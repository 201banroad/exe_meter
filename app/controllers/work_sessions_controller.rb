class WorkSessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_session

  def show
  end

  def update_target
    if @work_session.update(params.require(:work_session).permit(:target_price, :target_hours))
      redirect_to root_path, notice: "目標を更新しました"
    else
      flash.now[:alert] = "目標の更新に失敗しました"
      render :show, status: :unprocessable_entity
    end
  end

  def update_time
    if @work_session.running?
      redirect_to root_path, alert: "タイマー進行中は更新できません" and return
    end

    @work_session.update_manual_time!(params.dig(:work_session, :manual_time))
    redirect_to root_path, notice: "手動で時間を更新しました"

    rescue ActiveRecord::RecordInvalid => e
      @work_session = e.record
      flash.discard(:notice) # 前に表示されてたリセットしました等を消す
      flash.now[:alert] = "時間更新に失敗しました"
      render :show, status: :unprocessable_entity
  end

  private

  def load_session
    @work_session = current_user.work_session || current_user.create_work_session!(total_seconds: 0, target_price: 0, target_hours: 0) # 初期値だとnilが入り。バリデーションや、ロジックの時に困るので明示的に０を渡す
  end
end
