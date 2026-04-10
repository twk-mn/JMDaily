class CreateArticles < ActiveRecord::Migration[7.1]
  def change
    create_table :articles do |t|
      t.string :title
      t.string :slug
      t.text :dek
      t.string :status, default: "draft", null: false
      t.datetime :published_at
      t.string :featured_image_caption
      t.string :seo_title
      t.text :meta_description
      t.string :canonical_url
      t.text :source_notes
      t.string :article_type, default: "news"
      t.boolean :featured, default: false, null: false
      t.boolean :breaking, default: false, null: false
      t.references :author, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end
    add_index :articles, :slug, unique: true
  end
end
