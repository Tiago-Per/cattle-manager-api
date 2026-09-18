module Notifications
  class Dispatcher
    def self.deliver(to:, body:)
      adapter.deliver(to: to, body: body)
    end

    def self.adapter
      Rails.application.config.x.notifications.adapter.constantize.new
    end
  end
end
