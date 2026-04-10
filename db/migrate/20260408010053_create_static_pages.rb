class CreateStaticPages < ActiveRecord::Migration[7.1]
  def change
    create_table :static_pages do |t|
      t.string :title
      t.string :slug
      t.string :seo_title
      t.text :meta_description

      t.timestamps
    end
    add_index :static_pages, :slug, unique: true
  end
end
