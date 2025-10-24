class AddUniqueIndexToSessionsUserId < ActiveRecord::Migration[7.1]
  def change
    # 既存の（非ユニークな）indexがあれば外す
    remove_index :sessions, :user_id if index_exists?(:sessions, :user_id)

    # ユニーク制約で付け直す
    add_index :sessions, :user_id, unique: true
  end
end
