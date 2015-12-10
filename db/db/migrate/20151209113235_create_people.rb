class CreatePeople < ActiveRecord::Migration
  def change
    create_table :people do |t|
      t.string :name
      t.string :position
      t.string :industry
      t.string :location
      t.integer :linkedin_id
    end
    add_index :people, :name
    add_index :people, :position
    add_index :people, :location
    add_index :people, :industry
  end
end
