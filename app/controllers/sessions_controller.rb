class SessionsController < ApplicationController

  def show #セッションがあったらそれを使い、なかったら作る
    @session = Session.first_or_create!(total_seconds: 0, target_price: 0, target_hours: 0)
  end

  def update_target
    @session = Session.first_or_create!(total_seconds: 0, target_price: 0, target_hours: 0)
    if @session.update(params.require(:session).permit(:target_price, :target_hours))
      redirect_to root_path, notice: '目標を更新しました'
    else
      redirect_to root_path, alert: '更新に失敗しました'
    end

  end














end
