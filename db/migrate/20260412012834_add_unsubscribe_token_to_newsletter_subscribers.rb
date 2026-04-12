class AddUnsubscribeTokenToNewsletterSubscribers < ActiveRecord::Migration[8.0]
  def change
    add_column :newsletter_subscribers, :unsubscribe_token, :string
    add_index :newsletter_subscribers, :unsubscribe_token, unique: true
  end
end
