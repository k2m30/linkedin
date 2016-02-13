class AddPassedToToPerson < ActiveRecord::Migration
  def change
    add_column :people, :passed_to, :string
  end
end
