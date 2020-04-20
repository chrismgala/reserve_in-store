class AddPlanOverridesToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :plan_overrides, :jsonb
  end
end
