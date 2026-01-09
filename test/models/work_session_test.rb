require "test_helper"

class WorkSessionTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  def setup
    @user = User.create!(email: "model@example.com", username: "model_tester", password: "password1")
  end

  test "running? returns true when started_at is set and ended_at is nil" do # つまりこの設定でちゃんとrunningと判定されるか
    work_session = WorkSession.new(user: @user, started_at: Time.current, ended_at: nil)
    assert work_session.running?
  end

  test "running? returns false when both started_at and ended_at are present" do
    work_session = WorkSession.new(user: @user, started_at: Time.current, ended_at: Time.current)
    assert_not work_session.running?
  end

  test "persisted_seconds returns 0 when total_seconds is nil" do
    work_session = WorkSession.new(user: @user, total_seconds: nil)
    assert_equal 0, work_session.persisted_seconds
  end

  test "persisted_seconds returns total_seconds when present" do
    work_session = WorkSession.new(user: @user, total_seconds: 120)
    assert_equal 120, work_session.persisted_seconds
  end

  test "live_seconds returns total_seconds when not running" do
    work_session = WorkSession.new(user: @user, total_seconds: 100)
    assert_equal 100, work_session.live_seconds
  end

  test "live_seconds adds elapsed time when running" do
    base_time = Time.current.change(usec: 0) # ミリ秒の誤差を消す
    travel_to(base_time) do
      work_session = WorkSession.new(user: @user, total_seconds: 100, started_at: Time.current, ended_at: nil)
      travel 2.seconds
      assert_equal 102, work_session.live_seconds
    end
  end

  test "hour_price returns 0 when target_hours is 0" do # 0除算ガードのテスト
    work_session = WorkSession.new(user: @user, target_price: 1000, target_hours: 0)
    assert_equal 0, work_session.hour_price
  end

  test "hour_price returns correct value when target_price and target_hours are positive" do
    work_session = WorkSession.new(user: @user, target_price: 1000, target_hours: 2)
    assert_equal 500, work_session.hour_price
  end

  test "hour_price returns correct decimal when target_hours is 1.5" do
    work_session = WorkSession.new(user: @user, target_price: 1000, target_hours: 1.5)
    assert_in_delta 666.67, work_session.hour_price, 0.1
  end

  test "now_price multiplies hour_price and live_hours when stopped" do# 停止中の整数ケース
    work_session = WorkSession.new(user: @user, target_price: 1000, target_hours: 2, total_seconds: 7200)
    assert_equal 1000, work_session.now_price
  end

  test "now_price returns correct value when live_hours is decimal" do  # 停止中の少数ケース
    work_session = WorkSession.new(user: @user, target_price: 1200, target_hours: 2, total_seconds: 5400)
    assert_in_delta 900, work_session.now_price, 0.01
  end

  test "now_price during run adds elapsed hours (integer case)" do# 実行中の整数ケース
    base_time = Time.current.change(usec: 0) # ミリ秒の誤差を消す
    travel_to(base_time) do
      work_session = WorkSession.new(user: @user, started_at: Time.current, ended_at: nil, target_price: 1000, target_hours: 2, total_seconds: 3600)
      travel 7200.seconds
      assert_equal 1500, work_session.now_price
    end
  end

  test "now_price calculates correctly when running with fractional hour" do# 実行中の少数ケース
    base_time = Time.current.change(usec: 0) # ミリ秒の誤差を消す
    travel_to(base_time) do
      work_session = WorkSession.new(user: @user, started_at: Time.current, ended_at: nil, target_price: 1200, target_hours: 2, total_seconds: 1800)
      travel 3600.seconds
      assert_in_delta 900, work_session.now_price, 0.01
    end
  end

  test "progress_ratio is 0.0 when target_price is zero" do
    work_session = WorkSession.new(user: @user, target_price: 0, target_hours: 2, total_seconds: 7200)
    assert_equal 0.0, work_session.progress_ratio
  end

  # 2) 途中の進捗 (例: 30%)
  test "progress_ratio returns fractional value below 1.0" do
    # 時給 500円 (= 1000 ÷ 2h)、実働 0.6h (= 2160秒) → now_price=300
    work_session = WorkSession.new(user: @user, target_price: 1000, target_hours: 2, total_seconds: 2160)
    assert_in_delta 0.3, work_session.progress_ratio, 1e-6
  end

  # 3) ちょうど達成 (1.0)
  test "progress_ratio returns 1.0 when goal reached" do
    # 時給 500円、実働 2h (= 7200秒) → now_price=1000
    work_session = WorkSession.new(user: @user, target_price: 1000, target_hours: 2, total_seconds: 7200)
    assert_equal 1.0, work_session.progress_ratio
  end

  # 4) 超過しても 1.0 にクリップ
  test "progress_ratio does not exceed 1.0 even when now_price > target_price" do
    # 時給 500円、実働 3h (= 10800秒) → now_price=1500
    work_session = WorkSession.new(user: @user, target_price: 1000, target_hours: 2, total_seconds: 10800)
    assert_equal 1.0, work_session.progress_ratio
  end

  # 5) 実行中でも正しく増える
  test "progress_ratio increases while running" do
    base_time = Time.current.change(usec: 0)
    travel_to(base_time) do
      work_session = WorkSession.new(
        user: @user,
        target_price: 1200,
        target_hours: 2,  # 時給 600
        total_seconds: 1800, # 0.5h
        started_at: Time.current,
        ended_at: nil
      )
      travel 3600.seconds # +1h → 合計1.5h
      assert_in_delta 0.75, work_session.progress_ratio, 0.01
    end
  end


  # ここからバリデーションのテスト　　ほかのひらがなとか弾くテスト書く？と思ったけどRailsの機能で元々弾かれてるからわざわざ書かなくてOK
  test "target_price and target_hours are invalid when negative" do
    work_session = WorkSession.new(user: @user, target_price: -1, target_hours: -1)
    assert_not work_session.valid?
  end

  test "target_price and target_hours are valid when zero" do
    work_session = WorkSession.new(user: @user, target_price: 0, target_hours: 0)
    assert work_session.valid?
  end

  test "target_price and target_hours are valid when positive numbers (including decimal hours)" do
    work_session = WorkSession.new(user: @user, target_price: 1, target_hours: 1.5)
    assert work_session.valid?
  end

  test "target_price and target_hours are invalid when nil" do
    work_session = WorkSession.new(user: @user, target_price: nil, target_hours: nil)
    assert_not work_session.valid?
  end

  test "target_price and target_hours are invalid when empty string" do
    work_session = WorkSession.new(user: @user, target_price: "", target_hours: "")
    assert_not work_session.valid?
  end

  test "target_hours is valid below 100_000 and invalid at 100_000" do
    ok  = WorkSession.new(user: @user, target_price: 0, target_hours: 99_999.9)
    ng  = WorkSession.new(user: @user, target_price: 0, target_hours: 100_000)

    assert ok.valid?, "99_999.9 should be valid"
    assert_not ng.valid?, "100_000 should be invalid"
  end


  test "today_total_seconds sums only today's finished intervals" do
    travel_to Time.zone.local(2025, 9, 18, 12, 0, 0) do
      work_session = WorkSession.new(user: @user, total_seconds: 0, target_price: 0, target_hours: 0)

      # 昨日の完了区間（含まれない）
      work_session.work_intervals << WorkInterval.new(
        started_at: 1.day.ago,
        ended_at: 1.day.ago + 120,
        duration_sec: 120
      )

      # 今日の完了区間（含まれる）
      work_session.work_intervals << WorkInterval.new(
        started_at: Time.zone.now,
        ended_at: Time.zone.now + 60,
        duration_sec: 60
      )

      work_session.work_intervals << WorkInterval.new(
        started_at: Time.zone.now,
        ended_at: Time.zone.now + 120,
        duration_sec: 120
      )

      # 今日の進行中（含まれない）
      work_session.work_intervals << WorkInterval.new(
        started_at: Time.zone.now,
        ended_at: nil,
        duration_sec: nil
      )

      assert_equal 180, work_session.today_total_seconds
    end
  end

  test "update_manual_time! sets total_seconds and clears started/ended when format is valid" do
    ws = WorkSession.create!(user: @user, target_price: 0, target_hours: 1, total_seconds: 0)

    ws.update_manual_time!("01:30:00")
    ws.reload

    assert_equal 5400, ws.total_seconds       # 1.5h
    assert_nil ws.started_at
    assert_nil ws.ended_at
  end

  test "update_manual_time! raises and sets errors when format is invalid" do
    ws = WorkSession.create!(user: @user, target_price: 0, target_hours: 1, total_seconds: 0)

    assert_raises ActiveRecord::RecordInvalid do
      ws.update_manual_time!("1:99:00")       # 分・秒が 00..59 を超える
    end
    assert ws.errors[:manual_time].present?
  end
end
