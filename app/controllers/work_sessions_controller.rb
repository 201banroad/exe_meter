class SessionsController < ApplicationController
  before_action :authenticate_user!

  before_action :load_session

  def show
  end

  def update_target
    if @session.update(params.require(:session).permit(:target_price, :target_hours))
      redirect_to root_path, notice: '目標を更新しました'
    else
      render :show, status: :unprocessable_entity
    end
  end


    def start
      unless @session.running?
        now = Time.current
        @session.update!(started_at: now, ended_at: nil)

        # 進行中の WorkIntervalがもしすでにある場合はそれを使う（基本的にはありえないがもしものため）
        @session.work_intervals.find_or_create_by!(ended_at: nil) do |wi|
          wi.started_at = now
        end
      end
      redirect_to root_path, notice: '計測を開始しました'
    end



  def stop
    if @session.running?
      now = Time.current

      wi = @session.work_intervals.find_by(ended_at: nil)

      if wi
        gain = (now - wi.started_at).to_i
        wi.update!(ended_at: now, duration_sec: gain)
      else
        # 念のため保険としてあまり起こらないけどWIが無いとき、なくてもここでは新しく作らない、あくまでStopの処理なので
        gain = (now - @session.started_at).to_i
      end

      # セッションの停止と累積秒の更新
      @session.update!(ended_at: now, total_seconds: @session.persisted_seconds + gain)
    end
    redirect_to root_path, notice: '計測を停止しました'
  end


  def reset
    # 未完了の WorkInterval は削除（履歴は残す方針なので完了済みは残す）
    @session.work_intervals.where(ended_at: nil).delete_all

    if @session.update(total_seconds: 0, started_at: nil, ended_at: nil)
      redirect_to root_path, notice: 'リセットしました'
    else
      redirect_to root_path, alert: 'リセットに失敗しました'
    end
  end

  def update_time
    if @session.running?
      redirect_to root_path, alert: 'タイマー進行中は更新できません' and return
    end

    str = params.dig(:session, :manual_time).to_s.strip

    if str.blank?
      redirect_to root_path, alert: '時間を入力してください（HH:MM:SS）' and return
    end

    unless /\A\d{1,2}:\d{2}:\d{2}\z/.match?(str)
      redirect_to root_path, alert: '時間の形式が正しくありません（例: 01:30:00）' and return
    end

    hh, mm, ss = str.split(":").map(&:to_i)
    unless (0 <= mm && mm < 60) && (0 <= ss && ss < 60)
      redirect_to root_path, alert: '時間の形式が正しくありません（例: 01:30:00）' and return
    end

    manual_seconds = hh * 3600 + mm * 60 + ss

    if @session.update(total_seconds: manual_seconds, started_at: nil, ended_at: nil)
      redirect_to root_path, notice: "更新に成功しました"
    else
      redirect_to root_path, alert: "更新に失敗しました"
    end


  end


    private

    def load_session 
      @session = current_user.session || current_user.create_session!(total_seconds: 0, target_price: 0, target_hours: 0)
    end


end
