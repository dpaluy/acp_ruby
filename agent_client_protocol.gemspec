# frozen_string_literal: true

require_relative "lib/agent_client_protocol/version"

Gem::Specification.new do |spec|
  spec.name = "agent_client_protocol"
  spec.version = AgentClientProtocol::VERSION
  spec.authors = ["David Paluy"]
  spec.email = ["david@dpaluy.com"]

  spec.summary = "Ruby SDK for the Agent Client Protocol (ACP)"
  spec.description = "Full-parity Ruby SDK implementing the Agent Client Protocol — " \
                     "a JSON-RPC 2.0 based open protocol for communication between " \
                     "code editors and AI coding agents over stdio."
  spec.homepage = "https://github.com/dpaluy/agent-client-protocol"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[
          test/ spec/ bin/ Gemfile .gitignore .github/ .rubocop
          docs/ .agents/ AGENTS.md CLAUDE.md Rakefile .yardopts
          script/ examples/
        ])
    end
  end

  spec.extra_rdoc_files = Dir["README.md", "CHANGELOG.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_dependency "async", "~> 2.0"
  spec.add_dependency "async-io", "~> 1.0"
end
