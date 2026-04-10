class CreateTipSubmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :tip_submissions do |t|
      t.string  :name
      t.string  :email
      t.text    :tip_body, null: false
      t.boolean :read, null: false, default: false
      t.timestamps
    end

    add_index :tip_submissions, :read
  end
end
