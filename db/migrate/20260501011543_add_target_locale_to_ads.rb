class AddTargetLocaleToAds < ActiveRecord::Migration[8.1]
  def change
    add_column :ads, :target_locale, :string
    add_index  :ads, :target_locale
  end
end
