class CreateCategoryTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :category_translations do |t|
      t.references :category, null: false, foreign_key: true
      t.string :locale, null: false
      t.string :name
      t.text   :description
      t.timestamps

      t.index [ :category_id, :locale ], unique: true
    end
  end
end
