# frozen_string_literal: true

# GeminiServiceクラス
# Gemini APIとの連携を担当するサービスクラス
# 配信者特化のAI分析・目標提案・アクションプラン生成を行う
class GeminiService
  # カスタムエラークラスの定義
  class ApiError < StandardError; end
  class RateLimitError < StandardError; end
  class InvalidResponseError < StandardError; end

  def initialize
    # モックを使う場合はクライアントの初期化をスキップ
    return if use_mock?

    @client = Gemini.new(
      credentials: {
        service: 'generative-language-api',
        api_key: ENV.fetch('GEMINI_API_KEY')
      },
      options: { model: 'gemini-2.5-flash', server_sent_events: true }
    )
  rescue KeyError => e
    Rails.logger.error "Gemini API key not found: #{e.message}"
    raise ApiError, 'GEMINI_API_KEY environment variable is not set'
  end

  # 【メインメソッド】配信者の目標提案を生成
  # survey_profile: 配信プロフィール(配信経験・頻度・視聴者数等)
  # survey_response: アンケート回答(嬉しかった瞬間・辛かった瞬間・配信理由等)
  # @return [Hash] { goal_title:, goal_description:, action_plan: }
  def suggest_streamer_goal(survey_profile:, survey_response:)
    # モックを使う場合はモックレスポンスを返す
    return mock_goal_response(survey_profile, survey_response) if use_mock?

    prompt = build_goal_suggestion_prompt(survey_profile, survey_response)
    response_text = generate_text(prompt)

    parse_goal_response(response_text)
  rescue StandardError => e
    Rails.logger.error "Goal suggestion failed: #{e.message}"
    raise ApiError, "目標提案の生成に失敗しました: #{e.message}"
  end

  # 【サブメソッド】配信改善提案を生成
  # survey_profile: 配信プロフィール
  # survey_response: アンケート回答
  # @return [String] 改善提案のテキスト
  def suggest_improvement(survey_profile:, survey_response:)
    # モックを使う場合はモックレスポンスを返す
    return mock_improvement_response(survey_profile, survey_response) if use_mock?

    prompt = build_improvement_prompt(survey_profile, survey_response)
    generate_text(prompt)
  rescue StandardError => e
    Rails.logger.error "Improvement suggestion failed: #{e.message}"
    raise ApiError, "改善提案の生成に失敗しました: #{e.message}"
  end

  # 【サブメソッド】成長の星⭐輝き(spark)からモチベーション分析
  # goal: 目標オブジェクト
  # sparks: 過去の記録(成長の星⭐輝き)の配列
  # @return [String] モチベーション分析結果
  def analyze_spark_progress(goal:, sparks:)
    # モックを使う場合はモックレスポンスを返す
    return mock_spark_analysis_response(goal, sparks) if use_mock?

    prompt = build_spark_analysis_prompt(goal, sparks)
    generate_text(prompt)
  rescue StandardError => e
    Rails.logger.error "Spark analysis failed: #{e.message}"
    raise ApiError, "成長分析に失敗しました: #{e.message}"
  end

  private

  # モックを使うかどうかの判定メソッド
  # 開発環境では常にモックを使う設定
  def use_mock?
    # モックを使う場合
    # true

    # API を使う場合
    false

    # 環境に応じて自動切り替え
    # Rails.env.development?
  end

  # テキスト生成の共通メソッド
  def generate_text(prompt)
    max_retries = 3
    retry_count = 0

    begin
      result = @client.stream_generate_content(
        { contents: { role: 'user', parts: { text: prompt } } }
      )

      response_text = extract_text_from_result(result)

      if response_text.blank?
        Rails.logger.error 'Gemini API returned empty response'
        raise InvalidResponseError, 'Empty response from Gemini API'
      end

      response_text
    rescue Faraday::TooManyRequestsError => e
      Rails.logger.error "Gemini API rate limit exceeded: #{e.message}"
      raise RateLimitError, 'API rate limit exceeded. Please try again later.'
    rescue StandardError => e
      retry_count += 1
      if retry_count <= max_retries
        Rails.logger.warn "Gemini API error (retry #{retry_count}/#{max_retries}): #{e.message}"
        sleep(2**retry_count) # 指数バックオフ(2秒、4秒、8秒)
        retry
      else
        Rails.logger.error "Gemini API error after #{max_retries} retries: #{e.message}"
        raise ApiError, "Failed to generate text: #{e.message}"
      end
    end
  end

  # レスポンスからテキストを抽出
  def extract_text_from_result(result)
    result.map do |event|
      event.dig('candidates', 0, 'content', 'parts', 0, 'text')
    end.compact.join
  end

  # モックレスポンス：目標提案用
  def mock_goal_response(survey_profile, _survey_response)
    # 配信経験に応じてモックを変える
    case survey_profile.streaming_experience&.name
    when '初心者(1ヶ月未満)'
      {
        goal_title: '配信を習慣化しよう！',
        goal_description: 'まずは配信を習慣化することから始めましょう。無理のないペースで続けることが大切です。あなたの配信には価値があります！',
        action_plan: "◇ 週1回の配信を目指そう\n◇ 配信時間を固定してみよう\n◇ 配信前の準備をルーティン化しよう\n◇ 配信後に振り返りメモを書こう\n◇ 小さな成功を記録していこう"
      }
    when '経験者(1ヶ月〜1年)'
      {
        goal_title: '視聴者との絆を深めよう！',
        goal_description: '配信を続けてこられたあなたは素晴らしいです！次は視聴者との絆をさらに深めていきましょう。',
        action_plan: "◇ 常連視聴者の名前を覚えよう\n◇ コメントに積極的に返信しよう\n◇ 視聴者参加型の企画を考えよう\n◇ SNSで視聴者と交流しよう\n◇ コミュニティを作ってみよう"
      }
    when '中級者(1年以上)', '上級者(3年以上)', 'ベテラン(5年以上)'
      {
        goal_title: '配信の質を高めよう！',
        goal_description: '経験を積んできたあなたなら、次のステップに進めます。配信の質を高めることに挑戦しましょう！',
        action_plan: "◇ 配信テーマを事前に決めよう\n◇ サムネイルを工夫しよう\n◇ 配信の振り返りを定期的にしよう\n◇ 新しい企画に挑戦しよう\n◇ 他の配信者とコラボしてみよう"
      }
    else
      {
        goal_title: '配信を楽しもう！',
        goal_description: 'まずは配信を楽しむことから始めましょう。',
        action_plan: "◇ 配信を続けること\n◇ 視聴者とのコミュニケーションを大切にすること\n◇ 自分らしい配信スタイルを見つけること"
      }
    end
  end

  # 【プロンプト構築】目標提案用
  # 【プロンプト構築】目標提案用（わかりやすい言葉ver.）
  def build_goal_suggestion_prompt(survey_profile, survey_response)
    <<~PROMPT
      あなたは配信者の夢を応援する、優しいコーチです。
      配信者が「これならできそう！」と前向きになれる目標を提案してください。


      ## 配信者の基本情報
      - 配信プラットフォーム: #{survey_profile.streaming_platform&.name}
      - 配信カテゴリ: #{survey_profile.streaming_category&.name}
      - 配信経験: #{survey_profile.streaming_experience&.name}
      - 週の配信頻度: #{survey_profile.weekly_frequency}回
      - 平均視聴者数: #{survey_profile.average_listeners}人
      - 視聴者離脱率: #{survey_profile.listener_dropout_rate}%
      - 現在のモチベーションレベル: #{survey_profile.motivation_level}/5


      ## アンケート回答
      - 配信で嬉しかった瞬間: #{survey_response.happy_moment}
      - 配信で辛かった瞬間: #{survey_response.sad_moment}
      - 配信を始めた理由: #{survey_response.streaming_reasons}
      - 理想の配信スタイル: #{survey_response.desired_streaming_style}
      - 理想の視聴者層: #{survey_response.desired_listener}
      - 理想の月収: #{format_income(survey_response.desired_monthly_income)}


      ## 提案してほしい内容
      以下の形式で、配信者に最適な目標を提案してください。


      ### 1. 成長の星⭐のタイトル(20文字以内)
      短く、わかりやすく、やる気が出るタイトルをつけてください。


      ### 2. 目標の詳細説明(200文字程度)
      **高校生でもわかる簡単な言葉で** 説明してください。
      - なぜこの目標が今のあなたにぴったりなのか
      - 達成するとどんな良いことがあるのか
      - 配信者の良いところを認めて、背中を押すような言葉で


      ### 3. 具体的なアクションプラン(3〜5ステップ)
      **高校生でもわかる簡単な言葉で、今日からできる行動** を提案してください。
      - 難しい専門用語は使わない
      - 「〇〇しよう」「〇〇してみよう」など、優しい言い方で
      - 具体的で、すぐに行動に移せる内容にする


      ## 出力形式
      以下のJSON形式で出力してください:
      ```json
      {
        "goal_title": "目標タイトル",
        "goal_description": "目標の詳細説明",
        "action_plan": "1. ステップ1\\n2. ステップ2\\n3. ステップ3\\n4. ステップ4\\n5. ステップ5"
      }
      ```


      ## 話し方のルール（重要！）
      - **高校生でもわかる簡単な言葉を使う**
      - 難しい専門用語は避ける（例：「コミュニティ」→「仲間」、「エンゲージメント」→「つながり」）
      - 堅苦しい表現は避ける（例：「実施する」→「やってみる」、「活用する」→「使ってみる」）
      - 親しみやすく、前向きな言葉で語りかける
      - 「〜しましょう」「〜してみよう」など、優しい言い方にする
      - 絵文字や「！」を適度に使って、明るい雰囲気にする


      ## 注意事項
      - 配信者の今の状況を考えて、無理のない目標を提案してください
      - 「視聴者数を増やす」だけでなく、配信を楽しむことも大切にしてください
      - アクションプランは、今日から始められる簡単なことにしてください
    PROMPT
  end

  # モックレスポンス：改善提案用
  def mock_improvement_response(survey_profile, survey_response)
    <<~TEXT
      ## 現状の課題分析

      あなたの配信プロフィールを分析した結果、以下の課題が見えてきました。

      - 配信頻度: 週#{survey_profile.weekly_frequency}回
      - 平均視聴者数: #{survey_profile.average_listeners}人
      - 視聴者離脱率: #{survey_profile.listener_dropout_rate}%
      - モチベーションレベル: #{survey_profile.motivation_level}/5

      ## 改善のための具体的な施策

      ### 1. 視聴者離脱率を下げる工夫
      配信の冒頭で「今日の配信内容」を伝えることで、視聴者が最後まで見たくなる流れを作りましょう。

      ### 2. 配信頻度の最適化
      無理のないペースで続けることが大切です。週#{survey_profile.weekly_frequency}回の配信を継続しながら、配信時間を固定してみましょう。

      ### 3. 視聴者とのコミュニケーション強化
      コメントに積極的に返信することで、視聴者との絆が深まります。

      ## あなたの強みを活かした差別化ポイント

      #{survey_response.happy_moment} という経験から、あなたには視聴者を楽しませる力があります。
      この強みを活かして、#{survey_response.desired_streaming_style} という理想の配信スタイルを目指しましょう！
    TEXT
  end

  # 【プロンプト構築】改善提案用
  def build_improvement_prompt(survey_profile, survey_response)
    <<~PROMPT
      あなたは配信者専門のアドバイザーです。
      以下の情報をもとに、この配信者が抱える課題を分析し、改善提案をしてください。

      ## 配信者の基本情報
      - 配信プラットフォーム: #{survey_profile.streaming_platform&.name}
      - 配信カテゴリ: #{survey_profile.streaming_category&.name}
      - 配信経験: #{survey_profile.streaming_experience&.name}
      - 週の配信頻度: #{survey_profile.weekly_frequency}回
      - 平均視聴者数: #{survey_profile.average_listeners}人
      - 視聴者離脱率: #{survey_profile.listener_dropout_rate}%
      - 現在のモチベーションレベル: #{survey_profile.motivation_level}/5

      ## アンケート回答
      - 配信で嬉しかった瞬間: #{survey_response.happy_moment}
      - 配信で辛かった瞬間: #{survey_response.sad_moment}
      - 配信を始めた理由: #{survey_response.streaming_reasons}
      - 理想の配信スタイル: #{survey_response.desired_streaming_style}
      - 理想の視聴者層: #{survey_response.desired_listener}

      ## 提案してほしい内容
      1. 現状の課題分析(視聴者離脱率やモチベーションの低下など)
      2. 改善のための具体的な施策(3つ程度)
      3. 配信者の強みを活かした差別化ポイント

      配信者が前向きに取り組める内容で、実践的なアドバイスをしてください。
    PROMPT
  end

  # モックレスポンス：成長分析用
  def mock_spark_analysis_response(goal, sparks)
    spark_count = sparks.count

    <<~TEXT
      ## これまでの成長のポイント

      #{goal.survey_result.goal_title} という目標に向かって、これまで #{spark_count} 回の記録を残してきましたね！素晴らしいです 🎉

      あなたの記録を見ていると、少しずつ前に進んでいることがわかります。
      特に最近の記録からは、配信への前向きな気持ちが伝わってきます。

      ## 目標達成に向けた進捗状況

      現在の進捗率: #{[spark_count * 20, 100].min}%

      #{spark_count >= 5 ? '目標達成まであと一歩です！' : 'まだまだこれからです。焦らず一歩ずつ進んでいきましょう。'}

      ## 次に取り組むべきアクション

      1. これまでの記録を振り返って、自分の成長を実感しましょう
      2. 次の小さな目標を設定してみましょう
      3. 配信を楽しむことを忘れずに！

      ## あなたへのエール

      配信を続けてきたあなたは本当に素晴らしいです！
      どんなに小さな一歩でも、それは確実に成長につながっています。
      あなたの配信には価値があります。自信を持って、これからも楽しく配信を続けてください 🌟
    TEXT
  end

  # 【プロンプト構築】成長分析用(sparks)
  def build_spark_analysis_prompt(goal, sparks)
    spark_contents = sparks.map.with_index(1) do |spark, index|
      "#{index}. #{spark.content} (#{spark.created_at.strftime('%Y/%m/%d')})"
    end.join("\n")

    <<~PROMPT
      あなたは配信者専門のモチベーションコーチです。
      以下の情報をもとに、この配信者の成長を分析し、励ましのメッセージを送ってください。

      ## 目標
      #{goal.survey_result.goal_title}

      ## これまでの記録(成長の星⭐輝き)
      #{spark_contents}

      ## 分析してほしい内容
      1. これまでの記録から見える成長のポイント
      2. 目標達成に向けた進捗状況
      3. 次に取り組むべきアクション
      4. 配信者へのエールと励ましのメッセージ

      配信者が「続けてきて良かった」「これからも頑張ろう」「自分の配信には価値がある」と思える内容にしてください。
    PROMPT
  end

  # 【ヘルパーメソッド】月収をフォーマット
  def format_income(income)
    return '設定なし' if income.blank?

    "#{income.to_fs(:delimited)}円"
  end

  # 【パースメソッド】JSON形式のレスポンスをパース
  def parse_goal_response(response_text)
    # JSONブロックを抽出(```json ... ```の形式に対応)
    json_match = response_text.match(/```json\s*(\{.*?\})\s*```/m)
    json_text = json_match ? json_match[1] : response_text

    begin
      parsed = JSON.parse(json_text)
      {
        goal_title: parsed['goal_title'],
        goal_description: parsed['goal_description'],
        action_plan: parsed['action_plan']
      }
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse JSON response: #{e.message}"
      Rails.logger.error "Response text: #{response_text}"

      # JSONパースに失敗した場合はデフォルト値を返す
      {
        goal_title: '目標を設定しましょう',
        goal_description: 'AIによる目標提案の生成に失敗しました。手動で目標を設定してください。',
        action_plan: '1. まずは配信を続けること\n2. 視聴者とのコミュニケーションを大切にすること\n3. 自分らしい配信スタイルを見つけること'
      }
    end
  end
end
