# frozen_string_literal: true

require "sidekiq/web"

# Dedicated Redis DB so other local apps (Twilio jobs on db/0, etc.) do not collide.
redis_url = ENV.fetch("SIDEKIQ_REDIS_URL") {
  ENV.fetch("REDIS_URL", "redis://localhost:6379/2")
}

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end

# Admin-only Sidekiq Web (avoids Devise route constraints → RoutingError).
class SidekiqAdminAuth
  def initialize(app)
    @app = app
  end

  def call(env)
    user = env["warden"]&.user
    return @app.call(env) if user&.respond_to?(:admin?) && user.admin?

    request = ActionDispatch::Request.new(env)
    locale = request.params[:locale].presence || I18n.default_locale
    location =
      if user
        "/#{locale}"
      else
        "/#{locale}/users/sign_in"
      end

    [302, { "Content-Type" => "text/html", "Location" => location }, ["Redirecting..."]]
  end
end

Sidekiq::Web.use SidekiqAdminAuth
