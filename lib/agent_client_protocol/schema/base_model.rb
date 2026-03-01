# frozen_string_literal: true

module AgentClientProtocol
  module Schema
    class BaseModel
      class << self
        def properties
          @properties ||= {}
        end

        def required_properties
          @required_properties ||= Set.new
        end

        # Register a discriminator field + value for this class.
        # E.g., `discriminator "type", "text"` means to_h includes {"type" => "text"}
        def discriminator(field = nil, value = nil)
          if field
            @discriminator_field = field
            @discriminator_value = value
          end
          @discriminator_field ? [@discriminator_field, @discriminator_value] : nil
        end

        def property(ruby_name, json_name: nil, type: nil, default: :_no_default, required: false)
          json_name ||= to_camel_case(ruby_name.to_s)
          properties[ruby_name] = {json_name: json_name, type: type, default: default}
          required_properties << ruby_name if required
          attr_reader ruby_name
        end

        def from_hash(hash)
          return nil if hash.nil?

          kwargs = {}
          properties.each do |ruby_name, meta|
            json_name = meta[:json_name]
            if hash.key?(json_name)
              kwargs[ruby_name] = deserialize_value(hash[json_name], meta[:type])
            elsif hash.key?(ruby_name.to_s)
              kwargs[ruby_name] = deserialize_value(hash[ruby_name.to_s], meta[:type])
            end
          end
          new(**kwargs)
        end

        def inherited(subclass)
          super
          subclass.instance_variable_set(:@properties, properties.dup)
          subclass.instance_variable_set(:@required_properties, required_properties.dup)
        end

        private

        def to_camel_case(str)
          return str if str == "_meta"

          parts = str.split("_")
          parts[0] + parts[1..].map(&:capitalize).join
        end

        def deserialize_value(value, type)
          return nil if value.nil?

          case type
          when Class
            if type < BaseModel
              type.from_hash(value)
            else
              value
            end
          when :content_block
            ContentBlock.parse(value)
          when :session_update
            SessionUpdate.parse(value)
          when :tool_call_content
            ToolCallContent.parse(value)
          when :permission_outcome
            RequestPermissionOutcome.parse(value)
          when Array
            if type[0] == :array && value.is_a?(::Array)
              value.map { |v| deserialize_value(v, type[1]) }
            else
              value
            end
          when :hash
            value
          else
            value
          end
        end
      end

      def initialize(**kwargs)
        self.class.properties.each do |ruby_name, meta|
          if kwargs.key?(ruby_name)
            instance_variable_set(:"@#{ruby_name}", kwargs[ruby_name])
          elsif meta[:default] != :_no_default
            default = meta[:default]
            default = default.dup if default.is_a?(::Hash) || default.is_a?(::Array)
            instance_variable_set(:"@#{ruby_name}", default)
          end
        end
      end

      def to_h
        result = {}

        # Include discriminator if set on this class
        disc = self.class.discriminator
        if disc
          result[disc[0]] = disc[1]
        end

        self.class.properties.each do |ruby_name, meta|
          value = instance_variable_get(:"@#{ruby_name}")
          next if value.nil? && !self.class.required_properties.include?(ruby_name)

          result[meta[:json_name]] = serialize_value(value)
        end
        result
      end

      def to_json(*)
        JSON.generate(to_h, *)
      end

      def ==(other)
        other.is_a?(self.class) && to_h == other.to_h
      end

      def hash
        [self.class, to_h].hash
      end

      def eql?(other)
        self == other
      end

      def inspect
        pairs = self.class.properties.keys.map { |k| "#{k}: #{instance_variable_get(:"@#{k}").inspect}" }
        "#<#{self.class.name} #{pairs.join(", ")}>"
      end

      private

      def serialize_value(value)
        case value
        when BaseModel then value.to_h
        when ::Array then value.map { |v| serialize_value(v) }
        when ::Hash then value.transform_values { |v| serialize_value(v) }
        else
          value.respond_to?(:to_h) && !value.is_a?(Numeric) ? value.to_h : value
        end
      end
    end
  end
end
