require "test_helper"

class Owner::BookingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get owner_bookings_index_url
    assert_response :success
  end

  test "should get show" do
    get owner_bookings_show_url
    assert_response :success
  end

  test "should get accept" do
    get owner_bookings_accept_url
    assert_response :success
  end

  test "should get reject" do
    get owner_bookings_reject_url
    assert_response :success
  end

  test "should get complete" do
    get owner_bookings_complete_url
    assert_response :success
  end
end
