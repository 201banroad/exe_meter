class ChangeTargetHoursToDecimal < ActiveRecord::Migration[8.0]
  def change
    change_column :work_sessions, :target_hours, :decimal, precision: 6, scale: 1
  end
end
