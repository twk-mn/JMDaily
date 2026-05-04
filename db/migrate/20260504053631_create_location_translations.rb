class CreateLocationTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :location_translations do |t|
      t.references :location, null: false, foreign_key: true
      t.string :locale, null: false
      t.string :name
      t.text   :description
      t.timestamps

      t.index [ :location_id, :locale ], unique: true
    end
  end
end
