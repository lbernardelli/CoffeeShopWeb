class CoffeeVariant < ApplicationRecord
  belongs_to :coffee

  validates :size, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :size, uniqueness: { scope: :coffee_id }
end
