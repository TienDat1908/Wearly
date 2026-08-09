require "test_helper"

class Api::V1::HomeSpotlightSerializerTest < ActiveSupport::TestCase
  test "includes spin fields and runway image urls" do
    spotlight = HomeSpotlight.create!(
      eyebrow: "Tonight",
      title: "Ready",
      active: true,
      position: 1,
      spin_frame_count: 5
    )
    spotlight.images.attach(
      io: StringIO.new("fake"),
      filename: "look-a.png",
      content_type: "image/png"
    )

    request = ActionDispatch::TestRequest.create
    json = Api::V1::HomeSpotlightSerializer.new(spotlight, request: request).as_json

    assert_equal 5, json[:spin_frame_count]
    assert json[:spin_enabled]
    assert_equal 1, json[:runway_image_urls].size
    assert_equal json[:image_urls], json[:runway_image_urls]
  end
end
