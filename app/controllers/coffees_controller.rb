class CoffeesController < ApplicationController
  allow_unauthenticated_access only: [:index, :show]

  def index
    @coffees = Coffee.active.includes(:coffee_variants).order(:name)

    if params[:roast_type].present?
      @coffees = @coffees.by_roast_type(params[:roast_type])
    end
  end

  def show
    @coffee = Coffee.includes(:coffee_variants).find(params[:id])
  end
end
