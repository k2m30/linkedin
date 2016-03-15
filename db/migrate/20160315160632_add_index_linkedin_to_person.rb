class AddIndexLinkedinToPerson < ActiveRecord::Migration
  def change
    add_index :people, :linkedin_id
  end
end
