class AddTargetFieldsToSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions, :target_hours, :decimal, precision: 8, scale: 2
  end
end
