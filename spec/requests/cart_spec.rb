require 'rails_helper'

RSpec.describe "Carts", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/cart/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /add_item" do
    it "returns http success" do
      get "/cart/add_item"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /remove_item" do
    it "returns http success" do
      get "/cart/remove_item"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update_quantity" do
    it "returns http success" do
      get "/cart/update_quantity"
      expect(response).to have_http_status(:success)
    end
  end

end
