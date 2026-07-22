class Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  safelist("allow local development") do |request|
    request.ip == "127.0.0.1" || request.ip == "::1"
  end

  throttle("requests/ip", limit: 300, period: 5.minutes) do |request|
    request.ip
  end

  throttle("auth/ip", limit: 20, period: 5.minutes) do |request|
    if request.post? && request.path.match?(%r{\A(/(en|vi))?/users/sign_in\z|\A/api/v1/auth/sign_in\z})
      request.ip
    end
  end

  throttle("auth/login", limit: 8, period: 5.minutes) do |request|
    next unless request.post? && request.path.match?(%r{\A(/(en|vi))?/users/sign_in\z|\A/api/v1/auth/sign_in\z})

    login =
      request.params.dig("user", "login").presence ||
      request.params.dig("user", "email").presence ||
      request.params.dig("user", "phone").presence

    login.to_s.downcase.strip.presence
  end

  throttle("signup/ip", limit: 10, period: 10.minutes) do |request|
    if request.post? && request.path.match?(%r{\A(/(en|vi))?/users\z|\A/api/v1/auth/sign_up\z})
      request.ip
    end
  end

  throttle("password-reset/ip", limit: 6, period: 15.minutes) do |request|
    if request.post? && request.path.match?(%r{\A(/(en|vi))?/users/password\z})
      request.ip
    end
  end

  throttle("omniauth/ip", limit: 30, period: 10.minutes) do |request|
    request.ip if request.path.start_with?("/users/auth/")
  end

  self.throttled_responder = lambda do |request|
    retry_after = (request.env["rack.attack.match_data"] || {})[:period]

    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [{ error: "Too many requests. Please try again later." }.to_json]
    ]
  end
end
