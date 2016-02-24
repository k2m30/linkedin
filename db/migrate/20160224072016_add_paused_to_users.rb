class AddPausedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :paused, :boolean, default: false
  end
end
