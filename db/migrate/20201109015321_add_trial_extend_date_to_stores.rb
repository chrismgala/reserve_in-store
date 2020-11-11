class AddTrialExtendDateToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :trial_extend_date, :datetime
  end
end
