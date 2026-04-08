# frozen_string_literal: true

# CI環境用のドライバー設定
Capybara.register_driver :selenium_remote_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1400,1400')

  Capybara::Selenium::Driver.new(
    app,
    browser: :remote,
    url: ENV.fetch('SELENIUM_REMOTE_URL', nil),
    options: options
  )
end

# ローカル環境用のドライバー設定
Capybara.register_driver :remote_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1400,1400')

  Capybara::Selenium::Driver.new(
    app,
    browser: :remote,
    url: ENV.fetch('SELENIUM_DRIVER_URL', 'http://chrome:4444/wd/hub'),
    options: options
  )
end

# RSpecの設定
RSpec.configure do |config|
  config.before(:each, type: :system) do
    if ENV['SELENIUM_REMOTE_URL']
      # CI環境の設定
      driven_by :selenium_remote_chrome

      Capybara.server_host = '0.0.0.0'
      Capybara.server_port = 3001
      Capybara.app_host = "http://#{`hostname -i`.strip}:#{Capybara.server_port}"
    else
      # ローカル環境の設定
      driven_by :remote_chrome

      Capybara.server_host = IPSocket.getaddress(Socket.gethostname)
      Capybara.server_port = 3000
      Capybara.app_host = "http://#{Capybara.server_host}:#{Capybara.server_port}"
    end

    Capybara.ignore_hidden_elements = false
  end
end
