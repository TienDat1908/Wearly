Rails.application.config.action_dispatch.default_headers.merge!(
  "X-Content-Type-Options" => "nosniff",
  "X-Frame-Options" => "SAMEORIGIN",
  "Referrer-Policy" => "strict-origin-when-cross-origin",
  "X-Permitted-Cross-Domain-Policies" => "none"
)
