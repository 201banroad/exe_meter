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


end


# ================================
# ✅ Integration（コントローラ/ルーティング）系テスト
# ================================
class ActionDispatch::IntegrationTest < ActiveSupport::TestCase
  include Devise::Test::IntegrationHelpers

  def build_work_session(attrs = {}) #引数があればそれをデフォルトに上書きし、メソッド名だけでつまり空で呼び出したらデフォルトが使われる
    user = attrs.delete(:user) || @user #ハッシュからユーザーを取り出して変数に入れる、なかったら定義されてる@userを使う
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


