# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Capybara のテストサーバーへのリクエストを無視
  config.ignore_localhost = true

  # 特定のホストへのリクエストを無視（Capybara のテストサーバー）
  config.ignore_hosts '127.0.0.1', 'localhost', '172.18.0.4'

  # カセットが使われていない時はHTTP接続を許可
  config.allow_http_connections_when_no_cassette = true

  # APIキーをフィルタリング（録画時に実際のAPIキーを隠す）
  config.filter_sensitive_data('<GEMINI_API_KEY>') do
    Rails.application.credentials.dig(:gemini, :api_key)
  end

  # リクエストヘッダーからAPIキーを隠す
  config.before_record do |interaction|
    interaction.request.headers.delete('X-Goog-Api-Key')
  end

  # デフォルトのカセットオプション
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: %i[method uri body]
  }
end
