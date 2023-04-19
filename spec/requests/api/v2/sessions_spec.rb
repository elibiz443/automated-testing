require 'rails_helper'

RSpec.describe "Api::V2::Sessions", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:auth_token) { FactoryBot.create(:auth_token) }
  let!(:token) { { "Authorization" => "Bearer #{ auth_token.token_digest }" } }

  describe "POST /api/v2/sessions" do
    context "with valid credentials" do
      it "returns a success response with an authentication token" do
        post "/api/v2/login", params: { email: user.email, password: user.password }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("token")
      end
    end

    context "with invalid credentials" do
      it "returns an unauthorized response" do
        post "/api/v2/login", params: { email: user.email, password: "wrong_password" }
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include("Invalid email or password ❌")
      end
    end
  end

  describe "DELETE /api/v2/sessions" do
    it "invalidates the user's authentication token and returns a success response" do
      delete "/api/v2/logout", headers: token
      expect(response).to have_http_status(:ok)
      expect(user.reload.auth_token).to be_nil
      expect(response.body).to include("Logged Out!")
    end

    it "requires authentication" do
      delete "/api/v2/logout"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
