# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# db/seeds.rb

# プラットフォーム
['YouTube', 'Twitch', 'ツイキャス', 'ニコニコ生放送', 'spoon', 'IRIAM', 'REALITY', 'パルム', 'ポコチャ', 'ビゴ ライブ', 'ColorSing', 'ふわっち', '17LIVE', 'ミラティブ', 'Avvy'].each do |name|
  StreamingPlatform.find_or_create_by!(name: name)
end

# カテゴリ
['ゲーム実況', '雑談', '歌', '弾き語り', '演奏', 'お絵描き', '癒し', 'おもしろ', '趣味', '企画', '声劇・朗読', 'コラボ・凸待ち', '悩み・相談'].each do |name|
  StreamingCategory.find_or_create_by!(name: name)
end

# 経験レベル
['初心者(1ヶ月未満)', '経験者(1ヶ月〜1年)', '中級者(1年以上)', '上級者(3年以上)', 'ベテラン(5年以上)'].each do |name|
  StreamingExperience.find_or_create_by!(name: name)
end