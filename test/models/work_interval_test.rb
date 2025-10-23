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
