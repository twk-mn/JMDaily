class AddSocialLinksToAuthors < ActiveRecord::Migration[8.1]
  def change
    add_column :authors, :instagram_url, :string
    add_column :authors, :bluesky_url,   :string
    add_column :authors, :facebook_url,  :string
    add_column :authors, :mastodon_url,  :string
    add_column :authors, :linkedin_url,  :string
    add_column :authors, :youtube_url,   :string
  end
end
