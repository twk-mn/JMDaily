class CreateCorrections < ActiveRecord::Migration[8.1]
  def change
    create_table :corrections do |t|
      t.references :article, null: false, foreign_key: true
      t.text     :body,      null: false
      t.datetime :posted_at, null: false

      t.timestamps
    end

    add_index :corrections, [ :article_id, :posted_at ]
  end
end
