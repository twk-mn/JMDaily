class CreateTagTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :tag_translations do |t|
      t.references :tag, null: false, foreign_key: true
      t.string :locale, null: false
      t.string :name
      t.timestamps

      t.index [ :tag_id, :locale ], unique: true
    end
  end
end
