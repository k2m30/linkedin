class CreateIndustries < ActiveRecord::Migration
  def change
    create_table :industries do |t|
      t.integer :index
      t.string :keywords
      t.string :name

      t.timestamps null: false
    end
  end
end
