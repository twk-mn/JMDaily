class CreateArticleLocations < ActiveRecord::Migration[7.1]
  def change
    create_table :article_locations do |t|
      t.references :article, null: false, foreign_key: true
      t.references :location, null: false, foreign_key: true

      t.timestamps
    end
    add_index :article_locations, [:article_id, :location_id], unique: true
  end
end
