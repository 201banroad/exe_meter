class Session < ApplicationRecord

    def running?   #セッションが進行中かどうか
        started_at.present? && ended_at.nil?
    end

    def persisted_seconds #すでにDBに保存されている合計秒数。total_seconds がnilのときは 0 を返す（エラー防止）
        total_seconds || 0
    end

    def live_seconds #経過秒数。タイマー走っている場合と止まってる場合
        if running?
            persisted_seconds + ( Time.current - started_at ).to_i
        else
            persisted_seconds
        end
    end

    def live_hours #秒数を時間に変換 経過”時間”
        live_seconds / 3600.0
    end


        # １時間で稼げる金額 = 目標金額 ÷ 目標時間
    def hour_price
        return 0 if target_hours.to_f <= 0
        target_price.to_f / target_hours.to_f
    end

    # いままでの取り組みで“稼いだ価値”
    # = １時給 × これまでの実働時間
    def now_price
        hour_price * live_hours
    end

    # 達成度を0.0〜1.0で表示
    def progress_ratio
        return 0.0 if target_price.to_f <= 0
        [(now_price / target_price.to_f), 1.0].min  #1 10 0.1
    end

end
