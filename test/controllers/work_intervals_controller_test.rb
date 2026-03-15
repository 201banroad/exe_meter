    require "test_helper"

class WorkIntervalsControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @user = User.create!(email: "test2@example.com", username: "tester2", password: "password2")
    sign_in @user, scope: :user
    WorkSession.delete_all
  end

  test "start creates new interval" do
    work_session = build_work_session
    post start_work_intervals_path
    work_session.reload
    assert_equal 1, work_session.work_intervals.where(ended_at: nil).count
    wi = work_session.work_intervals.order(:created_at).last
    assert_not_nil wi.started_at
    assert_nil wi.ended_at
    assert_redirected_to root_path
  end
  
    test "stop ends running interval and updates total_seconds" do
      work_session = build_work_session(total_seconds: 10)
      now = Time.current.change(usec: 0)
      travel_to(now) do
        wi = work_session.work_intervals.create!(started_at: now, ended_at: nil)
        travel 2.seconds
        post stop_work_intervals_path
        work_session.reload
        wi.reload
        assert_equal 12, work_session.total_seconds
        assert_not_nil wi.ended_at
        assert_redirected_to root_path
      end
    end

    test "stop when not running does nothing" do
      work_session = build_work_session(total_seconds: 10)
      assert_no_changes -> { work_session.reload.total_seconds } do
        post stop_work_intervals_path
      end
      work_session.reload
      assert_redirected_to root_path
    end

    test "reset resets work_session to zero and clears intervals" do
      work_session = build_work_session(total_seconds: 100)
      wi = work_session.work_intervals.create!(started_at: Time.current, ended_at: nil)
      post reset_work_intervals_path
      work_session.reload
      assert_equal 0, work_session.total_seconds
      assert_equal 0, work_session.work_intervals.where(ended_at: nil).count
      assert_redirected_to root_path
      assert_equal "リセットしました", flash[:notice]
    end


    test "reset clears past completed work_session and zeroes total_seconds" do
      work_session = build_work_session(total_seconds: 100)
      wi = work_session.work_intervals.create!(started_at: 1.hour.ago, ended_at: 30.minutes.ago)
      post reset_work_intervals_path
      work_session.reload
      assert_equal 0, work_session.total_seconds
      assert_equal 0, work_session.work_intervals.where(ended_at: nil).count
      assert_redirected_to root_path
      assert_equal "リセットしました", flash[:notice]
    end

    test "reset twice is idempotent" do
      work_session = build_work_session(total_seconds: 50)
      wi = work_session.work_intervals.create!(started_at: Time.current, ended_at: nil)
      post reset_work_intervals_path
      work_session.reload
      assert_equal 0, work_session.total_seconds
      assert_equal 0, work_session.work_intervals.where(ended_at: nil).count
      assert_redirected_to root_path
      assert_equal "リセットしました", flash[:notice]
      post reset_work_intervals_path
      work_session.reload
      assert_equal 0, work_session.total_seconds
      assert_equal 0, work_session.work_intervals.where(ended_at: nil).count
      assert_redirected_to root_path
      assert_equal "リセットしました", flash[:notice]
    end
    
end
