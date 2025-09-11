require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest

    test "get session" do
        get session_path
        assert_response :success
    end

    test "start test" do 
        session = Session.first_or_create!(total_seconds: 0, target_price: 0, target_hours: 0)
        post start_session_path
        session.reload
        asert_not_nil session.started_at
        asert_nil session.ended_at
        assert_redirected_to root_path
    end

    test "end test" do
        base_time = Time.current.change(usec: 0)
        session = Session.first_or_create!(total_seconds: 10, target_price: 0, target_hours: 0)

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
        session = Session.first_or_create!(total_seconds: 10, started_at: nil, ended_at: nil)

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
        session = Session.first_or_create!(total_seconds: 0, started_at: base_time, ended_at: nil)
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
        session = Session.first_or_create!(total_seconds: 10, started_at: base_time, ended_at: nil)

        include ActiveSupport::Testing::TimeHelpers
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
        session = Session.first_or_create!(target_price: 0, target_hours: 0)
        patch update_target_session_path, params: { session: { target_price: 1000, target_hours: 2 } }
        session.reload
        assert_equal 1000, session.target_price
        assert_equal 2, session.target_hours
        assert_redirected_to root_path
    end
    
    test "update_target rejects negative price with 422 and does not persist" do
        session = Session.create!(target_price: 1000, target_hours: 2)

        patch update_target_session_path, params: { session: { target_price: -1000, target_hours: 2 } }

        session.reload
        assert_equal 1000, session.target_price   # 変わっていない
        assert_equal 2, session.target_hours
        assert_response :unprocessable_entity
    end

    test "update_target rejects negative hours with 422 and does not persist" do
        session = Session.create!(target_price: 1000, target_hours: 2)

        patch update_target_session_path, params: { session: { target_price: 1000, target_hours: -1 } }

        session.reload
        assert_equal 1000, session.target_price
        assert_equal 2, session.target_hours      # 変わっていない
        assert_response :unprocessable_entity
    end

    test "update_target rejects blank values with 422 and does not persist" do
        session = Session.create!(target_price: 1000, target_hours: 2)

        patch update_target_session_path, params: { session: { target_price: "", target_hours: "" } }

        session.reload
        assert_equal 1000, session.target_price
        assert_equal 2, session.target_hours      # 変わっていない
        assert_response :unprocessable_entity
    end


end

