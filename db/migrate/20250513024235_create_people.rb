class CreatePeople < ActiveRecord::Migration[8.0]
  def change
    create_table :people do |t|
      t.string :name, null: false
      t.string :family_name, null: false
      t.string :email, null: false
      t.string :phone, null: true
      t.references :entity, null: false, foreign_key: true
      t.timestamps
    end

    add_index :people, [ :name, :family_name, :email ], unique: true
  end
end
