module Api
  module V1
    class ProductSerializer
      include Rails.application.routes.url_helpers

      def initialize(product, request:, detailed: false)
        @product = product
        @request = request
        @detailed = detailed
      end

      def as_json
        payload = {
          id: product.id,
          title: product.title,
          product_type: product.product_type,
          description: product.description,
          status: product.status,
          size: product.size,
          color: product.color,
          brand: product.brand,
          city: product.city,
          district: product.district,
          ward: product.ward,
          price_per_day: product.price_per_day.to_i,
          deposit_amount: product.deposit_amount.to_i,
          cleaning_fee: product.cleaning_fee.to_i,
          replacement_value: product.replacement_value.to_i,
          pickup_available: product.pickup_available? || product.pickup_location.present?,
          delivery_available: product.delivery_available?,
          available_pickup_methods: product.available_pickup_methods,
          pickup_location: product.pickup_location,
          primary_photo_attachment_id: product.cover_photo_attachment_id,
          primary_photo_url: attachment_url(product.cover_photo),
          photo_urls: photo_urls,
          owner: UserSerializer.new(product.owner, request: request, public_profile: true).as_json,
          created_at: product.created_at&.iso8601,
          updated_at: product.updated_at&.iso8601
        }

        payload[:details] = product.details || {} if @detailed
        payload
      end

      private

      attr_reader :product, :request

      def photo_urls
        @photo_urls ||= product.photo_gallery.map { |photo| attachment_url(photo) }
      end

      def attachment_url(attachment)
        return unless attachment

        request.base_url + rails_blob_path(attachment, only_path: true)
      end
    end
  end
end
