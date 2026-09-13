class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.references :animal, null: false, foreign_key: true, index: false
      t.string :event_type, null: false
      t.date :occurred_on, null: false
      t.date :due_on
      t.text :notes
      t.decimal :weight_kg, precision: 6, scale: 2
      t.string :product_name
      t.string :sire_identification

      t.timestamps
    end

    add_index :events, %i[animal_id occurred_on]
    add_index :events, :due_on
  end
end
