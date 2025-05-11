class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @featured_coffees = Coffee.active.includes(:coffee_variants).limit(3)
  end
end
