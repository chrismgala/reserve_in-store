class AddCustomHtmlToLocations < ActiveRecord::Migration[5.2]
  def change
    add_column :locations, :custom_html, :text, default: ''
  end
end
