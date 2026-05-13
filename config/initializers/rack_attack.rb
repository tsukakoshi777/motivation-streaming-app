class Rack::Attack

  Rack::Attack.enabled = !Rails.env.test?
  
  # Redis をキャッシュストアとして使用
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
    url: ENV.fetch('REDIS_URL', 'redis://redis:6379/1')
  )

  # 1. オートコンプリート API のレート制限
  # ユーザーごとに 1分間に 30回 まで
  throttle('autocomplete/user', limit: 30, period: 1.minute) do |req|
    if req.path == '/goals/autocomplete' && req.get?
      req.session['user_id'] || req.ip
    end
  end

  # 2. 検索実行のレート制限
  # ユーザーごとに 1分間に 10回 まで
  throttle('search/user', limit: 10, period: 1.minute) do |req|
    if req.path == '/goals' && req.get? && req.params['q'].present?
      req.session['user_id'] || req.ip
    end
  end

  # 3. 全体的な IP ごとのレート制限
  # 同じ IP から 1分間に 100回 まで
  throttle('req/ip', limit: 100, period: 1.minute) do |req|
    req.ip
  end

  # レート制限に引っかかった場合のレスポンス
  self.throttled_responder = lambda do |request|
    match_data = request.env['rack.attack.match_data'] || {}
    retry_after = match_data[:period].to_i
    [
      429,
      { 'Content-Type' => 'application/json', 'Retry-After' => retry_after.to_s },
      [{ error: 'Too Many Requests' }.to_json]
    ]
  end
end