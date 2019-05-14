class ChangeDefaultStockIndicatorBehavior < ActiveRecord::Migration[5.2]
  def change
    change_column_default :stores, :stock_status_behavior_when_stock_unknown, 'unknown_stock_hide_button'
  end
end
