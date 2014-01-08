module Appsignal
  module Moped
    module Instrumentation
      EVENT_NAME = 'query.moped'

      private

      def logging_with_appsignal_instrumentation(operations, &block)
        ActiveSupport::Notifications.instrument(
          EVENT_NAME, :ops => operations
        ) do
          logging_without_appsignal_instrumentation(operations, &block)
        end
      end

    end
  end
end
