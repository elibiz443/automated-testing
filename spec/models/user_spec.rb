require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    let(:user) { build(:user) }

    it "is valid with valid attributes" do
      expect(user).to be_valid
    end

    it "is not valid without a name" do
      user.name = nil
      expect(user).not_to be_valid
    end

    it "is not valid without a unique email" do
      existing_user = create(:user)
      user.email = existing_user.email
      expect(user).not_to be_valid
    end

    it "is not valid without a password" do
      user.password = nil
      expect(user).not_to be_valid
    end
  end
end
