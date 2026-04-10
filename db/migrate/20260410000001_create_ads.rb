class CreateAds < ActiveRecord::Migration[8.0]
  def change
    create_table :ads do |t|
      t.string :name, null: false
      t.string :ad_type, null: false, default: "direct"
      t.string :placement_zone, null: false
      t.string :status, null: false, default: "active"

      # Direct ad fields
      t.string :link_url
      t.string :link_target, default: "_blank"
      t.string :sponsor_label

      # Programmatic / custom HTML
      t.text :script_code

      # Scheduling
      t.datetime :starts_at
      t.datetime :ends_at

      # Optional targeting
      t.bigint :target_category_id
      t.bigint :target_location_id

      # Tracking
      t.integer :impressions_count, null: false, default: 0
      t.integer :clicks_count, null: false, default: 0

      # Priority (higher = shown first if multiple match a zone)
      t.integer :priority, null: false, default: 0

      t.timestamps
    end

    add_index :ads, :placement_zone
    add_index :ads, :status
    add_foreign_key :ads, :categories, column: :target_category_id
    add_foreign_key :ads, :locations, column: :target_location_id
  end
end
