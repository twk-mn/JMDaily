class CreateArticleTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :article_translations do |t|
      t.references :article, null: false, foreign_key: true
      t.string :locale, null: false
      t.string :title, null: false
      t.string :slug, null: false
      t.text :dek
      t.string :seo_title
      t.text :meta_description

      t.timestamps
    end

    add_index :article_translations, [ :article_id, :locale ], unique: true
    add_index :article_translations, [ :locale, :slug ], unique: true
  end
end
