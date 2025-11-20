class WorkSession < ApplicationRecord
    # validates[:target_price >= 0,:target_hours >= 0, ]

    has_many :work_intervals, dependent: :destroy
    belongs_to :user

    validates :target_price, numericality: { greater_than_or_equal_to: 0 }, presence: true
    validates :target_hours, numericality: { greater_than_or_equal_to: 0, less_than: 100_000 }, presence: true

    def running?   # セッションが進行中かどうか
        started_at.present? && ended_at.nil?
    end

    def persisted_seconds # 合計秒数。total_seconds がnilのときは 0 を返す（計算時のエラー防止）
        total_seconds || 0
    end

    def live_seconds # 経過秒数。タイマー走っている場合と止まってる場合
        if running?
            persisted_seconds + (Time.current - started_at).to_i
        else
            persisted_seconds
        end
    end

    def live_hours # 秒数を時間に変換 経過”時間”
        live_seconds / 3600.0
    end


    # １時間で稼げる金額 = 目標金額 ÷ 目標時間　０除算ガードのために０以下だったら０を返す
    def hour_price
        return 0 if target_hours.to_f <= 0
        target_price.to_f / target_hours.to_f
    end

    # いままでの取り組みで“稼いだ価値”　１時給 × これまでの経過時間
    def now_price
        hour_price * live_hours
    end

    # 達成度を0.0〜1.0で表示これは不要かも
    def progress_ratio
        return 0.0 if target_price.to_f <= 0
        [ (now_price / target_price.to_f), 1.0 ].min  # 1 10 0.1
    end


    def today_total_seconds
        today_range = Time.zone.today.all_day

        if persisted? # 保存済み → DBにあるデータをSQLで集計する（速い・本番用）。
        work_intervals
            .where(ended_at: today_range)
            .where.not(duration_sec: nil)
            .sum(:duration_sec)
        else
        work_intervals # 未保存 → まだDBにない一時的な関連を、配列操作で集計する（テストや一時的な利用のため）
            .select { |wi| wi.ended_at.present? && today_range.cover?(wi.ended_at) }
            .sum { |wi| wi.duration_sec.to_i }
        end
    end


    # ここにコントローラにあったロジックやバリデーションを移行
    # 擬似的にバリデーションと更新をやってる（DBのカラムを作るんじゃなくて、一時的な入力値を弾きたいだけなのでバリデーションは使わず書いている）
    def update_manual_time!(manual_time_str)
        manual_time_str = manual_time_str.to_s.strip

        if manual_time_str.blank?
            errors.add(:manual_time, "を入力してください")
            raise ActiveRecord::RecordInvalid, self
        end

        unless /\A\d{1,}:\d{2}:\d{2}\z/.match?(manual_time_str)
            errors.add(:manual_time, "の形式が正しくありません（例: 01:30:00）")
            raise ActiveRecord::RecordInvalid, self
        end

        hh, mm, ss = manual_time_str.split(":").map(&:to_i)

        unless (0..59).cover?(mm) && (0..59).cover?(ss)
            errors.add(:manual_time,  "の分・秒は 00〜59 の範囲で入力してください")
            raise ActiveRecord::RecordInvalid, self
        end

        manual_seconds = hh * 3600 + mm * 60 + ss

        update!(total_seconds: manual_seconds, started_at: nil, ended_at: nil)
    end
end
