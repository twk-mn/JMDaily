class AddIndexesToAdsTargetColumns < ActiveRecord::Migration[8.1]
  def change
    add_index :ads, :target_category_id
    add_index :ads, :target_location_id
  end
end
