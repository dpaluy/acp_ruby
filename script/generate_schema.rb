#!/usr/bin/env ruby
# frozen_string_literal: true

# Generates Ruby schema classes from schema.json
# Usage: ruby script/generate_schema.rb [--check]

require "json"
require "set"
require "fileutils"

SCHEMA_PATH = File.expand_path("../schema/schema.json", __dir__)
META_PATH = File.expand_path("../schema/meta.json", __dir__)
OUTPUT_DIR = File.expand_path("../lib/agent_client_protocol/schema", __dir__)
META_OUTPUT = File.expand_path("../lib/agent_client_protocol/meta.rb", __dir__)

# Types that are JSON-RPC framing — we skip these (not user-facing)
SKIP_TYPES = Set.new(%w[
  AgentNotification AgentRequest AgentResponse
  ClientNotification ClientRequest ClientResponse
])

# Simple type aliases — just strings or integers, no class needed
ALIAS_TYPES = Set.new(%w[
  SessionId ToolCallId ProtocolVersion SessionModeId SessionConfigId
  SessionConfigGroupId SessionConfigValueId PermissionOptionId RequestId ErrorCode
])

class SchemaGenerator
  def initialize(schema, meta)
    @defs = schema["$defs"]
    @meta = meta
    @generated_classes = {}
    @enum_modules = {}
    @union_modules = {}
  end

  def generate_all
    classify_types
    generate_types_file
    generate_schema_file
    generate_meta_file
  end

  def check
    classify_types
    expected_types = generate_types_file
    expected_schema = generate_schema_file
    expected_meta = generate_meta_file

    ok = true
    [[File.join(OUTPUT_DIR, "types.rb"), expected_types],
     [File.join(OUTPUT_DIR, "generated.rb"), expected_schema],
     [META_OUTPUT, expected_meta]].each do |path, expected|
      if File.exist?(path)
        actual = File.read(path)
        if actual != expected
          warn "MISMATCH: #{path}"
          ok = false
        end
      else
        warn "MISSING: #{path}"
        ok = false
      end
    end
    ok
  end

  private

  def classify_types
    @enums = {}       # name -> [values]
    @objects = {}     # name -> definition
    @unions = {}      # name -> {discriminator:, variants:}
    @simple_unions = {} # name -> definition (anyOf without discriminator)
    # Maps ref_type -> [{field:, value:}] for unique discriminator assignment
    @discriminators = Hash.new { |h, k| h[k] = [] }

    @defs.each do |name, defn|
      next if SKIP_TYPES.include?(name) || ALIAS_TYPES.include?(name)

      if defn["oneOf"] && defn["discriminator"]
        parse_discriminated_union(name, defn)
      elsif defn["oneOf"] && all_const_strings?(defn["oneOf"])
        parse_enum(name, defn)
      elsif defn["oneOf"]
        # Enum-like with const values
        parse_enum(name, defn)
      elsif defn["properties"] || defn["type"] == "object"
        @objects[name] = defn
      elsif defn["anyOf"]
        @simple_unions[name] = defn
      elsif defn["description"] && defn.keys == ["description"]
        # Empty marker types (ExtRequest, etc.) — skip
      end
    end

    # Build discriminator map: for each union variant with a unique ref,
    # record the discriminator field + value
    @unions.each do |_union_name, info|
      info[:variants].each do |v|
        next unless v[:ref] && v[:discriminator_value]
        @discriminators[v[:ref]] << {field: info[:discriminator], value: v[:discriminator_value]}
      end
    end
  end

  def all_const_strings?(variants)
    variants.all? { |v| v["const"].is_a?(String) }
  end

  def parse_enum(name, defn)
    values = defn["oneOf"].map { |v| v["const"] }.compact
    @enums[name] = values if values.any?
  end

  def parse_discriminated_union(name, defn)
    disc_prop = defn["discriminator"]["propertyName"]
    variants = defn["oneOf"].map do |variant|
      disc_val = variant.dig("properties", disc_prop, "const")
      ref = variant.dig("allOf", 0, "$ref")&.then { |r| r.split("/").last }
      {discriminator_value: disc_val, ref: ref, inline: ref.nil?, definition: variant}
    end
    @unions[name] = {discriminator: disc_prop, variants: variants}
  end

  def generate_types_file
    lines = [
      "# frozen_string_literal: true",
      "",
      "# AUTO-GENERATED from schema.json — DO NOT EDIT",
      "",
      "module AgentClientProtocol",
      "  module Schema"
    ]

    # Enums as modules with constants
    @enums.sort_by(&:first).each do |name, values|
      lines << ""
      lines << "    module #{name}"
      values.each do |val|
        const_name = val.upcase.gsub(/[^A-Z0-9]/, "_")
        lines << "      #{const_name} = #{val.inspect}.freeze"
      end
      lines << "      ALL = [#{values.map { |v| v.upcase.gsub(/[^A-Z0-9]/, "_") }.join(", ")}].freeze"
      lines << "    end"
    end

    # Discriminated unions as modules with .parse
    @unions.sort_by(&:first).each do |name, info|
      disc = info[:discriminator]
      lines << ""
      lines << "    module #{name}"

      # Constants for discriminator values
      info[:variants].each do |v|
        next unless v[:discriminator_value]

        const = v[:discriminator_value].upcase.gsub(/[^A-Z0-9]/, "_")
        lines << "      #{const} = #{v[:discriminator_value].inspect}.freeze"
      end

      lines << ""
      lines << "      def self.parse(hash)"
      lines << "        return nil if hash.nil?"
      lines << "        disc = hash[#{disc.inspect}]"
      lines << "        case disc"

      info[:variants].each do |v|
        next unless v[:discriminator_value]

        if v[:ref]
          lines << "        when #{v[:discriminator_value].inspect}"
          # For session updates, the discriminator is added to the base type
          lines << "          obj = #{v[:ref]}.from_hash(hash)"
          lines << "          obj"
        else
          # Inline type — just return the hash
          lines << "        when #{v[:discriminator_value].inspect}"
          lines << "          hash"
        end
      end

      lines << "        else"
      lines << "          hash"
      lines << "        end"
      lines << "      end"
      lines << "    end"
    end

    lines << "  end"
    lines << "end"
    lines << ""

    content = lines.join("\n")
    write_file(File.join(OUTPUT_DIR, "types.rb"), content)
    content
  end

  def generate_schema_file
    lines = [
      "# frozen_string_literal: true",
      "",
      "# AUTO-GENERATED from schema.json — DO NOT EDIT",
      "",
      "require_relative \"base_model\"",
      "require_relative \"types\"",
      "",
      "module AgentClientProtocol",
      "  module Schema"
    ]

    # Sort objects to handle dependencies (simpler types first)
    sorted = topological_sort(@objects)

    sorted.each do |name|
      defn = @objects[name]
      lines.concat(generate_class(name, defn))
    end

    lines << "  end"
    lines << "end"
    lines << ""

    content = lines.join("\n")
    write_file(File.join(OUTPUT_DIR, "generated.rb"), content)
    content
  end

  def generate_class(name, defn)
    lines = []
    props = defn["properties"] || {}
    required = Set.new(defn["required"] || [])

    lines << ""
    lines << "    class #{name} < BaseModel"

    # Add discriminator if this type has exactly one unique discriminator mapping
    disc_entries = @discriminators[name]
    if disc_entries.size == 1
      d = disc_entries.first
      lines << "      discriminator #{d[:field].inspect}, #{d[:value].inspect}"
    end

    props.each do |json_name, prop_defn|
      ruby_name = to_snake_case(json_name)
      type_info = resolve_type(prop_defn)
      is_required = required.include?(json_name)

      default = resolve_default(prop_defn, type_info, is_required)

      parts = ["      property :#{ruby_name}"]
      parts << "json_name: #{json_name.inspect}" if json_name != to_camel_case(ruby_name)
      parts << "type: #{type_info[:ruby_type]}" if type_info[:ruby_type]
      parts << "default: #{default}" unless default == :_no_default
      parts << "required: true" if is_required

      lines << parts.join(", ")
    end

    lines << "    end"
    lines
  end

  def resolve_type(prop)
    if prop["$ref"]
      ref_name = prop["$ref"].split("/").last
      return resolve_ref_type(ref_name)
    end

    if prop["allOf"]
      ref = prop["allOf"].find { |a| a["$ref"] }
      if ref
        ref_name = ref["$ref"].split("/").last
        return resolve_ref_type(ref_name)
      end
    end

    if prop["anyOf"]
      # Check if it's a nullable ref
      refs = prop["anyOf"].select { |a| a["$ref"] }
      nulls = prop["anyOf"].select { |a| a["type"] == "null" }
      if refs.size == 1 && nulls.size >= 0
        ref_name = refs[0]["$ref"].split("/").last
        return resolve_ref_type(ref_name)
      end
      # Multiple refs — just use hash
      return {ruby_type: nil}
    end

    if prop["items"]
      elem_type = resolve_type(prop["items"])
      if elem_type[:ruby_type]
        return {ruby_type: "[:array, #{elem_type[:ruby_type]}]"}
      end
      return {ruby_type: nil}
    end

    case prop["type"]
    when "string" then {ruby_type: nil}
    when "integer" then {ruby_type: nil}
    when "number" then {ruby_type: nil}
    when "boolean" then {ruby_type: nil}
    when "array"
      if prop["items"]
        resolve_type(prop.merge("items" => prop["items"]))
      else
        {ruby_type: nil}
      end
    when "object", ["object", "null"]
      {ruby_type: ":hash"}
    else
      {ruby_type: nil}
    end
  end

  def resolve_ref_type(ref_name)
    if @unions.key?(ref_name)
      disc = @unions[ref_name][:discriminator]
      case disc
      when "sessionUpdate" then {ruby_type: ":session_update"}
      when "type"
        if ref_name == "ContentBlock"
          {ruby_type: ":content_block"}
        elsif ref_name == "ToolCallContent"
          {ruby_type: ":tool_call_content"}
        else
          {ruby_type: ref_name}
        end
      when "outcome"
        {ruby_type: ":permission_outcome"}
      else
        {ruby_type: nil}
      end
    elsif @objects.key?(ref_name)
      {ruby_type: ref_name}
    elsif @enums.key?(ref_name)
      {ruby_type: nil} # Enums are just string constants
    elsif ALIAS_TYPES.include?(ref_name)
      {ruby_type: nil} # Simple type aliases
    elsif @simple_unions.key?(ref_name)
      {ruby_type: nil}
    else
      {ruby_type: nil}
    end
  end

  def resolve_default(prop, type_info, is_required)
    return :_no_default if is_required

    if prop.key?("default")
      val = prop["default"]
      return val.inspect if val.is_a?(String) || val == true || val == false
      return val.to_s if val.is_a?(Integer) || val.is_a?(Float)
      return "nil" if val.nil?
      return "{}" if val.is_a?(Hash) && val.empty?
      return "[]" if val.is_a?(Array) && val.empty?
      return val.inspect if val.is_a?(Hash) || val.is_a?(Array)
    end

    if prop["anyOf"]&.any? { |a| a["type"] == "null" }
      return "nil"
    end

    if prop.dig("type") == ["object", "null"]
      return "nil"
    end

    :_no_default
  end

  def generate_meta_file
    lines = [
      "# frozen_string_literal: true",
      "",
      "# AUTO-GENERATED from meta.json — DO NOT EDIT",
      "",
      "module AgentClientProtocol",
      "  PROTOCOL_VERSION = #{@meta["version"]}",
      "",
      "  AGENT_METHODS = {"
    ]

    @meta["agentMethods"].sort.each do |key, value|
      lines << "    #{key}: #{value.inspect},"
    end
    lines << "  }.freeze"

    lines << ""
    lines << "  CLIENT_METHODS = {"
    @meta["clientMethods"].sort.each do |key, value|
      lines << "    #{key}: #{value.inspect},"
    end
    lines << "  }.freeze"
    lines << "end"
    lines << ""

    content = lines.join("\n")
    write_file(META_OUTPUT, content)
    content
  end

  def topological_sort(objects)
    # Simple: sort by dependency depth, then alphabetically
    deps = {}
    objects.each do |name, defn|
      deps[name] = find_object_deps(defn) & objects.keys.to_set
    end

    sorted = []
    visited = Set.new
    temp = Set.new

    visit = lambda do |name|
      return if visited.include?(name)

      if temp.include?(name)
        # Circular dependency — just add it
        sorted << name unless sorted.include?(name)
        return
      end

      temp.add(name)
      (deps[name] || []).each { |dep| visit.call(dep) }
      temp.delete(name)
      visited.add(name)
      sorted << name
    end

    objects.keys.sort.each { |name| visit.call(name) }
    sorted
  end

  def find_object_deps(defn)
    deps = Set.new
    extract_refs(defn, deps)
    deps
  end

  def extract_refs(node, deps)
    case node
    when Hash
      if node["$ref"]
        ref_name = node["$ref"].split("/").last
        deps << ref_name if @objects.key?(ref_name)
      end
      node.each_value { |v| extract_refs(v, deps) }
    when Array
      node.each { |v| extract_refs(v, deps) }
    end
  end

  def to_snake_case(str)
    return str if str == "_meta"

    str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
       .gsub(/([a-z\d])([A-Z])/, '\1_\2')
       .downcase
  end

  def to_camel_case(str)
    return str if str == "_meta"

    parts = str.split("_")
    parts[0] + parts[1..].map(&:capitalize).join
  end

  def write_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    puts "Generated: #{path}"
  end
end

schema = JSON.parse(File.read(SCHEMA_PATH))
meta = JSON.parse(File.read(META_PATH))

generator = SchemaGenerator.new(schema, meta)

if ARGV.include?("--check")
  if generator.check
    puts "All generated files are up to date."
    exit 0
  else
    puts "Generated files are out of date. Run: ruby script/generate_schema.rb"
    exit 1
  end
else
  generator.generate_all
  puts "Done."
end
