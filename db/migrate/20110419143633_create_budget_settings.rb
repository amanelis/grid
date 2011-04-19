class CreateBudgetSettings < ActiveRecord::Migration
  def self.up
    create_table :budget_settings do |t|
      t.references :channel, :null => false
      t.float :amount
      t.date :start_date
      t.timestamps
    end
  end

  def self.down
    drop_table :budget_settings
  end
end
