require "test_helper"
class WorkSessionsControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers
    setup do
        @user = User.create!(email: "test@example.com", username: "tester", password: "password1")
        sign_in @user, scope: :user
        WorkSession.delete_all
    end




    test "requires login for work_session" do
        sign_out @user
        get work_session_path
        assert_redirected_to new_user_session_path
    end



    test "get work_session" do
        get work_session_path
        assert_response :success
    end


    test "start test" do
        # まずレコードをつくる。スタートアクションする。セッションリロードする。インターバルのレコード数える。二つともレコードのエンドがNilか確認。ルートにリダイレクト
        work_session = build_work_session(total_seconds: 0, target_price: 0, target_hours: 0)
        post start_work_session_path
        work_session.reload

        assert_equal 1, work_session.work_intervals.where(ended_at: nil).count
        wi = work_session.work_intervals.order(:created_at).last
        assert_not_nil wi.started_at
        assert_nil wi.ended_at

        assert_not_nil work_session.started_at
        assert_nil work_session.ended_at
        assert_redirected_to root_path
    end

    test "end test" do
        # まず秒未満の細かい数字を０に揃える。トータル秒が10のを作る。2秒進めて、ストップアクションする。リロードし、12秒になってるかを確認する。エンドがNILじゃないか。リダイレクト
        base_time = Time.current.change(usec: 0)
        work_session = build_work_session(total_seconds: 10, target_price: 0, target_hours: 0)

            travel_to(base_time) do
                work_session.update!(started_at: Time.current, ended_at: nil)
                travel 2.seconds
                post stop_work_session_path
                work_session.reload
                assert_equal 12, work_session.total_seconds
                assert_not_nil work_session.ended_at
                assert_redirected_to root_path
            end
    end


    test "end test when dont running" do # 走ってない時にストップ押しても無害テスト
        work_session = build_work_session(total_seconds: 10, started_at: nil, ended_at: nil)

        assert_no_changes -> { work_session.reload.total_seconds } do
            post stop_work_session_path
        end

        work_session.reload
        assert_nil work_session.started_at
        assert_nil work_session.ended_at
        assert_redirected_to root_path
    end


    test "start test when running" do # 走ってる時にスタート押しても無害テスト
        base_time = Time.current.change(usec: 0)
        work_session = build_work_session(total_seconds: 0, started_at: base_time, ended_at: nil)
        assert_no_changes -> { work_session.reload.started_at } do
            post start_work_session_path
        end
        work_session.reload
        # assert_not_nil work_session.started_at
        assert_nil work_session.ended_at
        assert_redirected_to root_path
    end

    test "stop twice while running: second is no-op" do # 走ってる時にストップを二回押しても不変テスト
        base_time = Time.current.change(usec: 0)
        work_session = build_work_session(total_seconds: 10, started_at: base_time, ended_at: nil)

        travel_to(base_time) do
            # 2秒経過させて 1回目の stop（加算されることを確認）
            travel 2.seconds
            post stop_work_session_path
            work_session.reload
            assert_equal 12, work_session.total_seconds       # 10 + 2
            assert_not_nil work_session.ended_at
            assert_redirected_to root_path
        end

        # 2回目の stop（無害）: 時間は進めない
        prev_total = work_session.total_seconds
        prev_ended = work_session.ended_at

        assert_no_changes -> { work_session.reload.total_seconds } do
            post stop_work_session_path
        end
        work_session.reload
        assert_equal prev_ended, work_session.ended_at
        assert_redirected_to root_path
    end

    test "update_target updates values" do
        work_session = build_work_session(target_price: 0, target_hours: 0)
        patch update_target_work_session_path, params: { work_session: { target_price: 1000, target_hours: 2 } }
        work_session.reload
        assert_equal 1000, work_session.target_price
        assert_equal 2, work_session.target_hours
        assert_redirected_to root_path
    end

    test "update_target rejects negative price with 422 and does not persist" do
        work_session = build_work_session(target_price: 1000, target_hours: 2)

        patch update_target_work_session_path, params: { work_session: { target_price: -1000, target_hours: 2 } }

        work_session.reload
        assert_equal 1000, work_session.target_price   # 変わっていない
        assert_equal 2, work_session.target_hours
        assert_response :unprocessable_entity
    end

    test "update_target rejects negative hours with 422 and does not persist" do
        work_session = build_work_session(target_price: 1000, target_hours: 2)

        patch update_target_work_session_path, params: { work_session: { target_price: 1000, target_hours: -1 } }

        work_session.reload
        assert_equal 1000, work_session.target_price
        assert_equal 2, work_session.target_hours      # 変わっていない
        assert_response :unprocessable_entity
    end

    test "update_target rejects blank values with 422 and does not persist" do
        work_session = build_work_session(target_price: 1000, target_hours: 2)

        patch update_target_work_session_path, params: { work_session: { target_price: "", target_hours: "" } }

        work_session.reload
        assert_equal 1000, work_session.target_price
        assert_equal 2, work_session.target_hours      # 変わっていない
        assert_response :unprocessable_entity
    end

    test "reset resets work_session to zero and clears times" do
        work_session = build_work_session(total_seconds: 100, started_at: Time.current, ended_at: Time.current)

        post reset_work_session_path
        work_session.reload

        assert_equal 0, work_session.total_seconds
        assert_nil work_session.started_at
        assert_nil work_session.ended_at
        assert_redirected_to root_path
        assert_equal "リセットしました", flash[:notice]
    end

    test "reset while running clears running state and zeroes total_seconds" do
        work_session = build_work_session(total_seconds: 50, started_at: Time.current, ended_at: nil)

        post reset_work_session_path
        work_session.reload

        assert_equal 0, work_session.total_seconds
        assert_nil work_session.started_at
        assert_nil work_session.ended_at
        assert_redirected_to root_path
        assert_equal "リセットしました", flash[:notice]
    end

    test "reset does nothing when already reset" do
        work_session = build_work_session(total_seconds: 0, started_at: nil, ended_at: nil)

        post reset_work_session_path
        work_session.reload

        assert_equal 0, work_session.total_seconds
        assert_nil work_session.started_at
        assert_nil work_session.ended_at
        assert_redirected_to root_path
        assert_equal "リセットしました", flash[:notice]
    end

    test "reset clears past completed work_session and zeroes total_seconds" do # 履歴のセッションに対してもリセットできるか
        work_session = build_work_session(total_seconds: 100, started_at: 1.hour.ago, ended_at: 30.minutes.ago)

        post reset_work_session_path
        work_session.reload

        assert_equal 0, work_session.total_seconds
        assert_nil work_session.started_at
        assert_nil work_session.ended_at
        assert_redirected_to root_path
        assert_equal "リセットしました", flash[:notice]
    end

    test "reset twice is idempotent" do
        work_session = build_work_session(total_seconds: 50, started_at: Time.current, ended_at: nil)

        # 1回目のリセット
        post reset_work_session_path
        work_session.reload
        assert_equal 0, work_session.total_seconds
        assert_nil work_session.started_at
        assert_nil work_session.ended_at
        assert_redirected_to root_path
        assert_equal "リセットしました", flash[:notice]

        # 2回目のリセット（何も変わらないことを確認）
        post reset_work_session_path
        work_session.reload
        assert_equal 0, work_session.total_seconds
        assert_nil work_session.started_at
        assert_nil work_session.ended_at
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
        work_session = build_work_session(total_seconds: 100, started_at: Time.current, ended_at: nil)
        patch update_time_work_session_path, params: { work_session: { manual_time: "01:00:00" } }
        work_session.reload
        assert_equal 100, work_session.total_seconds
        assert_redirected_to root_path
        assert_equal "タイマー進行中は更新できません", flash[:alert]
    end
end
