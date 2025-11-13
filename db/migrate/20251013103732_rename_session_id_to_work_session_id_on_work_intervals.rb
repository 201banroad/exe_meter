class RenameSessionIdToWorkSessionIdOnWorkIntervals < ActiveRecord::Migration[8.0]
  def change
    if column_exists?(:work_intervals, :session_id)
      rename_column :work_intervals, :session_id, :work_session_id
    end

    if foreign_key_exists?(:work_intervals, :sessions)
      remove_foreign_key :work_intervals, :sessions
    end

    unless foreign_key_exists?(:work_intervals, :work_sessions, column: :work_session_id)
      add_foreign_key :work_intervals, :work_sessions, column: :work_session_id
    end

    if index_name_exists?(:work_intervals, 'index_work_intervals_on_session_id')
      rename_index :work_intervals, 'index_work_intervals_on_session_id', 'index_work_intervals_on_work_session_id'
    end
  end
end
