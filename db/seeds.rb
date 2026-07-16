puts "Cleaning database..."

if Rails.env.development?
  [
    Review,
    Dispute,
    ProductConditionReport,
    PromotionRedemption,
    Promotion,
    Payout,
    Payment,
    ProductReservation,
    Booking,
    Product,
    User
  ].each do |model|
    model.destroy_all if defined?(model)
  end
end

puts "Creating seed images..."

seed_image_dir = Rails.root.join("tmp", "seed_images")
FileUtils.mkdir_p(seed_image_dir)

def create_seed_svg(path, title, subtitle, emoji, gradient_from, gradient_to)
  svg = <<~SVG
    <svg width="900" height="1200" viewBox="0 0 900 1200" fill="none" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="bg" x1="0" y1="0" x2="900" y2="1200" gradientUnits="userSpaceOnUse">
          <stop stop-color="#{gradient_from}"/>
          <stop offset="1" stop-color="#{gradient_to}"/>
        </linearGradient>
      </defs>

      <rect width="900" height="1200" rx="72" fill="url(#bg)"/>
      <circle cx="760" cy="140" r="180" fill="white" fill-opacity="0.18"/>
      <circle cx="120" cy="1040" r="220" fill="white" fill-opacity="0.14"/>

      <rect x="80" y="80" width="740" height="1040" rx="56" fill="white" fill-opacity="0.22"/>
      <text x="450" y="455" text-anchor="middle" font-size="180">#{emoji}</text>

      <text x="450" y="625" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="52" font-weight="900" fill="white">
        #{title}
      </text>

      <text x="450" y="700" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="30" font-weight="700" fill="white" fill-opacity="0.9">
        #{subtitle}
      </text>

      <rect x="270" y="775" width="360" height="82" rx="41" fill="white" fill-opacity="0.92"/>
      <text x="450" y="828" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="28" font-weight="900" fill="#111827">
        Wearly
      </text>
    </svg>
  SVG

  File.write(path, svg)
end

def attach_seed_photo(product, index, emoji)
  colors = [
    ["#ec4899", "#fb923c"],
    ["#8b5cf6", "#ec4899"],
    ["#06b6d4", "#3b82f6"],
    ["#f97316", "#facc15"],
    ["#10b981", "#14b8a6"]
  ]

  gradient_from, gradient_to = colors[index % colors.length]
  safe_title = product.title.parameterize
  path = Rails.root.join("tmp", "seed_images", "#{safe_title}-#{index}.svg")

  create_seed_svg(
    path,
    product.title.truncate(22),
    product.product_type.to_s.humanize,
    emoji,
    gradient_from,
    gradient_to
  )

  File.open(path) do |file|
    product.photos.attach(
      io: file,
      filename: "#{safe_title}-#{index}.svg",
      content_type: "image/svg+xml"
    )
  end
end

puts "Creating users..."

admin = User.create!(
  full_name: "Wearly Admin",
  email: "admin@wearly.app",
  phone: "0900000000",
  password: "Admin@123",
  password_confirmation: "Admin@123",
  role: "admin",
  status: "active",
  preferred_locale: "en",
  city: "Ho Chi Minh City",
  district: "District 1",
  ward: "Ben Nghe",
  address: "Wearly Head Office"
)

owners = [
  {
    full_name: "Olivia Nguyen",
    email: "olivia.owner@wearly.app",
    phone: "0900000001",
    city: "Ho Chi Minh City",
    district: "District 1",
    address: "Le Loi Street"
  },
  {
    full_name: "Emma Tran",
    email: "emma.owner@wearly.app",
    phone: "0900000002",
    city: "Ho Chi Minh City",
    district: "District 3",
    address: "Vo Van Tan Street"
  },
  {
    full_name: "Sophia Le",
    email: "sophia.owner@wearly.app",
    phone: "0900000003",
    city: "Da Nang",
    district: "Hai Chau",
    address: "Bach Dang Street"
  },
  {
    full_name: "Mia Pham",
    email: "mia.owner@wearly.app",
    phone: "0900000004",
    city: "Ha Noi",
    district: "Hoan Kiem",
    address: "Trang Tien Street"
  },
  {
    full_name: "Noah Camera Studio",
    email: "noah.owner@wearly.app",
    phone: "0900000005",
    city: "Ho Chi Minh City",
    district: "Phu Nhuan",
    address: "Phan Xich Long Street"
  }
].map do |attrs|
  User.create!(
    attrs.merge(
      password: "Owner@123",
      password_confirmation: "Owner@123",
      role: "owner",
      status: "active",
      preferred_locale: "en"
    )
  )
end

renters = [
  ["Ava Johnson", "ava.renter@wearly.app", "0910000001", "Ho Chi Minh City"],
  ["Liam Smith", "liam.renter@wearly.app", "0910000002", "Ho Chi Minh City"],
  ["Isabella Brown", "isabella.renter@wearly.app", "0910000003", "Da Nang"],
  ["Ethan Davis", "ethan.renter@wearly.app", "0910000004", "Ha Noi"],
  ["Charlotte Wilson", "charlotte.renter@wearly.app", "0910000005", "Ho Chi Minh City"],
  ["Lucas Martinez", "lucas.renter@wearly.app", "0910000006", "Da Nang"],
  ["Amelia Taylor", "amelia.renter@wearly.app", "0910000007", "Ha Noi"],
  ["Mason Anderson", "mason.renter@wearly.app", "0910000008", "Ho Chi Minh City"]
].map do |full_name, email, phone, city|
  User.create!(
    full_name: full_name,
    email: email,
    phone: phone,
    password: "Renter@123",
    password_confirmation: "Renter@123",
    role: "renter",
    status: "active",
    preferred_locale: "en",
    city: city,
    district: "Central District",
    address: "Customer Address"
  )
end

puts "Creating products..."

product_templates = [
  ["Pink Satin Party Dress", "dress", "👗", "M", "Pink", "Aurora", 280_000, 800_000, 80_000],
  ["Black Evening Gown", "dress", "🖤", "S", "Black", "Luna", 350_000, 1_200_000, 100_000],
  ["White Bridal Mini Dress", "dress", "🤍", "S", "White", "Mira", 420_000, 1_500_000, 120_000],
  ["Pastel Korean Outfit", "outfit", "✨", "M", "Pastel", "Seoul Mood", 220_000, 700_000, 70_000],
  ["Vintage Denim Set", "outfit", "👖", "L", "Blue", "Retro Club", 180_000, 500_000, 50_000],
  ["Elegant Office Blazer", "outfit", "🧥", "M", "Beige", "Modern Muse", 190_000, 600_000, 50_000],
  ["Luxury Ao Dai Red", "dress", "🌹", "M", "Red", "Saigon Silk", 300_000, 1_000_000, 90_000],
  ["Minimal White Shirt", "shirt", "👔", "M", "White", "Clean Studio", 90_000, 250_000, 30_000],
  ["Classic Black Pants", "pants", "👖", "L", "Black", "Urban Fit", 90_000, 250_000, 30_000],
  ["Canon EOS R6 Camera", "camera", "📷", nil, "Black", "Canon", 700_000, 5_000_000, 0],
  ["Sony A7 III Camera", "camera", "📷", nil, "Black", "Sony", 650_000, 4_500_000, 0],
  ["Fujifilm X-T5 Camera", "camera", "📸", nil, "Silver", "Fujifilm", 600_000, 4_000_000, 0],
  ["Sigma 35mm Lens", "lens", "🔭", nil, "Black", "Sigma", 250_000, 2_000_000, 0],
  ["Sony 85mm Portrait Lens", "lens", "🔭", nil, "Black", "Sony", 320_000, 2_500_000, 0],
  ["Pearl Mini Handbag", "accessory", "👜", nil, "White", "Pearl Lane", 120_000, 400_000, 30_000],
  ["Crystal Event Earrings", "accessory", "💎", nil, "Silver", "Glow", 70_000, 300_000, 20_000],
  ["Gold Chain Necklace", "accessory", "📿", nil, "Gold", "Glam", 80_000, 300_000, 20_000],
  ["Birthday Princess Dress", "dress", "🎀", "S", "Pink", "Party Doll", 260_000, 700_000, 70_000],
  ["Champagne Prom Dress", "dress", "🥂", "M", "Champagne", "Starry", 380_000, 1_200_000, 100_000],
  ["Streetwear Oversized Set", "outfit", "🛹", "L", "Gray", "Urban Youth", 170_000, 500_000, 50_000],
  ["Travel Linen Set", "outfit", "🏝️", "M", "Cream", "Summer Club", 160_000, 450_000, 40_000],
  ["Polaroid Camera", "camera", "📷", nil, "White", "Polaroid", 180_000, 1_000_000, 0],
  ["Gimbal Stabilizer", "accessory", "🎥", nil, "Black", "DJI", 200_000, 1_500_000, 0],
  ["LED Video Light Kit", "accessory", "💡", nil, "Black", "Aputure", 150_000, 1_000_000, 0],
  ["Elegant Black Heels", "accessory", "👠", "38", "Black", "Chic", 100_000, 400_000, 30_000],
  ["White Wedding Veil", "accessory", "👰", nil, "White", "Bridal House", 130_000, 500_000, 40_000],
  ["Red Carpet Long Dress", "dress", "💃", "M", "Red", "Velvet", 450_000, 1_500_000, 120_000],
  ["Kids Birthday Dress", "dress", "🧒", "Kids", "Yellow", "Little Star", 150_000, 400_000, 40_000],
  ["Couple Photoshoot Outfit", "outfit", "💕", "M", "Beige", "Couple Mood", 260_000, 800_000, 60_000],
  ["Premium Tripod", "accessory", "📹", nil, "Black", "Manfrotto", 120_000, 700_000, 0]
]

products = product_templates.each_with_index.map do |template, index|
  title, product_type, emoji, size, color, brand, price_per_day, deposit_amount, cleaning_fee = template
  owner = owners[index % owners.length]

  product = Product.create!(
    owner: owner,
    title: title,
    product_type: product_type,
    description: "A stylish and well-maintained #{product_type.humanize.downcase} for events, photoshoots, travel, and special moments.",
    status: "active",
    condition_status: "excellent",
    size: size,
    color: color,
    gender: product_type.in?(["camera", "lens", "accessory"]) ? nil : "female",
    age_group: title.include?("Kids") ? "kids" : "adult",
    brand: brand,
    price_per_day: price_per_day,
    deposit_amount: deposit_amount,
    cleaning_fee: cleaning_fee,
    replacement_value: deposit_amount * 2,
    address: owner.address,
    city: owner.city,
    district: owner.district,
    ward: owner.ward,
    pickup_available: true,
    delivery_available: true,
    details: {
      material: product_type.in?(["dress", "outfit", "shirt", "pants"]) ? "Premium fabric" : nil,
      occasion: ["party", "photoshoot", "travel", "wedding"].sample,
      included_items: product_type.in?(["camera", "lens"]) ? ["charger", "case"] : ["hanger", "protective bag"]
    }
  )

  2.times do |photo_index|
    attach_seed_photo(product, photo_index, emoji)
  end

  product
end

puts "Creating promotions..."

owners.each_with_index do |owner, index|
  Promotion.create!(
    owner_id: owner.id,
    code: "WEARLY#{index + 1}0",
    discount_type: "percentage",
    discount_value: 10,
    max_discount_amount: 100_000,
    min_order_amount: 300_000,
    usage_limit: 100,
    used_count: 0,
    starts_at: 1.day.ago,
    ends_at: 60.days.from_now,
    active: true
  )
end

puts "Creating bookings..."

booking_statuses = ["pending", "accepted", "completed", "cancelled", "rejected"]

20.times do |index|
  product = products[index % products.length]
  renter = renters[index % renters.length]
  owner = product.owner

  start_time = (index - 5).days.from_now.change(hour: 10)
  end_time = start_time + [1, 2, 3, 4].sample.days
  rental_days = [(end_time.to_date - start_time.to_date).to_i + 1, 1].max

  rental_amount = product.price_per_day.to_i * rental_days
  cleaning_fee = product.cleaning_fee.to_i
  deposit_amount = product.deposit_amount.to_i
  platform_fee_rate = 15
  platform_fee_amount = (rental_amount * platform_fee_rate / 100.0).round
  owner_earning_amount = rental_amount + cleaning_fee - platform_fee_amount
  total_amount = rental_amount + cleaning_fee + deposit_amount

  status = booking_statuses[index % booking_statuses.length]

  booking = Booking.create!(
    product: product,
    owner: owner,
    renter: renter,
    status: status,
    start_time: start_time,
    end_time: end_time,
    rental_days: rental_days,
    rental_amount: rental_amount,
    cleaning_fee: cleaning_fee,
    delivery_fee: 0,
    deposit_amount: deposit_amount,
    discount_amount: 0,
    platform_fee_rate: platform_fee_rate,
    platform_fee_amount: platform_fee_amount,
    owner_earning_amount: owner_earning_amount,
    total_amount: total_amount,
    pickup_method: ["self_pickup", "delivery"].sample,
    pickup_address: renter.address,
    return_address: renter.address,
    accepted_at: status.in?(["accepted", "completed"]) ? 1.day.ago : nil,
    rejected_at: status == "rejected" ? 1.day.ago : nil,
    cancelled_at: status == "cancelled" ? 1.day.ago : nil,
    completed_at: status == "completed" ? Time.current : nil,
    cancel_reason: status == "cancelled" ? "Customer changed their plan." : nil,
    reject_reason: status == "rejected" ? "Item is not available for this schedule." : nil
  )

  reservation_status =
    case status
    when "accepted", "completed"
      "confirmed"
    when "cancelled", "rejected"
      "cancelled"
    else
      "pending"
    end

  ProductReservation.create!(
    product: product,
    booking: booking,
    renter: renter,
    start_time: start_time,
    end_time: end_time,
    status: reservation_status,
    reason: "booking"
  )

  Payment.create!(
    booking: booking,
    payer_id: renter.id,
    amount: total_amount,
    payment_method: ["cash", "bank_transfer"].sample,
    status: status.in?(["accepted", "completed"]) ? "paid" : "pending",
    transaction_id: "PAY-#{SecureRandom.hex(6).upcase}",
    paid_at: status.in?(["accepted", "completed"]) ? Time.current : nil,
    admin_note: "Seed payment"
  )

  if status == "completed"
    Payout.create!(
      owner_id: owner.id,
      booking: booking,
      amount: owner_earning_amount,
      status: "paid",
      payout_method: "bank_transfer",
      paid_at: Time.current,
      admin_note: "Seed payout"
    )

    Review.create!(
      booking: booking,
      reviewer_id: renter.id,
      reviewee_id: owner.id,
      product: product,
      rating: [4, 5].sample,
      comment: "Great experience. The item was clean, stylish, and exactly as described."
    )
  end

  if index == 3 || index == 11
    Dispute.create!(
      booking: booking,
      opened_by_id: renter.id,
      reason: "item_condition",
      description: "The renter reported a small condition issue after pickup.",
      status: "open",
      resolution_note: nil,
      resolved_by_id: nil,
      resolved_at: nil
    )
  end

  ProductConditionReport.create!(
    booking: booking,
    product: product,
    user: renter,
    report_type: "before_rental",
    status: "submitted",
    note: "Seed condition report. Item looks good before rental."
  )
end

puts "Seed completed."
puts "Admin login:"
puts "Email: admin@wearly.app"
puts "Password: Admin@123"
puts ""
puts "Owner login example:"
puts "Email: olivia.owner@wearly.app"
puts "Password: Owner@123"
puts ""
puts "Renter login example:"
puts "Email: ava.renter@wearly.app"
puts "Password: Renter@123"
