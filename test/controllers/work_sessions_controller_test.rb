require "test_helper"
class WorkSessionsControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers
    setup do
        @user = User.create!(email: "test@example.com", username: "tester", password: "password1")
        sign_in @user, scope: :user
        WorkSession.delete_all
    end

    test "requires login for work_session" do
        sign_out :user
        get work_session_path
        assert_redirected_to new_user_session_path
    end

    test "get work_session" do
        get work_session_path
        assert_response :success
    end



    test "reset clears past completed work_session and zeroes total_seconds" do # 履歴のセッションに対してもリセットできるか
        work_session = build_work_session(total_seconds: 100)

        post reset_work_intervals_path
        work_session.reload

        assert_equal 0, work_session.total_seconds
        assert_redirected_to root_path
        assert_equal "リセットしました", flash[:notice]
    end

    test "reset twice is idempotent" do
        work_session = build_work_session(total_seconds: 50)

        # 1回目のリセット
            post reset_work_intervals_path
        work_session.reload
        assert_equal 0, work_session.total_seconds
        assert_redirected_to root_path
        assert_equal "リセットしました", flash[:notice]

        # 2回目のリセット（何も変わらないことを確認）
            post reset_work_intervals_path
        work_session.reload
        assert_equal 0, work_session.total_seconds
        assert_redirected_to root_path
        assert_equal "リセットしました", flash[:notice]
    end

    test "update_time updates total_seconds when valid manual_time given" do
        work_session = build_work_session(total_seconds: 0)
        patch update_time_work_session_path, params: { work_session: { manual_time: "01:30:00" } }
        work_session.reload
        assert_equal 5400, work_session.total_seconds
        assert_redirected_to root_path
        assert_equal "手動で時間を更新しました", flash[:notice]
    end

    test "update_time rejects invalid manual_time format" do
        work_session = build_work_session(total_seconds: 0)
        patch update_time_work_session_path, params: { work_session: { manual_time: "1:99:00" } }
        assert_response :unprocessable_entity
        assert_match "時間更新に失敗しました", flash[:alert]
    end

    test "update_time does not update when running" do
        work_session = build_work_session(total_seconds: 100)
        work_session.work_intervals.create!(started_at: Time.current, ended_at: nil)

        patch update_time_work_session_path, params: { work_session: { manual_time: "01:00:00" } }

        work_session.reload
        assert_equal 100, work_session.total_seconds
        assert_redirected_to root_path
        assert_equal "タイマー進行中は更新できません", flash[:alert]
    end
end
