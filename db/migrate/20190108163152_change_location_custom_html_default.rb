class ChangeLocationCustomHtmlDefault < ActiveRecord::Migration[5.2]
  def up
    Location.where(custom_html: nil).find_each do |loc|
      loc.update!(custom_html: "")
    end
    change_column :locations, :custom_html, :text, default: "", null: false
  end
  def down
    change_column :locations, :custom_html, :text
  end
end
