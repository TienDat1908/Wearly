module ApplicationHelper
  def locale_url(locale)
    url_for(
      request.path_parameters
        .merge(request.query_parameters)
        .merge(locale: locale, only_path: true)
    )
  end

  def booking_status_label(booking)
    t("bookings.statuses.#{booking.status}", default: booking.status.to_s.humanize)
  end

  def pickup_method_label(booking)
    t("bookings.#{booking.pickup_method}", default: booking.pickup_method.to_s.humanize)
  end

  def booking_location_label(booking)
    if booking.pickup_method == "delivery"
      t("bookings.delivery_address")
    else
      t("bookings.pickup_return_location")
    end
  end
end
