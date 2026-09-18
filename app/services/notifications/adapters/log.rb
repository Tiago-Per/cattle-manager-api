module Notifications
  module Adapters
    class Log
      def deliver(to:, body:)
        Rails.logger.info("[Notifications::Adapters::Log] to=#{to} body=#{body}")
      end
    end
  end
end
