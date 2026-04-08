# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, type: :system) do
    if ENV['SELENIUM_REMOTE_URL']
      # CI環境の場合
      driven_by :selenium_chrome_headless
    else
      # ローカル環境の場合
      driven_by :remote_chrome
      Capybara.server_host = IPSocket.getaddress(Socket.gethostname)
      Capybara.server_port = 4444
      Capybara.app_host = "http://#{Capybara.server_host}:#{Capybara.server_port}"
      Capybara.ignore_hidden_elements = false
    end
  end
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
    url: 'http://chrome:4444/wd/hub',
    options: options
  )
end

# CI環境用のドライバー設定
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1400,1400')

  if ENV['SELENIUM_REMOTE_URL']
    Capybara::Selenium::Driver.new(
      app,
      browser: :remote,
      url: ENV['SELENIUM_REMOTE_URL'],
      options: options
    )
  else
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end
end

Capybara.javascript_driver = :selenium_chrome_headless
