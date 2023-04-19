require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user) }
  let(:user) { FactoryBot.create(:user) }
  let(:token) { JWT.encode({ user_id: user.id }, Rails.application.secret_key_base) }

  describe "Valid FactoryBot" do 
    it "has a valid factory" do
      expect(FactoryBot.create(:user)).to be_valid
    end
  end

  describe "associations" do
    it { should have_one(:auth_token).dependent(:destroy) }
  end

  describe "validations" do
    it { should be_valid }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:password) }
    it { should validate_length_of(:password).is_at_least(6) }
    it { should validate_presence_of(:password_confirmation) }
    it { should validate_length_of(:password_confirmation).is_at_least(6) }
  end

  describe "Generating auth_token" do
    it "creates an auth token for the user" do
      expect { user.generate_auth_token }.to change { AuthToken.count }.by(1)
      expect(user.auth_token).to be_present
    end

    it "returns a JWT token" do
      token = user.generate_auth_token
      expect(token).to be_a(String)
      expect(token).not_to be_blank
    end
  end

  describe "Find By Token" do
    it "returns the user for a valid token" do
      expect(User.find_by_token(token)).to eq(user)
    end

    it "returns nil for an invalid token" do
      expect(User.find_by_token("invalid_token")).to be_nil
    end
  end

  describe "Invalidate token" do
    it "destroys the user's auth token" do
      user.generate_auth_token
      expect { user.invalidate_token }.to change { AuthToken.count }.by(-1)
      expect(user.auth_token).to be_nil
    end
  end
end
