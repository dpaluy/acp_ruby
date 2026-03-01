# frozen_string_literal: true

module AgentClientProtocol
  class RequestError < StandardError
    attr_reader :code, :data

    PARSE_ERROR        = -32700
    INVALID_REQUEST    = -32600
    METHOD_NOT_FOUND   = -32601
    INVALID_PARAMS     = -32602
    INTERNAL_ERROR     = -32603
    AUTH_REQUIRED      = -32000
    RESOURCE_NOT_FOUND = -32002

    def initialize(code, message, data = nil)
      @code = code
      @data = data
      super(message)
    end

    def to_h
      h = {"code" => @code, "message" => message}
      h["data"] = @data if @data
      h
    end

    class << self
      def parse_error(data = nil)        = new(PARSE_ERROR, "Parse error", data)
      def invalid_request(data = nil)    = new(INVALID_REQUEST, "Invalid request", data)
      def method_not_found(method)       = new(METHOD_NOT_FOUND, "Method not found", {"method" => method})
      def invalid_params(data = nil)     = new(INVALID_PARAMS, "Invalid params", data)
      def internal_error(data = nil)     = new(INTERNAL_ERROR, "Internal error", data)
      def auth_required(data = nil)      = new(AUTH_REQUIRED, "Authentication required", data)
      def resource_not_found(uri = nil)  = new(RESOURCE_NOT_FOUND, "Resource not found", uri ? {"uri" => uri} : nil)

      def from_hash(hash)
        new(hash["code"], hash["message"], hash["data"])
      end
    end
  end
end
