class CreateUiStrings < ActiveRecord::Migration[8.1]
  def change
    create_table :ui_strings do |t|
      # Dot-separated chrome key, e.g. "footer.about_heading", "search.placeholder".
      # Mirrors the YAML i18n key namespacing so the t_ui fallback chain can
      # delegate to I18n.t with the same key when the row is missing.
      t.string :key, null: false
      t.string :locale, null: false
      t.text   :value
      t.timestamps

      t.index [ :key, :locale ], unique: true
      t.index :locale
    end
  end
end
