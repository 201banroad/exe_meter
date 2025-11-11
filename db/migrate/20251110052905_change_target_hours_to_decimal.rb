class ChangeTargetHoursToDecimal < ActiveRecord::Migration[8.0]
      change_column :work_sessions, :target_hours, :decimal, precision: 6, scale: 1

  def change

  end
end
