class CreateNewsletterIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :newsletter_issues do |t|
      t.string :subject, null: false
      t.text :body, null: false
      t.string :status, null: false, default: "draft"
      t.datetime :sent_at
      t.integer :recipients_count, default: 0

      t.timestamps
    end
  end
end
