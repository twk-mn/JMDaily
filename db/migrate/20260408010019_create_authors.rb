class CreateAuthors < ActiveRecord::Migration[7.1]
  def change
    create_table :authors do |t|
      t.string :name
      t.string :slug
      t.text :bio
      t.string :role_title
      t.string :twitter_url
      t.string :website_url
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :authors, :slug, unique: true
  end
end
