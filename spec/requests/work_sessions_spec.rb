require 'rails_helper'

RSpec.describe "WorkSessions", type: :request do
  let(:user) { User.create!(email: "test@example.com", password: "password") }

  describe "GET /work_session" do
    it "returns http success" do
      login_as(user, scope: :user)  # ← これ！ sign_in の代わり
      get work_session_path
      expect(response).to have_http_status(:success)
    end
  end
end
