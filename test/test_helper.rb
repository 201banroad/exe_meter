# 👉 「全テスト共通で適用したい初期設定や便利メソッドをまとめておく場所」
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase # こっちはモデル
  # 並列実行（必要なら）
  parallelize(workers: :number_of_processors)

  fixtures :all

  # ここに共通ヘルパー（DBに保存してから返す）
  def build_session(attrs = {})
    defaults = {
      total_seconds: 0,
      target_price:  0,
      target_hours:  0,
      started_at:    nil,
      ended_at:      nil
    }
    Session.create!(defaults.merge(attrs))
  end
end

class ActionDispatch::IntegrationTest # こっちはコントローラ、ルーティング
  # IntegrationTest は ActiveSupport::TestCase を継承しないので、
  # 同じメソッドが必要ならこちらにも定義する
  def build_session(attrs = {})
    defaults = {
      total_seconds: 0,
      target_price:  0,
      target_hours:  0,
      started_at:    nil,
      ended_at:      nil
    }
    Session.create!(defaults.merge(attrs))
  end
end
