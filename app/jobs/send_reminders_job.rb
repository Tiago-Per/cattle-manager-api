class SendRemindersJob < ApplicationJob
  queue_as :default

  def perform(window_start, window_end)
    User.where(whatsapp_opt_in: true).where.not(phone_number: [ nil, "" ]).find_each do |user|
      send_reminder(user, window_start, window_end)
    end
  end

  private

  def send_reminder(user, window_start, window_end)
    vaccinations = user.events.vaccination.where(due_on: window_start..window_end).includes(:animal)
    calvings = user.events.calving_due_between(window_start, window_end).includes(:animal)
    estrus = user.events.estrus_due_between(window_start, window_end).includes(:animal)

    return if vaccinations.none? && calvings.none? && estrus.none?

    begin
      ReminderSent.create!(user: user, window_start: window_start, window_end: window_end)
    rescue ActiveRecord::RecordNotUnique
      return
    end

    Notifications::Dispatcher.deliver(to: user.phone_number, body: message_for(vaccinations, calvings, estrus))
  end

  def message_for(vaccinations, calvings, estrus)
    lines = []

    vaccinations.each do |event|
      lines << "Vaccination due #{event.due_on} for #{event.animal.identification} (#{event.product_name})"
    end

    calvings.each do |event|
      lines << "Estimated calving date #{event.expected_calving_date} for #{event.animal.identification} (estimate)"
    end

    estrus.each do |event|
      lines << "Estimated estrus date #{event.expected_estrus_date} for #{event.animal.identification} (estimate)"
    end

    "You have #{lines.size} upcoming item(s):\n#{lines.join("\n")}"
  end
end
