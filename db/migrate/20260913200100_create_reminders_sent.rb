class CreateRemindersSent < ActiveRecord::Migration[8.1]
  def change
    # Idempotency guard for SendRemindersJob: a DB-level unique index (rather
    # than a check-then-insert in Ruby) so two overlapping runs for the same
    # user/window can't both pass the check and both send — the second insert
    # simply fails the constraint and the job treats that as "already sent".
    create_table :reminders_sent do |t|
      t.references :user, null: false, foreign_key: true
      t.date :window_start, null: false
      t.date :window_end, null: false

      t.timestamps
    end

    add_index :reminders_sent, %i[user_id window_start window_end], unique: true,
      name: "index_reminders_sent_on_user_and_window"
  end
end
