class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :dir
      t.belongs_to :industry
      t.string :login
      t.string :password
      t.string :proxy
      t.string :comment
      t.string :linkedin_profile
      t.string :command_str
    end
  end
end
