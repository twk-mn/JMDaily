class AddTwoFactorToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :totp_secret,     :string
    add_column :users, :totp_enabled_at, :datetime
  end
end
