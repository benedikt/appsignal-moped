module Appsignal
  module Middleware
    class MopedEventSanitizer
      WHITELISTED_KEYS = %w{fields flags}

      def call(event)
        if target?(event)
          event.payload[:ops] = appsignal_log_operations(event.payload[:ops])
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

      def appsignal_log_operations(ops)
        ops.map do |op|
          {
            operation_name(op) => {}.tap do |hash|
              op.instance_variables.reject do |o|
                o == :@full_collection_name
              end.each do |attr|
                value = op.instance_variable_get(attr)
                value = self.class.deep_clone(value)
                hash[attr.to_s.gsub('@', '')] = value unless value.nil?
              end
            end
          }
        end
      end

      def self.deep_clone(value)
        case value
        when Hash
          result = {}
          value.each { |k, v| result[k] = deep_clone(v) }
          result
        when Array
          value.map { |v| deep_clone(v) }
        when Symbol, Numeric, Regexp, true, false, nil
          value
        else
          value.clone
        end
      end

      def operation_name(operation)
        operation.class.name.split('::').last.tap do |class_name|
          class_name.gsub!(/([a-z])([A-Z])/,'\1_\2')
          class_name.downcase!
        end
      end

    end
  end
end
