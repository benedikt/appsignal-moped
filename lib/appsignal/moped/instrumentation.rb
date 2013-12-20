module Appsignal
  module Moped
    module Instrumentation
      EVENT_NAME = 'query.moped'

      private

      def logging_with_appsignal_instrumentation(operations, &block)
        ActiveSupport::Notifications.instrument(
          EVENT_NAME, :ops => appsignal_log_operations(operations)
        ) do
          logging_without_appsignal_instrumentation(operations, &block)
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
                value = Appsignal::Moped::Instrumentation.deep_clone(value)
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
        when Symbol, Numeric, true, false, nil
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
