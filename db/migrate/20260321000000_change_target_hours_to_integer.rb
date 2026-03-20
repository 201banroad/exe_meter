class ChangeTargetHoursToInteger < ActiveRecord::Migration[8.0]
  def up
    add_column :work_sessions, :target_hours_tmp, :integer

    execute <<~SQL
      UPDATE work_sessions
      SET target_hours_tmp = CAST(target_hours AS integer)
    SQL

    remove_column :work_sessions, :target_hours
    rename_column :work_sessions, :target_hours_tmp, :target_hours
  end

  def down
    add_column :work_sessions, :target_hours_tmp, :decimal, precision: 6, scale: 1

    execute <<~SQL
      UPDATE work_sessions
      SET target_hours_tmp = target_hours
    SQL

    remove_column :work_sessions, :target_hours
    rename_column :work_sessions, :target_hours_tmp, :target_hours
  end
end