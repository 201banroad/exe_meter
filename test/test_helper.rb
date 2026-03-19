ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "devise"
require "securerandom"


# ================================
# ✅ モデル系テスト
# ================================
class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)

  def build_work_session(attrs = {})
    user = attrs.delete(:user) || @user
    defaults = {
      total_seconds: 0,
      target_price: 0,
      target_hours: 0,
      user: user
    }
    WorkSession.create!(defaults.merge(attrs))
  end
end


# ================================
# ✅ Integration（コントローラ/ルーティング）系テスト
# ================================
class ActionDispatch::IntegrationTest < ActiveSupport::TestCase
  include Devise::Test::IntegrationHelpers
end
