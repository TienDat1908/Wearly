class ProductConditionReport < ApplicationRecord
  belongs_to :booking
  belongs_to :product
  belongs_to :user
end
