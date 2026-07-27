# frozen_string_literal: true

require "test_helper"

class ConversationsEnsureBookingTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(
      email: "owner-chat-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      full_name: "Owner Chat",
      phone: "09#{SecureRandom.random_number(10**8).to_s.rjust(8, '0')}",
      role: "owner",
      preferred_locale: "vi"
    )
    @renter = User.create!(
      email: "renter-chat-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      full_name: "Renter Chat",
      phone: "09#{SecureRandom.random_number(10**8).to_s.rjust(8, '0')}",
      role: "renter",
      preferred_locale: "vi"
    )
    @product = create_product("Váy dự tiệc")
    @booking = create_booking(@product)
  end

  test "creates conversation with system notice and unread for owner" do
    conversation = Conversations::EnsureBooking.call(booking: @booking)

    assert conversation.persisted?
    assert_equal Conversation.pair_key_for(@renter.id, @owner.id), conversation.pair_key
    assert_equal 1, conversation.messages.system_notices.count

    notice = conversation.messages.system_notices.first
    assert_equal @booking.id, notice.booking_id
    assert_includes notice.body, @product.title
    assert_includes notice.body, owner_booking_path(@booking, locale: "vi")

    assert_equal 1, conversation.unread_count_for(@owner)
    assert_equal 0, conversation.unread_count_for(@renter)
  end

  test "reuses one conversation for multiple bookings with same pair" do
    first = Conversations::EnsureBooking.call(booking: @booking)

    other_product = create_product("Áo khoác")
    other_booking = create_booking(other_product, start_offset: 10.days)

    second = Conversations::EnsureBooking.call(booking: other_booking)

    assert_equal first.id, second.id
    assert_equal 2, first.messages.system_notices.count
    assert_equal 1, Conversation.booking_kind.where(pair_key: first.pair_key).count
  end

  test "does not duplicate system notice for the same booking" do
    first = Conversations::EnsureBooking.call(booking: @booking)
    second = Conversations::EnsureBooking.call(booking: @booking)

    assert_equal first.id, second.id
    assert_equal 1, first.messages.system_notices.count
  end

  test "creates separate conversation for a different owner" do
    Conversations::EnsureBooking.call(booking: @booking)

    other_owner = User.create!(
      email: "owner2-chat-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      full_name: "Other Owner",
      phone: "09#{SecureRandom.random_number(10**8).to_s.rjust(8, '0')}",
      role: "owner",
      preferred_locale: "vi"
    )
    other_product = Product.create!(
      owner: other_owner,
      title: "Máy ảnh",
      product_type: "camera",
      price_per_day: 300_000,
      address: "Hanoi",
      city: "Hanoi",
      status: "active",
      pickup_available: true,
      pickup_location: "Dong Da",
      delivery_available: false
    )
    other_booking = create_booking(other_product, owner: other_owner, start_offset: 20.days)

    other_conversation = Conversations::EnsureBooking.call(booking: other_booking)

    assert_not_equal Conversation.pair_key_for(@renter.id, @owner.id), other_conversation.pair_key
    assert_equal 2, Conversation.booking_kind.count
  end

  private

  def create_product(title)
    Product.create!(
      owner: @owner,
      title: title,
      product_type: "dress",
      price_per_day: 200_000,
      address: "Hanoi",
      city: "Hanoi",
      status: "active",
      pickup_available: true,
      pickup_location: "Cau Giay",
      delivery_available: false
    )
  end

  def create_booking(product, owner: @owner, start_offset: 2.days)
    starts = start_offset.from_now.beginning_of_day
    Booking.create!(
      product: product,
      owner: owner,
      renter: @renter,
      status: "pending",
      start_time: starts,
      end_time: starts + 2.days,
      rental_days: 3,
      rental_amount: 600_000,
      cleaning_fee: 0,
      delivery_fee: 0,
      deposit_amount: 0,
      discount_amount: 0,
      platform_fee_rate: 0.1,
      platform_fee_amount: 60_000,
      renter_service_fee_amount: 0,
      owner_earning_amount: 540_000,
      total_amount: 660_000,
      pickup_method: "self_pickup",
      pickup_address: "Cau Giay",
      return_address: "Cau Giay"
    )
  end

  def owner_booking_path(booking, locale:)
    Rails.application.routes.url_helpers.owner_booking_path(booking, locale: locale)
  end
end
