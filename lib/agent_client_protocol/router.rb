# frozen_string_literal: true

module AgentClientProtocol
  class Router
    def initialize
      @request_handlers = {}
      @notification_handlers = {}
      @ext_method_handler = nil
      @ext_notification_handler = nil
    end

    def on_request(method, request_class: nil, response_class: nil, optional: false, &handler)
      @request_handlers[method] = {
        handler: handler,
        request_class: request_class,
        response_class: response_class,
        optional: optional
      }
    end

    def on_notification(method, request_class: nil, &handler)
      @notification_handlers[method] = {
        handler: handler,
        request_class: request_class
      }
    end

    def on_ext_method(&handler)
      @ext_method_handler = handler
    end

    def on_ext_notification(&handler)
      @ext_notification_handler = handler
    end

    def call(method, params, is_notification)
      if is_notification
        dispatch_notification(method, params)
      else
        dispatch_request(method, params)
      end
    end

    private

    def dispatch_request(method, params)
      # Extension methods start with _
      if method.start_with?("_")
        if @ext_method_handler
          return @ext_method_handler.call(method, params)
        else
          raise RequestError.method_not_found(method)
        end
      end

      entry = @request_handlers[method]
      unless entry
        raise RequestError.method_not_found(method)
      end

      begin
        deserialized = deserialize_params(params, entry[:request_class])
        result = entry[:handler].call(deserialized)

        if result.nil? && entry[:optional]
          return nil
        end

        serialize_result(result)
      rescue NotImplementedError
        if entry[:optional]
          nil
        else
          raise RequestError.method_not_found(method)
        end
      end
    end

    def dispatch_notification(method, params)
      if method.start_with?("_")
        @ext_notification_handler&.call(method, params)
        return nil
      end

      entry = @notification_handlers[method]
      return nil unless entry

      deserialized = deserialize_params(params, entry[:request_class])
      entry[:handler].call(deserialized)
      nil
    end

    def deserialize_params(params, klass)
      return params unless klass && params.is_a?(Hash)

      klass.from_hash(params)
    end

    def serialize_result(result)
      case result
      when Schema::BaseModel then result.to_h
      when Hash then result
      when nil then nil
      else result
      end
    end
  end
end
