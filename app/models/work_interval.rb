class WorkInterval < ApplicationRecord
  belongs_to :session
end


#これは、カラムを作っただけ。このカラムをどう使うかは、Sessionコントローラで決める、それを応用して、１日の機能にするにはモデルで定義が必要



#ended_atがtoday_rangeにあるduration_secをSUMして1日の合計を出す機能

#いちにちをどうやって定義するのか そういう部品があった

#昨日分と進行中は除外されるなら、跨いで止めた分はどう処理されるんだ、浮くんじゃない？
#END押した日に計上されるらしい

#WorkIntervalモデル
#紐付け session_id
#Sessionモデル

#何年もやってる人でさえ調べながらやるし新しい発見があるんだ、だから少しの進歩だって、大丈夫。自分に優しくて大丈夫

#Price.Hoursは０以上で必ず入ってなきゃいけないから、毎回コード打って作るの面倒だからBeforeActionでさきに入れてる

#テストはCreateにすると毎回バリデーション走るからNewにしてる、保存のテストじゃなくて、機能のテストがしたいだけだから