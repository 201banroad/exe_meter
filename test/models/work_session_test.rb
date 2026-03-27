require "test_helper"

class WorkSessionTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers


  def setup
    @user = User.create!(email: "model@example.com", username: "model_tester", password: "password1")
  end

  test "running? test" do
    work_session = build_work_session
    work_session.work_intervals.create!(started_at: Time.current, ended_at: nil)
    assert work_session.running?
  end

  test "not running? test" do
    work_session = build_work_session
    work_session.work_intervals.create!(started_at: Time.current, ended_at: Time.current)
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

  test "live_seconds adds time when running" do
    base_time = Time.current.change(usec: 0) # ミリ秒の誤差を消す
    travel_to(base_time) do
      work_session = build_work_session(total_seconds: 100)
      work_session.work_intervals.create!(started_at: Time.current, ended_at: nil)
      travel 2.seconds
      assert_equal 102, work_session.live_seconds
    end
  end

  test "hour_price returns 0 when target_hours is 0" do # 0除算ガードのテスト
    work_session = WorkSession.new(user: @user, target_price: 1000, target_hours: 0)
    assert_equal 0, work_session.hour_price
  end

  test "hour_price simple test" do
    work_session = WorkSession.new(user: @user, target_price: 1000, target_hours: 2)
    assert_in_delta 500, work_session.hour_price, 0.01
  end

  test "second_price test" do
    work_session = WorkSession.new(user: @user, target_price: 3600, target_hours: 1)
    assert_in_delta 1, work_session.second_price, 0.01
  end

  test "now_price simple test" do
    work_session = WorkSession.new(user: @user, target_price: 1000, target_hours: 2, total_seconds: 7200)
    assert_in_delta 1000, work_session.now_price, 0.01
  end

  test "now_price during run uses persisted_seconds only" do
    base_time = Time.current.change(usec: 0) # ミリ秒の誤差を消す
    travel_to(base_time) do
      work_session = build_work_session(target_price: 1000, target_hours: 2, total_seconds: 3600)
      work_session.work_intervals.create!(started_at: Time.current, ended_at: nil)
      travel 7200.seconds
      assert_in_delta 500, work_session.now_price, 0.01
    end
  end

  test "today_total_time sums only today's finished intervals" do
    travel_to Time.zone.local(2025, 9, 18, 12, 0, 0) do
      work_session = build_work_session(total_seconds: 0, target_price: 0, target_hours: 0)

      # 昨日の完了区間（含まれない）
      work_session.work_intervals.create!(
        started_at: 1.day.ago,
        ended_at: 1.day.ago + 120,
        duration_sec: 120
      )

      # 今日の完了区間（含まれる）
      work_session.work_intervals.create!(
        started_at: Time.zone.now,
        ended_at: Time.zone.now + 60,
        duration_sec: 60
      )

      work_session.work_intervals.create!(
        started_at: Time.zone.now,
        ended_at: Time.zone.now + 120,
        duration_sec: 120
      )

      # 今日の進行中（含まれない）
      work_session.work_intervals.create!(
        started_at: Time.zone.now,
        ended_at: nil,
        duration_sec: nil
      )

      assert_equal 180, work_session.today_total_time
    end
  end

  test "update_manual_time! sets total_seconds when format is valid" do
    ws = build_work_session(target_hours: 1)

    ws.update_manual_time!("01:30:00")
    ws.reload

    assert_equal 5400, ws.total_seconds       # 1.5h
  end

  test "update_manual_time! raises and sets errors when format is invalid" do
    ws = build_work_session(target_hours: 1)

    assert_raises ActiveRecord::RecordInvalid do
      ws.update_manual_time!("1:99:00")       # 分・秒が 00..59 を超える
    end
    assert ws.errors[:manual_time].present?
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

  test "target_price and target_hours are valid when positive integers" do
    work_session = WorkSession.new(user: @user, target_price: 1, target_hours: 1)
    assert work_session.valid?
  end

  test "target_hours is invalid when decimal" do
    work_session = WorkSession.new(user: @user, target_price: 1, target_hours: 1.5)
    assert_not work_session.valid?
  end

  test "target_price is invalid when decimal" do
    work_session = WorkSession.new(user: @user, target_price: 1.5, target_hours: 1)
    assert_not work_session.valid?
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
    ok  = WorkSession.new(user: @user, target_price: 0, target_hours: 99_999)
    ng  = WorkSession.new(user: @user, target_price: 0, target_hours: 100_000)

    assert ok.valid?, "99_999 should be valid"
    assert_not ng.valid?, "100_000 should be invalid"
  end
end
