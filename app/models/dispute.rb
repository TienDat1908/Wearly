class Dispute < ApplicationRecord
  belongs_to :booking
  belongs_to :opened_by, class_name: "User"
  belongs_to :resolved_by, class_name: "User", optional: true
end
