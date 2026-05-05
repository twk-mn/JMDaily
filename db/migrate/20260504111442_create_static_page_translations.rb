class CreateStaticPageTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :static_page_translations do |t|
      t.references :static_page, null: false, foreign_key: true
      t.string :locale, null: false
      t.string :title
      t.string :seo_title
      t.text   :meta_description
      # Note: `body` is stored as ActionText rich text (action_text_rich_texts
      # rows keyed on record_type/record_id/name), not a column on this table.
      t.timestamps

      t.index [ :static_page_id, :locale ], unique: true
    end
  end
end
