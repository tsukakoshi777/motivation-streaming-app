# frozen_string_literal: true

module LoginHelper
  def login_as(user)
    #  user_session の中に email と password を入れる
    post login_path, params: {
      user_session: {
        email: user.email,
        password: 'password'
      }
    }

    #  リダイレクトの確認
    expect(response).to have_http_status(:redirect),
                        "ログインに失敗しました。Status: #{response.status}"

    follow_redirect!
  end
end

RSpec.configure do |config|
  config.include LoginHelper, type: :request
end
