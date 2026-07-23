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
          image_urls: image_urls,
          created_at: home_spotlight.created_at&.iso8601,
          updated_at: home_spotlight.updated_at&.iso8601
        }
      end

      private

      attr_reader :home_spotlight, :request

      def image_urls
        home_spotlight.display_images.first(HomeSpotlight::MAX_IMAGES).map do |attachment|
          request.base_url + rails_blob_path(attachment, only_path: true)
        end
      end
    end
  end
end
