class CreateEntities < ActiveRecord::Migration[8.0]
  def change
    create_table :entities do |t|
      t.string :registration_number, null: false
      t.string :registration_type, null: false
      t.timestamps
    end

    add_index :entities, [ :registration_number, :registration_type ], unique: true
  end
end
