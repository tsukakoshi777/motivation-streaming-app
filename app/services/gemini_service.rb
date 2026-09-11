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
      options: {
        model: 'gemini-2.5-flash',
        server_sent_events: true,
        connection: {
          request: {
            timeout: 30,        # 読み込みタイムアウト（30秒）
            open_timeout: 10    # 接続タイムアウト（10秒）
          }
        }
      }
    )
  rescue KeyError => e
    Rails.logger.error "Gemini API key not found: #{e.message}"
    raise ApiError, 'GEMINI_API_KEY environment variable is not set'
  end

  # 【メインメソッド】配信者の目標提案を生成
  # survey_profile: 配信プロフィール(配信経験・頻度・視聴者数等)
  # survey_response: アンケート回答(嬉しかった瞬間・辛かった瞬間・配信理由等)
  # @return [Hash] { goal_title:, goal_description:, action_plan: }
  def suggest_streamer_goal(survey_profile:, survey_response:, job_id: nil)
    # モックを使う場合はモックレスポンスを返す
    return mock_goal_response(survey_profile, survey_response) if use_mock?

    prompt = build_goal_suggestion_prompt(survey_profile, survey_response)
    response_text = generate_text(prompt, job_id: job_id)

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

  def use_mock?
    # テスト環境では常にモックを使う
    return true if Rails.env.test?

    # 本番環境では常に API を使う
    return false if Rails.env.production?

    # 開発環境ではコメントアウトで切り替え
    # モックを使う場合はこちらを有効化
    # true

    # API を使う場合はこちらを有効化(上の行をコメントアウト)
    false
  end

  # キャンセルフラグをチェックするメソッド
  def cancelled?(job_id)
    Rails.cache.read("ai_suggestion_cancelled:#{job_id}").present?
  end

  # テキスト生成の共通メソッド
  def generate_text(prompt, job_id: nil)
    # ✅ API呼び出し前にキャンセルフラグをチェック
    if job_id.present? && cancelled?(job_id)
      Rails.logger.info "❌ API呼び出しをスキップしました: #{job_id}"
      raise ApiError, 'API呼び出しがキャンセルされました'
    end

    Rails.logger.info "✅ API呼び出しを開始します: #{job_id}"

    # リトライ処理を含むAPI呼び出し
    response_text = call_gemini_api_with_retry(prompt)

    Rails.logger.info "✅ API呼び出しが完了しました: #{job_id}"

    response_text
  end

  # リトライ処理を含むAPI呼び出し
  def call_gemini_api_with_retry(prompt, max_retries: 3)
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

  # 【プロンプト構築】目標提案用（わかりやすい言葉ver.）
  def build_goal_suggestion_prompt(survey_profile, survey_response)
    <<~PROMPT
       あなたは配信者の夢を応援する、優しいコーチです。
       配信者が「これならできそう！」と前向きになれる目標と、その目標を達成するために必要な具体的なアクションプランを提案してください。


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
      #{' '}
       配信者の経験年数、モチベーションレベル、配信を始めた理由を **重要視** して、以下の形式で提案してください。


       ### 1. 成長の星⭐のタイトル(20文字以内)
       短く、わかりやすく、やる気が出るタイトルをつけてください。


       ### 2. 目標の詳細説明(150〜250文字)
       - **なぜこの目標が今のあなたにぴったりなのか** を、配信者の経験年数とモチベーションレベルを踏まえて説明してください
       - **配信者の良いところを認めて、背中を押すような言葉で書いてください**
       - **配信者が今、強化・磨くべきポイントを、以下のわかりやすい単語を使って明示してください**：
         - **企画力**：配信の内容や企画を工夫する力
         - **ファン化**：視聴者をファンにする力
         - **集客力**：新しい視聴者を呼び込む力
         - **投げ銭施策**：投げ銭を増やすための工夫
         - **トーク力**：視聴者と楽しく会話する力
         - **継続力**：配信を楽しく続ける力
         - **宣伝力**：配信時間や内容、企画時間や内容を拡散や認知させる力
       - **説明文の最後に、「今、あなたに必要なのは〇〇を強化すること」「〇〇を磨くこと」「〇〇をもっと頑張ること」のように、具体的に伝えてください**
       - 達成するとどんな良いことがあるのか、 **具体的な数字や変化** を示してください
       - **必ず150〜250文字程度にしてください。**


       ### 3. 具体的なアクションプラン(4～6ステップ)
      #{' '}
       **配信者の経験年数に合わせた、今日からできる具体的な行動を足りてないスキルや言動を気づかせるように** を提案してください。
       **各ステップの冒頭に、「どこを強化・磨くのか」を明確に伝えてください。**
      #{' '}
       #### アクションプランのルール
       - **各ステップの冒頭に、「どこを強化・磨くのか」を【】で明記してください**
       - **プラットフォーム固有の機能の存在が不明確な場合は、どのプラットフォームでも実践できる汎用的な方法を提案してください**
       - **メモやノートに書き出す提案は、全体の1ステップ程度に留めてください**
       - **「輝きメモ」は、配信プラットフォーム（IRIAM、Spoonなど）の機能ではなく、このアプリ（推しスタ）独自の機能です**
       - **「輝きメモ」を使う際は、「このアプリの輝きメモ機能」「推しスタの輝きメモ機能」のように、必ず「このアプリ」または「推しスタ」を明記してください**
       - **例: 「このアプリ（推しスタ）の輝きメモ機能を使って、リスナーさんが教えてくれた好きな曲をメモしておこう」**
      #{' '}
       #### 説明文とアクションプランの繋がり
       - **説明文で触れた内容を、アクションプランで具体的に展開してください**
      #{' '}
       #### 初心者（配信経験1年未満）の場合
       - **本質的な課題**：配信を継続できるように楽しむこと
       - **提案の方向性**：
         - 配信を楽しむための具体的な方法を提案してください
         - 無理なく続けられる小さな目標を提案してください
         - 具体的なツール名や操作方法まで書いてください
       - **例**：
         - 「Canvaで『ゲーム実況 サムネイル』と検索し、人気のデザインを真似てサムネイルを作ってみよう」
         - 「配信開始時に『初めての人も、いつでもコメント大歓迎！』と声に出して伝えてみよう」
      #{' '}
       #### 中級者（配信経験1〜3年）の場合
       - **本質的な課題**：モチベーションが落ちないように頑張れる目的と応援してくれるファンの獲得
       - **提案の方向性**：
         - ファンとの絆を深める方法を提案してください
         - 配信を続ける目的や理由を再確認できる方法を提案してください
       - **例**：
         - 「過去1ヶ月の配信を振り返り、視聴者が増えた配信と減った配信の違いを3つ書き出してみよう」
       #### 上級者（配信経験3年以上）の場合
       - **本質的な課題**：過去との比較で落ち込みやすくなるので、総合視聴者数や平均視聴者数、投げ銭のサポートなど、成果を実感できる指標を意識する
       - **提案の方向性**：
         - ビジネス的な視点で提案してください
         - 過去との比較で落ち込まないように、前向きな視点で成果を振り返る方法を提案してください
         - 新しいファンを獲得するための戦略を提案してください
       - **例**：
         - 「過去3ヶ月の配信データを見て、一番視聴者が増えた配信の共通点を3つ見つけてみよう」
         - 「視聴者が減る時間帯を特定し、その時間にクイズやプレゼント企画を入れてみよう」
         - 「月1回、視聴者アンケートを実施して、配信内容の改善点を聞いてみよう」
      #{' '}
      #{' '}
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
       - **親しみやすく、前向きな言葉で語りかける**
       - **専門用語は絶対に使わない**（例：「CTR」「エンゲージメント」「コンバージョン」などは使わない）
       - 誰でも理解できる、日常会話で使う言葉を使う
       - 堅苦しい表現は避ける（例：「実施する」→「やってみる」、「活用する」→「使ってみる」）
       - 「〜しましょう」「〜してみよう」など、優しい言い方にする
       - 絵文字や「！」を適度に使って、明るい雰囲気にする
      ## 注意事項
       - **配信者の経験年数、モチベーションレベル、配信を続ける理由を重視してください**
       - 配信者の今の状況を考えて、無理のない目標を提案してください
       - 「視聴者数を増やす」「投げ銭を増やす」だけでなく、配信を楽しむことも大切にしてください
       - アクションプランは、 **具体的なツール名や操作方法まで書いてください**
       - 「〇〇を改善する」ではなく、「〇〇で△△を検索し、□□を試してみよう」のように、 **今日からできる行動** にしてください
       - **専門用語は絶対に使わないでください**（例：「CTR」「エンゲージメント」「リテンション」「コンバージョン」などは使わない）

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
