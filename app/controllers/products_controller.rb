class ProductsController < ApplicationController
  skip_before_action :authenticate, only: [ :index, :show ]

  def index
    @products = Product.active.order(:name)

    if params[:roast_type].present?
      @products = @products.by_roast_type(params[:roast_type])
    end
  end

  def show
    @product = Product.find(params[:id])
  end
end
