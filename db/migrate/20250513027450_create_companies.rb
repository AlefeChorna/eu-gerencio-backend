class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :trader_name, null: false
      t.references :entity, null: false, foreign_key: true
      t.references :parent, null: true, foreign_key: { to_table: :companies }
      t.references :admin, null: true, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
