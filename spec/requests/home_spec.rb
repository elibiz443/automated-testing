require 'rails_helper'

RSpec.describe "Homes", type: :request do
  let(:auth_token) { FactoryBot.create(:auth_token) }
  let!(:token) { { "Authorization" => "Bearer #{ auth_token.token_digest }" } }
  
  describe "GET #index" do
    it "returns a success response" do
      get "/api/v2/users", headers: token
      expect(response).to have_http_status(:ok)
    end
  end
end
