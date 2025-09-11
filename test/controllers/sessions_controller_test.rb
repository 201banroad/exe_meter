require "test_helper"
#ヘルパーにて、初期値を設定build_session（数字を与えてないカラムがNilになってしまうため）
class SessionsControllerTest < ActionDispatch::IntegrationTest
    include ActiveSupport::Testing::TimeHelpers

    setup do
        Session.delete_all   # ← 前回の残ったパラメータを消してくれる、ここに一行書くだけでOK！or createだと前回のテスト持ち越すのでリセットのためのコード
    end

    test "get session" do
        get session_path
        assert_response :success
    end

    test "start test" do 
        session = build_session(total_seconds: 0, target_price: 0, target_hours: 0)
        post start_session_path
        session.reload
        assert_not_nil session.started_at
        assert_nil session.ended_at
        assert_redirected_to root_path
    end

    test "end test" do
        base_time = Time.current.change(usec: 0)
        session = build_session(total_seconds: 10, target_price: 0, target_hours: 0)

            travel_to(base_time) do
                session.update!(started_at: Time.current, ended_at: nil)

                travel 2.seconds
                post stop_session_path
                session.reload
                assert_equal 12, session.total_seconds  
                assert_not_nil session.ended_at
                assert_redirected_to root_path
            end
    end

    test "end test when dont running" do #走ってない時にストップ押しても無害テスト
        session = build_session(total_seconds: 10, started_at: nil, ended_at: nil)

        assert_no_changes -> { session.reload.total_seconds } do
            post stop_session_path
        end

        session.reload
        assert_nil session.started_at
        assert_nil session.ended_at
        assert_redirected_to root_path
    end


    test "start test when running" do #走ってる時にスタート押しても無害テスト
        base_time = Time.current.change(usec: 0)
        session = build_session(total_seconds: 0, started_at: base_time, ended_at: nil)
        assert_no_changes -> {session.reload.started_at } do
            post start_session_path
        end
        session.reload
        # assert_not_nil session.started_at
        assert_nil session.ended_at
        assert_redirected_to root_path
    end

    test "stop twice while running: second is no-op" do #走ってる時にストップを二回押しても不変テスト
        base_time = Time.current.change(usec: 0)
        session = build_session(total_seconds: 10, started_at: base_time, ended_at: nil)

        travel_to(base_time) do
            # 2秒経過させて 1回目の stop（加算されることを確認）
            travel 2.seconds
            post stop_session_path
            session.reload
            assert_equal 12, session.total_seconds       # 10 + 2
            assert_not_nil session.ended_at
            assert_redirected_to root_path
        end

        # 2回目の stop（無害）: 時間は進めない
        prev_total = session.total_seconds
        prev_ended = session.ended_at

        assert_no_changes -> { session.reload.total_seconds } do
            post stop_session_path
        end
        session.reload
        assert_equal prev_ended, session.ended_at
        assert_redirected_to root_path
    end

    test "update_target updates values" do
        session = build_session(target_price: 0, target_hours: 0)
        patch update_target_session_path, params: { session: { target_price: 1000, target_hours: 2 } }
        session.reload
        assert_equal 1000, session.target_price
        assert_equal 2, session.target_hours
        assert_redirected_to root_path
    end

    test "update_target rejects negative price with 422 and does not persist" do
        session = build_session(target_price: 1000, target_hours: 2)

        patch update_target_session_path, params: { session: { target_price: -1000, target_hours: 2 } }

        session.reload
        assert_equal 1000, session.target_price   # 変わっていない
        assert_equal 2, session.target_hours
        assert_response :unprocessable_entity
    end

    test "update_target rejects negative hours with 422 and does not persist" do
        session = build_session(target_price: 1000, target_hours: 2)

        patch update_target_session_path, params: { session: { target_price: 1000, target_hours: -1 } }

        session.reload
        assert_equal 1000, session.target_price
        assert_equal 2, session.target_hours      # 変わっていない
        assert_response :unprocessable_entity
    end

    test "update_target rejects blank values with 422 and does not persist" do
        session = build_session(target_price: 1000, target_hours: 2)

        patch update_target_session_path, params: { session: { target_price: "", target_hours: "" } }

        session.reload
        assert_equal 1000, session.target_price
        assert_equal 2, session.target_hours      # 変わっていない
        assert_response :unprocessable_entity
    end

    test "reset resets session to zero and clears times" do
        session = build_session(total_seconds: 100, started_at: Time.current, ended_at: Time.current)

        post reset_session_path
        session.reload

        assert_equal 0, session.total_seconds
        assert_nil session.started_at
        assert_nil session.ended_at
        assert_redirected_to root_path
        assert_equal "リセットしました", flash[:notice]
    end

    test "reset while running clears running state and zeroes total_seconds" do
        session = build_session(total_seconds: 50, started_at: Time.current, ended_at: nil)

        post reset_session_path
        session.reload

        assert_equal 0, session.total_seconds
        assert_nil session.started_at
        assert_nil session.ended_at
        assert_redirected_to root_path
        assert_equal "リセットしました", flash[:notice]
    end

    test "reset does nothing when already reset" do
        session = build_session(total_seconds: 0, started_at: nil, ended_at: nil)

        post reset_session_path
        session.reload

        assert_equal 0, session.total_seconds
        assert_nil session.started_at
        assert_nil session.ended_at
        assert_redirected_to root_path
        assert_equal "リセットしました", flash[:notice]
    end

    test "reset clears past completed session and zeroes total_seconds" do #履歴のセッションに対してもリセットできるか
        session = build_session(total_seconds: 100, started_at: 1.hour.ago, ended_at: 30.minutes.ago)

        post reset_session_path
        session.reload

        assert_equal 0, session.total_seconds
        assert_nil session.started_at
        assert_nil session.ended_at
        assert_redirected_to root_path
        assert_equal "リセットしました", flash[:notice]
    end

    test "reset twice is idempotent" do
        session = build_session(total_seconds: 50, started_at: Time.current, ended_at: nil)

        # 1回目のリセット
        post reset_session_path
        session.reload
        assert_equal 0, session.total_seconds
        assert_nil session.started_at
        assert_nil session.ended_at
        assert_redirected_to root_path
        assert_equal "リセットしました", flash[:notice]

        # 2回目のリセット（何も変わらないことを確認）
        post reset_session_path
        session.reload
        assert_equal 0, session.total_seconds
        assert_nil session.started_at
        assert_nil session.ended_at
        assert_redirected_to root_path
        assert_equal "リセットしました", flash[:notice]
    end



    



end

