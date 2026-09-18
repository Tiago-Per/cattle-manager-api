class AddWhatsappFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :phone_number, :string
    add_column :users, :whatsapp_opt_in, :boolean, default: false, null: false
  end
end
