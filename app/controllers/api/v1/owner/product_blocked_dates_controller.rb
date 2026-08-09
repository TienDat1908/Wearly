# frozen_string_literal: true

module Api
  module V1
    module Owner
      class ProductBlockedDatesController < BaseController
        before_action :set_product
        before_action :set_blocked_date, only: [:destroy]

        def index
          from, to = parse_window
          result = Products::BusyRanges.call(
            product: @product,
            from: from,
            to: to,
            include_booking_details: true
          )

          render json: {
            product_id: @product.id,
            from: result.from.iso8601,
            to: result.to.iso8601,
            busy: result.busy,
            blocked_dates: @product.product_blocked_dates.order(:start_on, :id).map { |block| serialize_block(block) }
          }
        rescue ArgumentError
          render json: { error: "Please choose a valid date range.", code: "invalid_date_range" }, status: :unprocessable_entity
        end

        def create
          block = @product.product_blocked_dates.new(blocked_date_params)

          if block.save
            render json: { blocked_date: serialize_block(block) }, status: :created
          else
            render json: {
              error: block.errors.full_messages.to_sentence,
              code: "invalid_block"
            }, status: :unprocessable_entity
          end
        end

        def destroy
          @blocked_date.destroy!
          head :no_content
        end

        private

        def set_product
          @product = current_api_user.products.find(params[:product_id])
        end

        def set_blocked_date
          @blocked_date = @product.product_blocked_dates.find(params[:id])
        end

        def blocked_date_params
          params.require(:blocked_date).permit(:start_on, :end_on, :note)
        end

        def serialize_block(block)
          {
            id: block.id,
            start_on: block.start_on.iso8601,
            end_on: block.end_on.iso8601,
            note: block.note
          }
        end

        def parse_window
          from = params[:from].present? ? Date.iso8601(params[:from]) : Date.current.beginning_of_month
          to = params[:to].present? ? Date.iso8601(params[:to]) : (from + 2.months).end_of_month
          raise ArgumentError if to < from || (to - from).to_i > 366

          [from, to]
        end
      end
    end
  end
end
