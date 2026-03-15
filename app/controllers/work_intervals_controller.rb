class WorkIntervalsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_session

  def start
    unless @work_session.running?
        now = Time.current
        @work_session.work_intervals.create!(started_at: now, ended_at: nil)
    end
    redirect_to root_path, notice: "計測を開始しました"
  end

  def stop
    if @work_session.running?
      now = Time.current
      wi = @work_session.work_intervals.find_by(ended_at: nil)

      if wi
        gain = (now - wi.started_at).to_i
        wi.update!(ended_at: now, duration_sec: gain)#durationは今日分のインターバル集計用
      end
      @work_session.update!(total_seconds: @work_session.persisted_seconds + gain)

    end
    redirect_to root_path, notice: "計測を停止しました"
  end

  def reset
    # 未完了の WorkInterval は削除（完了済みは今日のサマリーで使うので残す）
    @work_session.work_intervals.where(ended_at: nil).delete_all

    if @work_session.update(total_seconds: 0)
      redirect_to root_path, notice: "リセットしました"
    else
      redirect_to root_path, alert: "リセットに失敗しました"
    end
  end

  private

    def load_session #ユーザーの情報は、アソシエーションの関係で、WSから持ってくる
        @work_session = current_user.work_session || current_user.create_work_session!(total_seconds: 0, target_price: 0, target_hours: 0)
        @work_interval = @work_session.work_intervals.order(:created_at).last
    end

end
