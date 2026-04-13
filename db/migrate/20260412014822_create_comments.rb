class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.references :article, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email
      t.text :body, null: false
      t.string :status, null: false, default: "pending"
      t.string :ip_address

      t.timestamps
    end
  end
end
