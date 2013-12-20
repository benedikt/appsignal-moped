module Appsignal
  module Middleware
    class MopedEventSanitizer
      WHITELISTED_KEYS = %w{fields flags}

      def call(event)
        if target?(event)
          event.payload[:ops].each do |operation|
            operation.each_value do |parameters|
              selected(parameters).each_value do |value|
                scrub!(value)
              end
            end
          end
        end
        yield
      end

      protected

      def target?(event)
        event.name == Appsignal::Moped::Instrumentation::EVENT_NAME
      end

      def selected(parameters)
        parameters.reject { |key, value| WHITELISTED_KEYS.include?(key) }
      end

      def scrub!(value)
        if value.is_a?(Hash) || value.is_a?(Array)
          Appsignal::Transaction::ParamsSanitizer.scrub!(value)
        end
      end
    end
  end
end
