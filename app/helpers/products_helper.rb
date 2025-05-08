module ProductsHelper
  def product_gradient_class(index)
    gradients = [
      "bg-gradient-to-br from-amber-200 to-orange-300",
      "bg-gradient-to-br from-yellow-200 to-amber-300",
      "bg-gradient-to-br from-orange-300 to-red-300",
      "bg-gradient-to-br from-green-200 to-teal-300",
      "bg-gradient-to-br from-purple-200 to-pink-300",
      "bg-gradient-to-br from-blue-200 to-indigo-300",
      "bg-gradient-to-br from-rose-200 to-orange-300",
      "bg-gradient-to-br from-cyan-200 to-blue-300",
      "bg-gradient-to-br from-gray-300 to-slate-400"
    ]

    gradients[index % gradients.length]
  end
end
