require "omniauth"

# Set OMNIAUTH_FULL_HOST when an OAuth provider needs callback URLs generated
# from a public host instead of the current request host.
OmniAuth.config.full_host = ENV["OMNIAUTH_FULL_HOST"] if ENV["OMNIAUTH_FULL_HOST"].present?
