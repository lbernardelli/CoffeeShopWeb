class Product < ApplicationRecord
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :roast_type, inclusion: { in: %w[light medium dark], allow_nil: true }

  scope :active, -> { where(active: true) }
  scope :by_roast_type, ->(type) { where(roast_type: type) }
end
