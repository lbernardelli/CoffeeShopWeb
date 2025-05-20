require 'rails_helper'

RSpec.describe Coffee, type: :model do
  describe 'associations' do
    it 'has many coffee variants' do
      association = Coffee.reflect_on_association(:coffee_variants)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe 'validations' do
    it 'validates presence of name' do
      coffee = build(:coffee, name: nil)
      expect(coffee).not_to be_valid
      expect(coffee.errors[:name]).to include("can't be blank")
    end

    it 'validates roast_type is in valid list when present' do
      coffee = build(:coffee, roast_type: 'invalid')
      expect(coffee).not_to be_valid
      expect(coffee.errors[:roast_type]).to include('is not included in the list')
    end

    it 'allows nil roast_type' do
      coffee = build(:coffee, roast_type: nil)
      expect(coffee).to be_valid
    end
  end

  describe 'scopes' do
    describe '.active' do
      it 'returns only active coffees' do
        active_coffee = create(:coffee, active: true)
        inactive_coffee = create(:coffee, active: false)

        expect(Coffee.active).to include(active_coffee)
        expect(Coffee.active).not_to include(inactive_coffee)
      end
    end

    describe '.by_roast_type' do
      it 'returns coffees filtered by roast type' do
        light_coffee = create(:coffee, :light_roast)
        dark_coffee = create(:coffee, :dark_roast)

        expect(Coffee.by_roast_type('light')).to include(light_coffee)
        expect(Coffee.by_roast_type('light')).not_to include(dark_coffee)
      end
    end
  end

  describe '#price' do
    let(:coffee) { create(:coffee, :with_variants) }

    it 'returns the price for a given size' do
      small_variant = coffee.coffee_variants.find_by(size: 'small')

      expect(coffee.price('small')).to eq(small_variant.price)
    end

    it 'returns 0 if size does not exist' do
      expect(coffee.price('extra_large')).to eq(0)
    end
  end

  describe '#starting_price' do
    context 'with variants' do
      let(:coffee) { create(:coffee) }

      before do
        create(:coffee_variant, coffee: coffee, size: 'small', price: 10.00)
        create(:coffee_variant, coffee: coffee, size: 'large', price: 20.00)
      end

      it 'returns the minimum price from variants' do
        expect(coffee.starting_price).to eq(10.00)
      end
    end

    context 'without variants' do
      let(:coffee) { create(:coffee) }

      it 'returns 0' do
        expect(coffee.starting_price).to eq(0)
      end
    end
  end
end
