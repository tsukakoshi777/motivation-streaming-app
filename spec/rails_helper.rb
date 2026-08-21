# frozen_string_literal: true

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'

# WebMock を読み込む
require 'webmock/rspec'

# テスト環境で環境変数を設定
ENV['GEMINI_API_KEY'] = 'test_dummy_api_key_for_testing'

Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # 元の設定
  config.use_transactional_fixtures = true

  # FactoryBot の設定
  config.include FactoryBot::Syntax::Methods

  # ⭐ ActiveJob::TestHelper を追加
  config.include ActiveJob::TestHelper

  # ⭐ 各テストの前にキューをクリア
  config.before(:each) do
    clear_enqueued_jobs
  end

  # WebMock の設定
  # ローカルホストへのリクエストは許可(Capybara が使う)
  WebMock.disable_net_connect!(allow_localhost: true)

  # Sorcery のテストヘルパーを読み込む
  config.include Sorcery::TestHelpers::Rails::Controller, type: :controller
  config.include Sorcery::TestHelpers::Rails::Integration, type: :request

  # OmniAuth のテストモードを有効化
  config.before(:each, type: :request) do
    OmniAuth.config.test_mode = true
  end

  # テスト後にモックをクリア
  config.after(:each, type: :request) do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google] = nil
    Rails.application.env_config['omniauth.auth'] = nil
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
