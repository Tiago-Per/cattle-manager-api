class CreateAnimals < ActiveRecord::Migration[8.0]
  def change
    create_table :animals do |t|
      t.string :identification, null: false
      t.string :category, null: false
      t.date :birth_date
      t.string :sex, null: false
      t.string :status, null: false, default: "active"

      t.timestamps
    end
    add_index :animals, :identification, unique: true
  end
end
