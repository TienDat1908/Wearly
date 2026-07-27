# frozen_string_literal: true

# Temporary hardcoded support contacts — replace with real values later.
module WearlySupport
  EMAIL = ENV.fetch("WEARLY_SUPPORT_EMAIL", "support@wearly.io")
  PHONE = ENV.fetch("WEARLY_SUPPORT_PHONE", "+84 900 000 000")
  PHONE_TEL = ENV.fetch("WEARLY_SUPPORT_PHONE_TEL", "+84900000000")
end
