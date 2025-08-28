class CreateSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :sessions do |t|
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :total_seconds
      t.integer :target_price

      t.timestamps
    end
  end
end
