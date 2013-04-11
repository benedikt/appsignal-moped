module Appsignal
  module Middleware
    class MopedEventSanitizer
      WHITELISTED_KEYS = %w{fields flags}

      def call(event)
        if target?(event)
          event.payload.each_value do |operation|
            dirty_content(operation).each_value do |value|
              scrub!(value)
            end
          end
        end
        yield
      end

      protected

      def target?(event)
        event.name == Appsignal::Moped::Instrumentation::EVENT_NAME
      end

      def dirty_content(operation)
        operation.reject { |key, value| WHITELISTED_KEYS.include?(key) }
      end

      def scrub!(value)
        if value.is_a?(Hash) || value.is_a?(Array)
          Appsignal::ParamsSanitizer.scrub!(value)
        end
      end
    end
  end
end
