class ReminderSent < ApplicationRecord
  self.table_name = "reminders_sent"

  belongs_to :user
end
