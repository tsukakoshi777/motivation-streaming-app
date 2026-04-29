# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 7.0.3', '>= 7.0.3.1'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'

# Use mysql as the database for Active Record
gem 'pg'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 5.0'

# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem 'jsbundling-rails'

# CSS のバンドリング（Bootstrap を使うため）
gem 'cssbundling-rails'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'

# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Use Sass to process CSS
gem 'dartsass-rails', '~> 0.4.0'

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

gem 'sorcery', '0.16.3'

gem 'rails-i18n', '~> 7.0.0'

gem 'draper', '4.0.2'

# 画像アップロード機能
gem 'carrierwave', '2.2.2'
gem 'fog-aws' # 本番環境でS3を使用するため
gem 'mini_magick' # 画像のリサイズ用

# AWS S3連携（本番環境で使用）
gem 'aws-sdk-s3', require: false

# 環境変数管理（本番環境で .env ファイルを読み込むため）
gem 'dotenv-rails', groups: %i[development production]

gem 'turbo-rails', '1.1.1'

# OGP設定用のGem
gem 'meta-tags'

# ページネーション関連のGem
gem 'bootstrap5-kaminari-views'
gem 'kaminari', '1.2.2'

# Gemini AI
gem 'gemini-ai'

# Gemini AI分析結果の表示用
gem 'redcarpet'
gem 'sanitize'

# SNSログイン（Google）
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'pry-byebug'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  gem 'rubocop'
  gem 'rubocop-checkstyle_formatter'
  gem 'rubocop-rails'
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  # ERB ファイルの自動整形用
  gem 'htmlbeautifier'

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers', '~> 5.0'
  gem 'vcr'
  gem 'webmock'
end
