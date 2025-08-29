class Session < ApplicationRecord

    def running?   #セッションが進行中かどうか
        started_at.present? && ended_at.nil?
    end

    def persisted_seconds #すでにDBに保存されている合計秒数。total_seconds がnilのときは 0 を返す（エラー防止）
        total_seconds || 0
    end

    def live_seconds #タイマー走っている場合と止まってる場合での経過時間
        if running?
            persisted_seconds + ( Time.current - started_at ).to_i
        else
            persisted_seconds
        end
    end



end
