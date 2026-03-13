class WorkIntervalsController < ApplicationController

  before_action :load_session


  def start
    unless @work_session.running?
      now = Time.current
      @work_session.update!(started_at: now, ended_at: nil)

      @work_session.work_intervals.create!(started_at: now, ended_at: nil)
    end
    redirect_to root_path, notice: "計測を開始しました"
  end


  private

  def load_session
    @work_session = current_user.work_session || current_user.create_work_session!(total_seconds: 0, target_price: 0, target_hours: 0) # 初期値だとnilが入り。バリデーションや、ロジックの時に困るので明示的に０を渡す
  end

end
