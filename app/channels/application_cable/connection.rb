# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      reject_unauthorized_connection unless current_user&.active?
    end

    private

    def find_verified_user
      user_from_warden || user_from_token
    end

    def user_from_warden
      env["warden"]&.user
    end

    def user_from_token
      token = request.params[:token].presence
      return if token.blank?

      User.find_signed(token, purpose: :mobile_auth)
    rescue ActiveSupport::MessageVerifier::InvalidSignature,
           ActiveSupport::MessageEncryptor::InvalidMessage,
           ArgumentError
      nil
    end
  end
end
