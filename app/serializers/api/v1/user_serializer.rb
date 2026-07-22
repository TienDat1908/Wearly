module Api
  module V1
    class UserSerializer
      include Rails.application.routes.url_helpers

      def initialize(user, request:, public_profile: false)
        @user = user
        @request = request
        @public_profile = public_profile
      end

      def as_json
        payload = {
          id: user.id,
          full_name: user.full_name,
          role: user.role,
          status: user.status,
          preferred_locale: user.preferred_locale,
          city: user.city,
          district: user.district,
          ward: user.ward,
          avatar_url: attachment_url(user.avatar),
          social_links: {
            facebook_url: user.facebook_url,
            instagram_url: user.instagram_url,
            tiktok_url: user.tiktok_url,
            zalo_url: user.zalo_url,
            website_url: user.website_url
          }.compact,
          created_at: user.created_at,
          updated_at: user.updated_at
        }

        return payload if public_profile

        payload.merge(
          email: user.email,
          phone: user.phone,
          address: user.address,
          payout_ready: user.bank_name.present? &&
            user.bank_account_name.present? &&
            user.bank_account_number.present?
        )
      end

      private

      attr_reader :user, :request
      attr_reader :public_profile

      def attachment_url(attachment)
        return unless attachment.attached?

        request.base_url + rails_blob_path(attachment, only_path: true)
      end
    end
  end
end
