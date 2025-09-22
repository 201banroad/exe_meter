class CreateWorkIntervals < ActiveRecord::Migration[8.0]
  def change
    create_table :work_intervals do |t|
      t.references :session, null: false, foreign_key: true
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :duration_sec

      t.timestamps
    end
  end
end
