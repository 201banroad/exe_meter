class RemoveStartedAtAndEndedAtFromWorkSessions < ActiveRecord::Migration[8.0]
  def change
    remove_column :work_sessions, :started_at, :datetime
    remove_column :work_sessions, :ended_at, :datetime
  end
end
