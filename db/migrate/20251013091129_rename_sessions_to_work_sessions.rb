class RenameSessionsToWorkSessions < ActiveRecord::Migration[8.0]
  def change
    rename_table :sessions, :work_sessions
  end
end
