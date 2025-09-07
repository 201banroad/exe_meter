require "test_helper"

class SessionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "running? returns true when started_at is set and ended_at is nil" do #つまりこの設定でちゃんとrunningと判定されるか
    session = Session.new(started_at: Time.current, ended_at: nil)
    assert session.running?
  end

  test "running? returns false when both started_at and ended_at are present" do
    session = Session.new( started_at: Time.current, ended_at: Time.current )
    assert_not session.running?
  end

  test "persisted_seconds returns 0 when total_seconds is nil" do
    session = Session.new(total_seconds: nil) 
    assert_equal 0, session.persisted_seconds
  end

  test "persisted_seconds returns total_seconds when present" do
    session = Session.new(total_seconds: 120)
    assert_equal 120, session.persisted_seconds
  end

  test "live_seconds returns total_seconds when not running" do
    session = Session.new(total_seconds: 100)
    assert_equal 100, session.live_seconds
  end

  test "live_seconds adds elapsed time when running" do
    base_time = Time.current.change(usec: 0) # ミリ秒の誤差を消す
    travel_to(base_time) do
      session = Session.new(total_seconds: 100, started_at: Time.current, ended_at: nil)
      travel 2.seconds
      assert_equal 102, session.live_seconds
    end
  end

  test "hour_price returns 0 when target_hours is 0" do 
    session = Session.new(target_price: 1000, target_hours: 0)
    assert_equal 0, session.hour_price
  end

  test "hour_price returns correct value when target_price and target_hours are positive" do 
    session = Session.new(target_price: 1000, target_hours: 2)
    assert_equal 500, session.hour_price
  end

  test "hour_price returns correct decimal when target_hours is 1.5" do 
    session = Session.new(target_price: 1000, target_hours: 1.5)
    assert_in_delta 666.67, session.hour_price, 0.1
  end

  test "now_price multiplies hour_price and live_hours when stopped" do#停止中の整数ケース
    sessison = Session.new(target_price: 1000, target_hours: 2, total_seconds: 7200)
    assert_equal 1000, session.now_price
  end

  test "now_price returns correct value when live_hours is decimal" do  #停止中の少数ケース
    session = Session.new(target_price: 1200, target_hours: 2, total_seconds: 5400 )
    assert_in_delta 900, session.now_price, 0.01
  end

  test "now_price during run adds elapsed hours (integer case)" do#実行中の整数ケース
    base_time = Time.current.change(usec: 0) # ミリ秒の誤差を消す
    travel_to(base_time) do
      session = Session.new(started_at: Time.current, ended_at: nil, target_price: 1000, target_hours: 2, total_seconds: 3600 )
      travel 7200.seconds
      assert_equal 1500, session.now_price
    end
  end

  test "now_price calculates correctly when running with fractional hour" do#実行中の少数ケース
    base_time = Time.current.change(usec: 0) # ミリ秒の誤差を消す
    travel_to(base_time) do
      session = Session.new(started_at: Time.current, ended_at: nil, target_price: 1200, target_hours: 2, total_seconds: 1800 )
      travel 3600.seconds
      assert_in_delta 900, session.now_price, 0.01
    end
  end


  #ここからバリデーションのテスト　　ほかのひらがなとか弾くテスト書く？と思ったけどRailsの機能で元々弾かれてるからわざわざ書かなくてOK
  test "target_price and target_hours are invalid when negative" do
    session = Session.new(target_price: -1, target_hours: -1)
    assert_not session.valid?
  end

  test "target_price and target_hours are valid when zero" do
    session = Session.new(target_price: 0, target_hours: 0)
    assert session.valid?
  end

  test "target_price and target_hours are valid when positive numbers (including decimal hours)" do
    session = Session.new(target_price: 1, target_hours: 1.5)
    assert session.valid?
  end

  test "target_price and target_hours are invalid when nil" do
    session = Session.new(target_price: nil, target_hours: nil)
    assert_not session.valid?
  end

  test "target_price and target_hours are invalid when empty string" do
    session = Session.new(target_price: "", target_hours: "")
    assert_not session.valid?
  end

end
