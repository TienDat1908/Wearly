require "test_helper"

class HomeSpotlightTest < ActiveSupport::TestCase
  MINI_PNG = Base64.decode64(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
  ).freeze

  test "runway_images uses uploaded looks in order" do
    spotlight = HomeSpotlight.create!(eyebrow: "Tonight", title: "Ready", active: true, position: 1, spin_frame_count: 1)
    attach_look(spotlight, "look-a.png")
    attach_look(spotlight, "look-b.png")

    assert_equal 2, spotlight.runway_images.size
    assert_equal %w[look-a.png look-b.png], spotlight.runway_images.map { |image| image.filename.to_s }
  end

  test "spin_enabled when look images exist and frames >= 2" do
    spotlight = HomeSpotlight.create!(eyebrow: "Tonight", title: "Ready", active: true, position: 1, spin_frame_count: 1)
    attach_look(spotlight, "look-a.png")
    assert_not spotlight.spin_enabled?

    spotlight.update!(spin_frame_count: 5)
    assert spotlight.spin_enabled?
    assert_equal "look-a.png", spotlight.spin_source_attachment.filename.to_s
  end

  test "rejects more than five images" do
    spotlight = HomeSpotlight.new(eyebrow: "Tonight", title: "Ready", active: true, position: 1, spin_frame_count: 1)
    6.times { |index| attach_look(spotlight, "look-#{index}.png") }

    assert_not spotlight.valid?
    assert_includes spotlight.errors[:images], "must be 5 images or fewer"
  end

  private

  def attach_look(spotlight, filename)
    spotlight.images.attach(
      io: StringIO.new(MINI_PNG),
      filename: filename,
      content_type: "image/png"
    )
  end
end
