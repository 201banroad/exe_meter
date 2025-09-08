class SessionsController < ApplicationController
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


    def start #この機能で何がしたいのか、スタートアクションをしたら現在時刻を記録したい。進行中でないならアップデートする
      unless @session.running?
        @session.update!(started_at: Time.current, ended_at: nil)
      end
      redirect_to root_path, notice: '計測を開始しました'
    end

    def stop #エンドアクションをしたら、エンド時刻を記録、ゲインに代入して、もともとのDBに保存する

      if @session.running? 
        gain = (Time.current - @session.started_at).to_i
        @session.update!(ended_at: Time.current, total_seconds: @session.persisted_seconds + gain )
      end
      redirect_to root_path, notice: '計測を停止しました' 
    end

    def reset
      # 進行中でも強制停止してゼロに戻す
      if @session.update(total_seconds: 0, started_at: nil, ended_at: nil)
        redirect_to root_path, notice: 'リセットしました'
      else
        redirect_to root_path, alert: 'リセットに失敗しました'
      end
    end


    private

    def load_session  #セッションがあったらそれを使い、なかったら作る
      @session = Session.first_or_create!(total_seconds: 0, target_price: 0, target_hours: 0)
    end


end
