# 👉 「全テスト共通で適用したい初期設定や便利メソッドをまとめておく場所」
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "devise"
require "securerandom"

# Deviseのマッピング（devise_for :users）を確実に読み込む
Rails.application.reload_routes!

# -------------------------
# 共通ユーティリティ
# -------------------------
def create_user(attrs = {})
  User.create!(
    {
      email:    "test+#{SecureRandom.hex(4)}@example.com",
      username: "u_#{SecureRandom.hex(3)}",
      password: "password"
    }.merge(attrs)
  )
end

# -------------------------
# Integration（コントローラ/ルーティング）系
# -------------------------
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include Rails.application.routes.url_helpers   # ← URLヘルパを可視化

  # 必要ならURL生成用のhost（pathだけなら不要）
  # Rails.application.routes.default_url_options[:host] = "www.example.com"

  def build_work_session(attrs = {})
    user = attrs.delete(:user) || @user || create_user
    defaults = {
      total_seconds: 0,
      target_price:  0,
      target_hours:  0,
      started_at:    nil,
      ended_at:      nil,
      user:          user                      # ← 必ず関連づける
    }
    WorkSession.create!(defaults.merge(attrs))
  end
end

# -------------------------
# モデル系
# -------------------------
class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)

  def build_work_session(attrs = {})
    user = attrs.delete(:user) || create_user   # ← モデル側でも必ず関連づける
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
