require 'rails_helper'

RSpec.describe Home, type: :model do
  describe "validations" do
    it { should validate_presence_of(:detail) }
  end
end
