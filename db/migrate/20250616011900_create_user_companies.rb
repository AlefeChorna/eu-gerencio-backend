class CreateUserCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :user_companies do |t|
      t.references :company, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
      t.index [ :company_id, :user_id ], unique: true, name: 'index_user_companies_on_company_and_user'
    end
  end
end
