class PromotionRedemption < ApplicationRecord
  belongs_to :promotion
  belongs_to :user
  belongs_to :booking
end
