module Api
  module V1
    class HomeSpotlightSerializer
      include Rails.application.routes.url_helpers

      def initialize(home_spotlight, request:)
        @home_spotlight = home_spotlight
        @request = request
      end

      def as_json
        {
          id: home_spotlight.id,
          eyebrow: home_spotlight.eyebrow,
          title: home_spotlight.title,
          subtitle: home_spotlight.subtitle,
          active: home_spotlight.active?,
          position: home_spotlight.position,
          spin_frame_count: home_spotlight.spin_frame_count.to_i,
          spin_enabled: home_spotlight.spin_enabled?,
          image_urls: image_urls,
          runway_image_urls: runway_image_urls,
          created_at: home_spotlight.created_at&.iso8601,
          updated_at: home_spotlight.updated_at&.iso8601
        }
      end

      private

      attr_reader :home_spotlight, :request

      def image_urls
        urls_for(home_spotlight.display_images)
      end

      def runway_image_urls
        urls_for(home_spotlight.runway_images)
      end

      def urls_for(attachments)
        attachments.first(HomeSpotlight::MAX_IMAGES).map do |attachment|
          request.base_url + rails_blob_path(attachment, only_path: true)
        end
      end
    end
  end
end
