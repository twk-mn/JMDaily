class CreateSiteLanguages < ActiveRecord::Migration[8.0]
  def change
    create_table :site_languages do |t|
      t.string  :code,        null: false
      t.string  :name,        null: false
      t.string  :native_name
      t.string  :flag_emoji
      t.integer :position,    null: false, default: 0
      t.boolean :active,      null: false, default: true
      t.boolean :deletable,   null: false, default: true

      t.timestamps
    end

    add_index :site_languages, :code, unique: true
    add_index :site_languages, [ :active, :position ]
  end
end
