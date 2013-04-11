module Appsignal
  module Moped
    module Instrumentation
      EVENT_NAME = 'query.moped'

      private

      def logging_with_appsignal_instrumentation(operations, &block)
        ActiveSupport::Notifications.instrument(
          EVENT_NAME, appsignal_log_operations(operations)
        ) do
          logging_without_appsignal_instrumentation(operations, &block)
        end
      end

      def appsignal_log_operations(operations)
        show_counter = operations.count > 1
        Hash[
          operations.each_with_index.map do |op, index|
            [
              appsignal_operation_name(op, show_counter ? index + 1 : nil),
              appsignal_operation_payload(op)
            ]
          end
        ]
      end

      def appsignal_operation_name(operation, counter)
        collection = operation.instance_variable_get(:@collection)
        description = "#{appsignal_class_name(operation)} in '#{collection}'"
        if counter
          "#{counter} - #{description}"
        else
          description
        end
      end

      def appsignal_class_name(operation)
        operation.class.name.split('::').last.tap do |class_name|
          class_name.gsub!(/([a-z])([A-Z])/,'\1_\2')
          class_name.downcase!
        end
      end

      def appsignal_operation_payload(operation)
        {}.tap do |hash|
          operation.instance_variables.reject do |o|
            o == :@full_collection_name
          end.each do |attr|
            value = operation.instance_variable_get(attr)
            hash[attr.to_s.gsub('@', '')] = value unless value.nil?
          end
        end
      end

    end
  end
end
