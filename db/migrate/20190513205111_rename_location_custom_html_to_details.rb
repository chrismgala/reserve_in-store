class RenameLocationCustomHtmlToDetails < ActiveRecord::Migration[5.2]
  def change
    rename_column :locations, :custom_html, :details
  end
end
