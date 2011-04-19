class CreateBudgetInfusions < ActiveRecord::Migration
  def self.up
    create_table :budget_infusions do |t|
      t.references :channel, :null => false
      t.float :amount
      t.date :commitment_date
      t.timestamps
    end
  end

  def self.down
    drop_table :budget_infusions
  end
end
