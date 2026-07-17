class Promotion < ApplicationRecord
  belongs_to :owner, class_name: "User", optional: true
  has_many :promotion_redemptions, dependent: :restrict_with_error
end
