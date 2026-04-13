class AddLocaleToNewsletterIssues < ActiveRecord::Migration[8.1]
  def change
    add_column :newsletter_issues, :locale, :string, null: false, default: "en"
    add_index  :newsletter_issues, :locale
  end
end
