class ChangeAuthorsUserIdNullable < ActiveRecord::Migration[7.1]
  def change
    change_column_null :authors, :user_id, true
  end
end
