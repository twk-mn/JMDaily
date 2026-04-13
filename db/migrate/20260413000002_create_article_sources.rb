class CreateArticleSources < ActiveRecord::Migration[8.1]
  def change
    create_table :article_sources do |t|
      t.references :article, null: false, foreign_key: true
      t.string :name, null: false
      t.string :url
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :article_sources, [ :article_id, :position ]
  end
end
