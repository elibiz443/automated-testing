require 'rails_helper'

RSpec.describe "Api::V1::Users", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:valid_attributes) { FactoryBot.attributes_for(:user) }
  let(:invalid_attributes) { FactoryBot.attributes_for(:user, email: '') }
  let(:new_attributes) { FactoryBot.attributes_for(:user, name: "Jane") }
  let!(:user_to_delete) { FactoryBot.create(:user) }

  describe "GET #index" do
    it "returns a success response" do
      get "/api/v1/users"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      get "/api/v1/users/#{user.to_param}"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    context "with valid user params" do
      it "creates a new user" do
        expect {
          post "/api/v1/users", params: valid_attributes 
        }.to change(User, :count).by(1)
      end

      it "returns a success response" do
        post "/api/v1/users", params: valid_attributes
        expect(response).to have_http_status(:created)
      end

      it "returns a success message" do
        post "/api/v1/users", params: valid_attributes
        expect(response.body).to include("User created successfully 👍")
      end

      it "returns the created user" do
        post "/api/v1/users", params: valid_attributes 
        expect(JSON.parse(response.body)["user"]).to be_present
      end
    end

    context "with invalid user params" do
      it "does not create a new user" do
        expect { post "/api/v1/users", params: invalid_attributes }.to_not change(User, :count)
      end
      
      it "returns status code 422" do
        post "/api/v1/users", params: invalid_attributes
        expect(response).to have_http_status(422)
      end
      
      it "returns an error message" do
        post "/api/v1/users", params: invalid_attributes
        expect(JSON.parse(response.body)["errors"]).to be_present
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      it "updates the requested user" do
        put "/api/v1/users/#{user.id}", params: new_attributes
        user.reload
        expect(user.name).to eq("Jane")
      end

      it "returns a success response" do
        put "/api/v1/users/#{user.id}", params: valid_attributes
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid params" do
      it "returns an unprocessable entity response" do
        put "/api/v1/users/#{user.id}", params: invalid_attributes
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested user" do
      expect { delete "/api/v1/users/#{user_to_delete.id}" }.to change(User, :count).by(-1)
    end

    it "returns a success response" do
      delete "/api/v1/users/#{user.id}"
      expect(response).to have_http_status(:ok)
    end
  end
end
