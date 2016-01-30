class AddOwnerAndTimestampToPerson < ActiveRecord::Migration
  def change
    add_column :people, :owner, :string
    add_column :people, :created_at, :timestamp, default: Time.now
  end
end
