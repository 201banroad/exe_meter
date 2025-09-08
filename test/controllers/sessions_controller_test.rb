require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest

    test "get session" do
        get session_path
        assert_response :success
    end

    test "start time" do 
        session = Session.first_or_create!(total_seconds: 0, target_price: 0, target_hours: 0)
        post start_session_path
        session.reload
        asert_not_nil session.started_at
        asert_nil session.ended_at
        assert_redirected_to root_path
    end



end
