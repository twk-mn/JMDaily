class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.integer :position

      t.timestamps
    end
    add_index :categories, :slug, unique: true
  end
end
