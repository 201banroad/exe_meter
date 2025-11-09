class WorkSessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_session

  def show
  end

  def update_target
    if @work_session.update(params.require(:work_session).permit(:target_price, :target_hours))
      redirect_to root_path, notice: "目標を更新しました"
    else
      render :show, status: :unprocessable_entity
    end
  end


  def start
    unless @work_session.running?
      now = Time.current
      @work_session.update!(started_at: now, ended_at: nil)

      # 新しいWorkIntervalを作り、進行中のWorkIntervalがもしある場合はそれを使う（途中で中断された時などもしものため）
      @work_session.work_intervals.find_or_create_by!(ended_at: nil) do |wi|
        wi.started_at = now
      end
    end
    redirect_to root_path, notice: "計測を開始しました"
  end

  def stop
    if @work_session.running?
      now = Time.current
      wi = @work_session.work_intervals.find_by(ended_at: nil)

      if wi
        gain = (now - wi.started_at).to_i
        wi.update!(ended_at: now, duration_sec: gain)
      else
        # 念のため保険としてあまり起こらないけどWIが無いとき、なくてもここでは新しく作らない、あくまでStopの処理なので
        gain = (now - @work_session.started_at).to_i
      end

      # セッションの停止と累積秒の更新
      @work_session.update!(ended_at: now, total_seconds: @work_session.persisted_seconds + gain)
    end
    redirect_to root_path, notice: "計測を停止しました"
  end


  def reset
    # 未完了の WorkInterval は削除（履歴は残す方針なので完了済みは残す）
    @work_session.work_intervals.where(ended_at: nil).delete_all

    if @work_session.update(total_seconds: 0, started_at: nil, ended_at: nil)
      redirect_to root_path, notice: "リセットしました"
    else
      redirect_to root_path, alert: "リセットに失敗しました"
    end
  end

  def update_time
    if @work_session.running?
      redirect_to root_path, alert: "タイマー進行中は更新できません" and return
    end 

    @work_session.update_manual_time!(params.dig(:work_session, :manual_time))
    redirect_to root_path, notice: "手動時間を更新しました"

    rescue ActiveRecord::RecordInvalid => e
      # flash.now[:alert] = e.record.errors.full_messages.to_sentence
      @work_session = e.record
      flash.discard(:notice) # 前に表示されてたリセットしました等を消す
      render :show, status: :unprocessable_entity
  end

  private

  def load_session 
    @work_session = current_user.work_session || current_user.create_work_session!(total_seconds: 0, target_price: 0, target_hours: 0) #初期値だとnilが入り。バリデーションや、ロジックの時に困るので明示的に０を渡す
  end
end

