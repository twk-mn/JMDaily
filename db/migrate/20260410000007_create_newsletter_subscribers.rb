class CreateNewsletterSubscribers < ActiveRecord::Migration[8.0]
  def change
    create_table :newsletter_subscribers do |t|
      t.string  :email,           null: false
      t.string  :confirmation_token
      t.datetime :confirmed_at
      t.datetime :unsubscribed_at
      t.timestamps
    end

    add_index :newsletter_subscribers, :email, unique: true
    add_index :newsletter_subscribers, :confirmation_token, unique: true
  end
end
