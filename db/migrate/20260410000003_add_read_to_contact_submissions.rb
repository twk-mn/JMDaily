class AddReadToContactSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :contact_submissions, :read, :boolean, null: false, default: false
    add_index  :contact_submissions, :read
  end
end
