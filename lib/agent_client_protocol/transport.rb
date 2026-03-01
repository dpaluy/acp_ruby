# frozen_string_literal: true

require "json"

module AgentClientProtocol
  module Transport
    MAX_LINE_BYTES = 50 * 1024 * 1024 # 50MB

    class NdjsonWriter
      def initialize(io)
        @io = io
        @io.sync = true
        @mutex = Mutex.new
      end

      def write(message)
        line = JSON.generate(message) + "\n"
        @mutex.synchronize do
          @io.write(line)
          @io.flush
        end
      end

      def close
        @io.close unless @io.closed?
      rescue IOError
        # already closed
      end
    end

    class NdjsonReader
      def initialize(io, max_line_bytes: MAX_LINE_BYTES)
        @io = io
        @max_line_bytes = max_line_bytes
      end

      def each
        return enum_for(:each) unless block_given?

        loop do
          line = read_line
          break if line.nil?

          line = line.strip
          next if line.empty?

          begin
            yield JSON.parse(line)
          rescue JSON::ParserError => e
            raise AgentClientProtocol::RequestError.parse_error(e.message)
          end
        end
      end

      def close
        @io.close unless @io.closed?
      rescue IOError
        # already closed
      end

      private

      def read_line
        @io.gets
      rescue IOError, Errno::EBADF
        nil
      end
    end
  end
end
