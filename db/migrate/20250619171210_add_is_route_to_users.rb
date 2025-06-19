class AddIsRouteToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :is_root, :boolean, default: false, null: false
  end
end
