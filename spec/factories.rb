# spec/factories.rb

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password { 'password' }
    password_confirmation { 'password' }
  end

  factory :auth_token do
    association :user
    token_digest { JWT.encode({ user_id: user.id }, Rails.application.secret_key_base) }
  end
end
