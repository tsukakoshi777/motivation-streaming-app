# frozen_string_literal: true

namespace :ai do
  desc 'AI提案プロンプトの精度検証'
  task verify: :environment do |_task, _args|
    # ユーザーIDを環境変数から取得（デフォルトは全ユーザー）
    user_id = ENV.fetch('USER_ID', nil)

    puts '=' * 80
    puts 'AI提案の精度検証を開始します'
    puts '使用モデル: gemini-2.5-flash'
    puts '=' * 80
    puts ''

    # データベース内のプロフィールを確認
    puts '📊 データベース内のプロフィールを確認中...'

    # ユーザーIDが指定されている場合は、そのユーザーのプロフィールのみ取得
    profiles = if user_id.present?
                 SurveyProfile.includes(:streaming_experience, :survey_response, :streaming_platform,
                                        :streaming_category)
                              .where(user_id: user_id)
                              .limit(5)
               else
                 SurveyProfile.includes(:streaming_experience, :survey_response, :streaming_platform,
                                        :streaming_category)
                              .limit(5)
               end

    if profiles.empty?
      puts '⚠️  データベースにプロフィールが存在しません'
      puts '  まず、アプリでアンケートを作成してください'
      exit
    end

    puts "✅ #{profiles.count}件のプロフィールが見つかりました"
    puts ''

    # 各プロフィールでテスト
    profiles.each_with_index do |profile, index|
      puts '-' * 80
      puts "【テストケース #{index + 1}】"
      puts '-' * 80

      begin
        survey_response = profile.survey_response

        unless survey_response
          puts "⚠️  このプロフィール（ID: #{profile.id}）にはアンケート回答がありません"
          puts ''
          next
        end

        # プロフィール情報を表示
        puts "\n■ 配信者情報:"
        puts "  - プラットフォーム: #{profile.streaming_platform&.name || '未設定'}"
        puts "  - カテゴリ: #{profile.streaming_category&.name || '未設定'}"
        puts "  - 配信経験: #{profile.streaming_experience&.name || '未設定'}"
        puts "  - 週の配信頻度: #{profile.weekly_frequency}回"
        puts "  - 平均視聴者数: #{profile.average_listeners}人"
        puts "  - 視聴者離脱率: #{profile.listener_dropout_rate}%"
        puts "  - モチベーションレベル: #{profile.motivation_level}/5"
        puts ''

        puts '■ アンケート回答:'
        puts "  - 配信で嬉しかった瞬間: #{survey_response.happy_moment&.truncate(50) || '未回答'}"
        puts "  - 配信で辛かった瞬間: #{survey_response.sad_moment&.truncate(50) || '未回答'}"
        puts "  - 配信を始めた理由: #{survey_response.streaming_reasons&.truncate(50) || '未回答'}"
        puts "  - 理想の配信スタイル: #{survey_response.desired_streaming_style&.truncate(50) || '未回答'}"
        puts ''

        # AI提案を生成
        puts '■ AI提案を生成中...'
        service = GeminiService.new
        start_time = Time.current

        result = service.suggest_streamer_goal(
          survey_profile: profile,
          survey_response: survey_response
        )

        elapsed_time = Time.current - start_time

        # 結果を表示
        puts "\n■ 生成された提案（生成時間: #{elapsed_time.round(2)}秒）:"
        puts ''
        puts '  【タイトル】'
        puts "  #{result[:goal_title]}"
        puts "  (文字数: #{result[:goal_title].length}文字)"
        puts ''
        puts '  【説明】'
        puts "  #{result[:goal_description]}"
        puts "  (文字数: #{result[:goal_description].length}文字)"
        puts ''
        puts '  【アクションプラン】'
        result[:action_plan].split("\n").each do |line|
          puts "  #{line}"
        end
        puts ''

        # 評価ポイントを表示
        puts '■ 評価チェックリスト:'
        title_ok = result[:goal_title].length <= 20
        desc_ok = result[:goal_description].length.between?(150, 250)
        action_ok = result[:action_plan].split("\n").length.between?(3, 5)

        puts "  [#{title_ok ? '✓' : '✗'}] タイトルは20文字以内か？ (#{result[:goal_title].length}文字)"
        puts "  [#{desc_ok ? '✓' : '✗'}] 説明は150〜250文字程度か？ (#{result[:goal_description].length}文字)"
        puts "  [#{action_ok ? '✓' : '✗'}] アクションプランは3〜5ステップか？ (#{result[:action_plan].split("\n").length}ステップ)"
        puts '  [ ] 高校生でもわかる簡単な言葉か？'
        puts '  [ ] 配信者の状況に合った提案か？'
        puts '  [ ] 今日から始められる具体的な内容か？'
        puts '  [ ] 前向きで励ましの言葉になっているか？'
        puts ''
      rescue GeminiService::ApiError => e
        puts "⚠️  APIエラー: #{e.message}"
        puts ''
      rescue StandardError => e
        puts "⚠️  エラー: #{e.class} - #{e.message}"
        puts e.backtrace.first(3).join("\n")
        puts ''
      end

      puts ''
      sleep 2 # APIレート制限対策（念のため）
    end

    puts '=' * 80
    puts '検証完了'
    puts '=' * 80
  end

  desc '特定のプロフィールでAI提案を検証'
  task :verify_one, [:profile_id] => :environment do |_t, args|
    profile_id = args[:profile_id]

    unless profile_id
      puts '⚠️  エラー: プロフィールIDを指定してください'
      puts '  使用例: rails ai:verify_one[1]'
      exit
    end

    puts '=' * 80
    puts '特定プロフィールのAI提案検証'
    puts "プロフィールID: #{profile_id}"
    puts '=' * 80
    puts ''

    begin
      profile = SurveyProfile.includes(:streaming_experience, :survey_response, :streaming_platform,
                                       :streaming_category).find(profile_id)
      survey_response = profile.survey_response

      unless survey_response
        puts "⚠️  このプロフィール（ID: #{profile.id}）にはアンケート回答がありません"
        exit
      end

      # プロフィール情報を表示
      puts "\n■ 配信者情報:"
      puts "  - プラットフォーム: #{profile.streaming_platform&.name || '未設定'}"
      puts "  - カテゴリ: #{profile.streaming_category&.name || '未設定'}"
      puts "  - 配信経験: #{profile.streaming_experience&.name || '未設定'}"
      puts "  - 週の配信頻度: #{profile.weekly_frequency}回"
      puts "  - 平均視聴者数: #{profile.average_listeners}人"
      puts "  - 視聴者離脱率: #{profile.listener_dropout_rate}%"
      puts "  - モチベーションレベル: #{profile.motivation_level}/5"
      puts ''

      puts '■ アンケート回答:'
      puts "  - 配信で嬉しかった瞬間: #{survey_response.happy_moment&.truncate(50) || '未回答'}"
      puts "  - 配信で辛かった瞬間: #{survey_response.sad_moment&.truncate(50) || '未回答'}"
      puts "  - 配信を始めた理由: #{survey_response.streaming_reasons&.truncate(50) || '未回答'}"
      puts "  - 理想の配信スタイル: #{survey_response.desired_streaming_style&.truncate(50) || '未回答'}"
      puts ''

      # AI提案を生成
      puts '■ AI提案を生成中...'
      service = GeminiService.new
      start_time = Time.current

      result = service.suggest_streamer_goal(
        survey_profile: profile,
        survey_response: survey_response
      )

      elapsed_time = Time.current - start_time

      # 結果を表示
      puts "\n■ 生成された提案（生成時間: #{elapsed_time.round(2)}秒）:"
      puts ''
      puts '  【タイトル】'
      puts "  #{result[:goal_title]}"
      puts "  (文字数: #{result[:goal_title].length}文字)"
      puts ''
      puts '  【説明】'
      puts "  #{result[:goal_description]}"
      puts "  (文字数: #{result[:goal_description].length}文字)"
      puts ''
      puts '  【アクションプラン】'
      result[:action_plan].split("\n").each do |line|
        puts "  #{line}"
      end
      puts ''

      # 評価ポイントを表示
      puts '■ 評価チェックリスト:'
      title_ok = result[:goal_title].length <= 20
      desc_ok = result[:goal_description].length.between?(150, 250)
      action_ok = result[:action_plan].split("\n").length.between?(3, 5)

      puts "  [#{title_ok ? '✓' : '✗'}] タイトルは20文字以内か？ (#{result[:goal_title].length}文字)"
      puts "  [#{desc_ok ? '✓' : '✗'}] 説明は150〜250文字程度か？ (#{result[:goal_description].length}文字)"
      puts "  [#{action_ok ? '✓' : '✗'}] アクションプランは3〜5ステップか？ (#{result[:action_plan].split("\n").length}ステップ)"
      puts '  [ ] 高校生でもわかる簡単な言葉か？'
      puts '  [ ] 配信者の状況に合った提案か？'
      puts '  [ ] 今日から始められる具体的な内容か？'
      puts '  [ ] 前向きで励ましの言葉になっているか？'
      puts ''
    rescue ActiveRecord::RecordNotFound
      puts "⚠️  エラー: ID #{profile_id} のプロフィールが見つかりません"
    rescue GeminiService::ApiError => e
      puts "⚠️  APIエラー: #{e.message}"
    rescue StandardError => e
      puts "⚠️  エラー: #{e.class} - #{e.message}"
      puts e.backtrace.first(3).join("\n")
    end

    puts ''
    puts '=' * 80
    puts '検証完了'
    puts '=' * 80
  end

  desc 'プロンプトの比較検証（複数バージョンを試す）'
  task :compare_prompts, [:profile_id] => :environment do |_t, args|
    profile_id = args[:profile_id]

    unless profile_id
      puts '⚠️  エラー: プロフィールIDを指定してください'
      puts '  使用例: rails ai:compare_prompts[1]'
      exit
    end

    puts '=' * 80
    puts 'プロンプト比較検証'
    puts "プロフィールID: #{profile_id}"
    puts '=' * 80
    puts ''

    begin
      profile = SurveyProfile.includes(:streaming_experience, :survey_response, :streaming_platform,
                                       :streaming_category).find(profile_id)
      survey_response = profile.survey_response

      unless survey_response
        puts "⚠️  このプロフィール（ID: #{profile.id}）にはアンケート回答がありません"
        exit
      end

      # プロフィール情報を表示
      puts "\n■ 配信者情報:"
      puts "  - 配信経験: #{profile.streaming_experience&.name || '未設定'}"
      puts "  - モチベーションレベル: #{profile.motivation_level}/5"
      puts ''

      # 複数回実行して結果を比較
      results = []
      3.times do |i|
        puts "#{i + 1}回目の生成中..."
        service = GeminiService.new
        result = service.suggest_streamer_goal(
          survey_profile: profile,
          survey_response: survey_response
        )
        results << result
        sleep 2 # APIレート制限対策
      end

      # 結果を比較表示
      puts "\n■ 生成結果の比較:"
      puts ''

      results.each_with_index do |result, index|
        puts "【#{index + 1}回目】"
        puts "  タイトル: #{result[:goal_title]} (#{result[:goal_title].length}文字)"
        puts "  説明文字数: #{result[:goal_description].length}文字"
        puts "  アクションプラン行数: #{result[:action_plan].split("\n").length}行"
        puts ''
      end

      # タイトルの一致度を確認
      puts '■ タイトルの一致度:'
      if results[0][:goal_title] == results[1][:goal_title] && results[1][:goal_title] == results[2][:goal_title]
        puts '  ✓ 3回とも同じタイトルが生成されました（安定性: 高）'
      elsif results[0][:goal_title] == results[1][:goal_title] || results[1][:goal_title] == results[2][:goal_title] || results[0][:goal_title] == results[2][:goal_title]
        puts '  △ 2回は同じタイトルが生成されました（安定性: 中）'
      else
        puts '  ✗ 3回とも異なるタイトルが生成されました（安定性: 低）'
      end
      puts ''

      # 文字数のばらつきを確認
      title_lengths = results.map { |r| r[:goal_title].length }
      desc_lengths = results.map { |r| r[:goal_description].length }

      puts '■ 文字数のばらつき:'
      puts "  タイトル: #{title_lengths.min}〜#{title_lengths.max}文字（平均: #{title_lengths.sum / title_lengths.size}文字）"
      puts "  説明: #{desc_lengths.min}〜#{desc_lengths.max}文字（平均: #{desc_lengths.sum / desc_lengths.size}文字）"
      puts ''
    rescue ActiveRecord::RecordNotFound
      puts "⚠️  エラー: ID #{profile_id} のプロフィールが見つかりません"
    rescue GeminiService::ApiError => e
      puts "⚠️  APIエラー: #{e.message}"
    rescue StandardError => e
      puts "⚠️  エラー: #{e.class} - #{e.message}"
      puts e.backtrace.first(3).join("\n")
    end

    puts ''
    puts '=' * 80
    puts '検証完了'
    puts '=' * 80
  end
end
