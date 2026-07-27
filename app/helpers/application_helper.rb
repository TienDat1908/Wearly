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

  def conversation_title(conversation, viewer:)
    if conversation.support?
      return t("conversations.support_title")
    end

    conversation.other_participant_for(viewer)&.full_name.presence ||
      conversation.subject.presence ||
      t("conversations.booking_chat")
  end

  def conversation_booking_path_for(conversation, viewer:, booking: nil)
    booking ||=
      if conversation.respond_to?(:latest_related_booking)
        conversation.latest_related_booking
      end
    return if booking.blank? || viewer.blank?
    return unless [booking.renter_id, booking.owner_id].include?(viewer.id)

    if viewer.id == booking.owner_id
      owner_booking_path(booking)
    else
      booking_path(booking)
    end
  end

  def booking_chat_button(booking, viewer:, **html_options)
    return unless booking.chattable?
    return unless viewer
    return unless [booking.renter_id, booking.owner_id].include?(viewer.id)

    path =
      if viewer.id == booking.owner_id
        chat_owner_booking_path(booking)
      else
        chat_booking_path(booking)
      end

    label =
      if viewer.id == booking.owner_id
        t("conversations.chat_with_renter")
      else
        t("conversations.chat_with_owner")
      end

    defaults = {
      method: :post,
      class: "px-5 py-3 rounded-full bg-pink-500 text-white font-black text-center"
    }

    button_to label, path, defaults.merge(html_options)
  end

  # role: :renter | :owner — copy differs slightly for each side.
  def acceptance_countdown_badge(booking, role: :renter)
    return unless booking.pending?

    prefix =
      if role.to_sym == :owner
        t("bookings.acceptance_remaining_owner")
      else
        t("bookings.acceptance_remaining_renter")
      end

    tag.div(
      class: "acceptance-countdown inline-flex flex-wrap items-center gap-2 rounded-full bg-amber-50 text-amber-800 px-3 py-1.5 text-xs font-black",
      data: {
        controller: "acceptance-countdown",
        acceptance_countdown_deadline_value: booking.acceptance_deadline.iso8601,
        acceptance_countdown_expired_value: t("bookings.acceptance_countdown_expired"),
        acceptance_countdown_hours_label_value: t("bookings.countdown_hours_short"),
        acceptance_countdown_minutes_label_value: t("bookings.countdown_minutes_short"),
        acceptance_countdown_seconds_label_value: t("bookings.countdown_seconds_short")
      }
    ) do
      safe_join(
        [
          tag.span("⏱"),
          tag.span(prefix),
          tag.span(
            t("bookings.acceptance_countdown_loading"),
            class: "tabular-nums",
            data: { acceptance_countdown_target: "display" }
          )
        ],
        " "
      )
    end
  end
end
