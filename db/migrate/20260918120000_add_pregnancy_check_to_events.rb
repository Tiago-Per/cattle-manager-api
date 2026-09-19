class AddPregnancyCheckToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :pregnancy_check_result, :string
    add_column :events, :pregnancy_checked_on, :date
  end
end
