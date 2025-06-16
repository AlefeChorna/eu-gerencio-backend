class RemoveCompanyIdFromUsers < ActiveRecord::Migration[8.0]
  def up
    # Check if the column exists before trying to remove it
    if column_exists?(:users, :company_id)
      # Only try to remove the foreign key if it exists
      remove_foreign_key :users, :companies if foreign_key_exists?(:users, :companies)
      remove_column :users, :company_id
    end
  end

  def down
    # Only add the column back if it doesn't exist
    unless column_exists?(:users, :company_id)
      add_reference :users, :company, foreign_key: true
    end
  end
end
