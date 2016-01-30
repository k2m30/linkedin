class CreateKeywords < ActiveRecord::Migration
  def change
    create_table :keywords do |t|
      t.string :owner
      t.string :position
      t.string :keyword
      t.integer :industry
      t.boolean :passed, default: false
    end
  end
end
