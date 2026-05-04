class CreateAuthorTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :author_translations do |t|
      t.references :author, null: false, foreign_key: true
      t.string :locale, null: false
      t.string :role_title
      t.text   :bio
      t.timestamps

      t.index [ :author_id, :locale ], unique: true
    end
  end
end
