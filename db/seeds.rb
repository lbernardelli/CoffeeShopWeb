# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Clear existing data
Coffee.destroy_all

# Create coffee products with variants (following code_test structure)
coffees_data = [
  {
    name: "Ethiopian Yirgacheffe",
    description: "Bright, floral notes with a hint of citrus and bergamot. Perfect for pour-over brewing. Grown in the highlands of Ethiopia, this coffee offers a wine-like acidity and a clean, crisp finish.",
    roast_type: "light",
    origin: "Ethiopia",
    variants: [
      { size: "small", price: 16.99 },
      { size: "medium", price: 18.99 },
      { size: "large", price: 20.99 }
    ]
  },
  {
    name: "Colombian Supremo",
    description: "Rich, balanced flavor with notes of caramel, cocoa, and roasted nuts. A classic choice for any coffee lover. Sourced from the high-altitude farms of Colombia, this coffee delivers consistent quality and smooth taste.",
    roast_type: "medium",
    origin: "Colombia",
    variants: [
      { size: "small", price: 14.99 },
      { size: "medium", price: 16.99 },
      { size: "large", price: 18.99 }
    ]
  },
  {
    name: "Sumatra Mandheling",
    description: "Bold, earthy flavor with low acidity and herbal notes. Perfect for espresso and French press. This Indonesian coffee is known for its full body and complex flavor profile with hints of dark chocolate.",
    roast_type: "dark",
    origin: "Indonesia",
    variants: [
      { size: "small", price: 17.99 },
      { size: "medium", price: 19.99 },
      { size: "large", price: 21.99 }
    ]
  },
  {
    name: "Kenya AA",
    description: "Wine-like acidity with bright berry notes and a complex flavor profile. One of Africa's finest coffees. Grown at high elevations, this coffee delivers intense flavors with hints of blackcurrant and citrus.",
    roast_type: "light",
    origin: "Kenya",
    variants: [
      { size: "small", price: 19.99 },
      { size: "medium", price: 21.99 },
      { size: "large", price: 23.99 }
    ]
  },
  {
    name: "Costa Rica Tarrazu",
    description: "Bright and clean with a perfect balance of acidity and sweetness. Notes of honey and citrus. This high-altitude coffee from Costa Rica's famous Tarrazu region is known for its exceptional cup quality.",
    roast_type: "medium",
    origin: "Costa Rica",
    variants: [
      { size: "small", price: 15.99 },
      { size: "medium", price: 17.99 },
      { size: "large", price: 19.99 }
    ]
  },
  {
    name: "Italian Espresso",
    description: "Intense and creamy with a rich crema. Perfect for espresso shots and cappuccinos. A masterful blend of beans roasted to perfection, delivering bold flavors with notes of dark chocolate and caramel.",
    roast_type: "dark",
    origin: "Italy",
    variants: [
      { size: "small", price: 13.99 },
      { size: "medium", price: 15.99 },
      { size: "large", price: 17.99 }
    ]
  },
  {
    name: "Guatemala Antigua",
    description: "Smooth with chocolate undertones and a hint of spice. Medium body with balanced acidity. Grown in the volcanic soil surrounding Antigua, this coffee offers a distinctive smoky flavor with sweet notes.",
    roast_type: "medium",
    origin: "Guatemala",
    variants: [
      { size: "small", price: 16.49 },
      { size: "medium", price: 18.49 },
      { size: "large", price: 20.49 }
    ]
  },
  {
    name: "Hawaiian Kona",
    description: "Smooth and mild with a delicate flavor profile. Notes of brown sugar and nuts. One of the world's most sought-after coffees, grown on the slopes of Mauna Loa in Hawaii's perfect coffee-growing climate.",
    roast_type: "light",
    origin: "Hawaii",
    variants: [
      { size: "small", price: 27.99 },
      { size: "medium", price: 29.99 },
      { size: "large", price: 32.99 }
    ]
  },
  {
    name: "French Roast",
    description: "Smoky and bold with a deep, rich flavor. Perfect for those who enjoy a strong cup. This dark roast delivers intense flavors with notes of dark chocolate and a slight bitterness that coffee enthusiasts love.",
    roast_type: "dark",
    origin: "France",
    variants: [
      { size: "small", price: 12.99 },
      { size: "medium", price: 14.99 },
      { size: "large", price: 16.99 }
    ]
  },
  {
    name: "Brazilian Santos",
    description: "Smooth and nutty with low acidity and a sweet finish. Great for everyday drinking. Brazil's most famous coffee, known for its creamy body and notes of chocolate and peanut. Perfect for espresso blends.",
    roast_type: "medium",
    origin: "Brazil",
    variants: [
      { size: "small", price: 13.49 },
      { size: "medium", price: 15.49 },
      { size: "large", price: 17.49 }
    ]
  },
  {
    name: "Jamaican Blue Mountain",
    description: "Exceptionally smooth with no bitterness. Mild flavor with hints of herbs and nuts. One of the world's most expensive and sought-after coffees, grown in the Blue Mountains of Jamaica.",
    roast_type: "medium",
    origin: "Jamaica",
    variants: [
      { size: "small", price: 37.99 },
      { size: "medium", price: 39.99 },
      { size: "large", price: 42.99 }
    ]
  },
  {
    name: "Yemen Mocha",
    description: "Complex and exotic with winey notes and chocolate flavors. Rich body with spicy undertones. One of the oldest coffee varieties, offering a unique taste experience with its distinctive wild and fruity characteristics.",
    roast_type: "medium",
    origin: "Yemen",
    variants: [
      { size: "small", price: 22.99 },
      { size: "medium", price: 24.99 },
      { size: "large", price: 26.99 }
    ]
  }
]

coffees_data.each do |coffee_data|
  variants_data = coffee_data.delete(:variants)

  coffee = Coffee.create!(coffee_data)

  variants_data.each do |variant_data|
    coffee.coffee_variants.create!(variant_data)
  end

  puts "Created coffee: #{coffee.name} with #{coffee.coffee_variants.count} variants"
end

puts "Seeding completed! Created #{Coffee.count} coffees with #{CoffeeVariant.count} variants."
