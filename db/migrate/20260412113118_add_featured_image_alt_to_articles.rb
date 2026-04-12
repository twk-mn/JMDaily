class AddFeaturedImageAltToArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :featured_image_alt, :string
  end
end
