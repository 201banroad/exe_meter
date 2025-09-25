require "test_helper"

class WorkIntervalTest < ActiveSupport::TestCase

    test "duration_sec is calculated correctly when ended_at is present" do
        start_time = Time.zone.now
        end_time   = start_time + 120

        interval = WorkInterval.new(
            session: Session.new(total_seconds: 0, target_price: 0, target_hours: 0),
            started_at: start_time,
            ended_at: end_time,
            duration_sec: (end_time - start_time).to_i
        )
        assert_equal 120, interval.duration_sec
    end

    test "duration_sec is nil when ended_at is nil (running)" do
        start_time = Time.zone.now
   
        interval = WorkInterval.new(
            session: Session.new(total_seconds: 0, target_price: 0, target_hours: 0),
            started_at: start_time,
            ended_at: nil,
            duration_sec: nil
        )
        assert_nil interval.duration_sec
    end





end

この機能、テストは書いてるけど機能やDBはまだ作ってもいない、今はテストから先に書く

まずこれは、１日の区間、どれくらいの成果があったか見る機能  のテスト。いや区間の機能ってだけか？それをSessionで定義するのかも

いちにちをどうやって定義するのか

昨日分と進行中は除外されるなら、跨いで止めた分はどう処理されるんだ、浮くんじゃない？
END押した日に計上されるらしい

Sessionにもテストを書くらしい、なんでだ？

とりあえず１日をまとめる機能は実装できたから、見直していく

WorkIntervalモデル
紐付け session_id
Sessionモデル

何年もやってる人でさえ調べながらやるし新しい発見があるんだ、だから少しの進歩だって、大丈夫。自分に優しくて大丈夫
