# 👉 全テスト共通の初期設定
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "devise"
require "securerandom"

# ルートの再読み込み（test環境でルーティングを確実に使えるように）
Rails.application.reload_routes!

# ================================
# ✅ ルートヘルパを全テストで使えるようにする
# ================================
module RouteHelperForTests
  include Rails.application.routes.url_helpers
  Rails.application.routes.default_url_options[:host] = "www.example.com"
end

# ================================
# ✅ 共通ユーティリティ
# ================================
def create_user(attrs = {})
  User.create!(
    {
      email:    "test+#{SecureRandom.hex(4)}@example.com",
      username: "u_#{SecureRandom.hex(3)}",
      password: "password"
    }.merge(attrs)
  )
end

# ================================
# ✅ Integration（コントローラ/ルーティング）系テスト
# ================================
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include RouteHelperForTests

  def build_work_session(attrs = {})
    user = attrs.delete(:user) || @user || create_user
    defaults = {
      total_seconds: 0,
      target_price:  0,
      target_hours:  0,
      started_at:    nil,
      ended_at:      nil,
      user:          user
    }
    WorkSession.create!(defaults.merge(attrs))
  end
end

# ================================
# ✅ モデル系テスト
# ================================
class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)

  def build_work_session(attrs = {})
    user = attrs.delete(:user) || create_user
    defaults = {
      total_seconds: 0,
      target_price:  0,
      target_hours:  0,
      started_at:    nil,
      ended_at:      nil,
      user:          user
    }
    WorkSession.create!(defaults.merge(attrs))
  end
end

# 最後に明示的にルートヘルパをロード
include Rails.application.routes.url_helpers
Rails.application.routes.default_url_options[:host] = "www.example.com"

