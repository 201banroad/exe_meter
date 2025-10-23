require 'rails_helper'

# RSpec.describe Session, type: :model do
#   pending "add some examples to (or delete) #{__FILE__}"
# end



# 時刻を固定/移動できるヘルパ
# rails_helper.rb で `config.include ActiveSupport::Testing::TimeHelpers` を設定しておくと使える
RSpec.describe WorkSession, type: :model do
  describe '#running?' do #進行中と停止が正しく判断されるかのテスト
    it 'started_at があり、ended_at が nil のとき true（進行中）' do
      s = described_class.new(started_at: Time.current) # 終了時間は未設定
      expect(s.running?).to be true                      # ⇒ 進行中と判断
    end
    #自動で作られたテストなので一旦基本の１つ以外は保留
#     it 'ended_at が入っていれば false（停止済み）' do
#       s = described_class.new(started_at: Time.current, ended_at: Time.current)
#       expect(s.running?).to be false
#     end
   end

#   describe '#live_seconds と #live_hours' do #トータルタイムのテスト、停止済みと進行中どちらもOKか
#     it '停止済みなら total_seconds をそのまま返す' do
#       # すでに1時間分（3600秒）が保存されている想定
#       s = described_class.new(total_seconds: 3600, started_at: 2.hours.ago, ended_at: 1.hour.ago)
#       expect(s.live_seconds).to eq 3600
#       expect(s.live_hours).to eq 1.0
#     end

#     it '進行中なら total_seconds + (現在時刻 - started_at) を返す' do
#       # テスト時刻を 2025-08-29 12:00:00 JST に固定
#       travel_to Time.zone.parse('2025-08-29 12:00:00') do
#         # すでに1時間ぶん保存済み + 11:00 に開始して今12:00なので +3600秒
#         s = described_class.new(total_seconds: 3600, started_at: 1.hour.ago)
#         expect(s.live_seconds).to eq(3600 + 3600) # 7200
#         expect(s.live_hours).to eq 2.0
#       end
#     end
#   end

#   describe '#hour_price（時給 = 目標金額 ÷ 目標時間）' do #時給を出す時の除算ガードとto_fが機能しているか（.0まで期待しているので）
#     it 'target_hours が 0 または nil のときは 0（0除算ガード）' do
#       expect(described_class.new(target_price: 1_000_000, target_hours: 0).hour_price).to eq 0
#       expect(described_class.new(target_price: 1_000_000, target_hours: nil).hour_price).to eq 0
#     end

#     it '金額/時間 を小数で計算する（整数同士の割り算対策に to_f）' do
#       s = described_class.new(target_price: 1_000_000, target_hours: 50)
#       expect(s.hour_price).to eq 20_000.0 # 100万円 / 50h = 2万円/h
#     end
#   end

#   describe '#now_price（現在の市場価値 = 時給 × 実働時間）' do #市場価値の計算がしっかりできるかのテスト
#     it 'live_hours に比例して増える' do
#       # 3時間ぶんの実働が total_seconds に保存されている想定
#       s = described_class.new(target_price: 1_000_000, target_hours: 50, total_seconds: 3 * 3600)
#       # hour_price=20000.0, live_hours=3.0 → now_price=60000.0
#       expect(s.now_price).to eq 60_000.0
#     end

#     it '進行中の時間も含めて増える' do
#       travel_to Time.zone.parse('2025-08-29 12:00:00') do
#         # 11:30開始で現在12:00 → 30分=0.5hぶん上乗せされる
#         s = described_class.new(target_price: 1_000_000, target_hours: 50, total_seconds: 3 * 3600, started_at: 30.minutes.ago)
#         # base 3.0h + 0.5h = 3.5h → 20000 * 3.5 = 70000
#         expect(s.now_price).to be_within(0.001).of(70_000.0)
#       end
#     end
#   end

#   describe '#progress_ratio（達成度= now_price / target_price、最大1.0）' do
#     it 'target_price が 0 以下なら 0.0' do
#       s = described_class.new(target_price: 0, target_hours: 10, total_seconds: 3600)
#       expect(s.progress_ratio).to eq 0.0
#     end

#     it '達成度は 0.0〜1.0 にクランプされる' do
#       # 2時間実働、目標は1時間で10万円 → now_priceは20万円になるが、比率は1.0で打ち止め
#       s = described_class.new(target_price: 100_000, target_hours: 1, total_seconds: 2 * 3600)
#       expect(s.progress_ratio).to eq 1.0
#     end

#     it '途中経過（例: 25%）も正しく出る' do
#       # 目標100万円/50h → 時給2万円。実働10h → 20万。比率0.2
#       s = described_class.new(target_price: 1_000_000, target_hours: 50, total_seconds: 10 * 3600)
#       expect(s.progress_ratio).to be_within(1e-9).of(0.2)
#     end
#   end
end
