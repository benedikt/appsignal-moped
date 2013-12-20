require 'moped'
require 'appsignal'
require 'appsignal/moped/instrumentation'
require 'appsignal/middleware/moped_event_sanitizer'

::Moped::Node.class_eval do
  include Appsignal::Moped::Instrumentation

  private

  alias_method :logging_without_appsignal_instrumentation, :logging
  alias_method :logging, :logging_with_appsignal_instrumentation
end

Appsignal.post_processing_middleware.add Appsignal::Middleware::MopedEventSanitizer
