# AUTOMATED-TESTING

This is an API 7 Simple Authentication app that tackles testing CRUD functionality Using:
* RSpec
* FactoryBot
* Faker
* DatabaseCleaner
* Bcrypt

### Steps to run the app:
```
git clone git@github.com:elibiz443/automated-testing.git && bundle && rails db:create db:migrate
```

### The making of the app:

1. Create a new API:

I start by runing in terminal:
```
rails new automated-testing -d postgresql --api -T && cd automated-testing
```
I do this so as to generate rails 7 API skeleton.

Requirements:
* postgresql as the database for Active Record.(Setup your postgresql as per your machine)
* Ruby version 3.2.0
* Rails version 7.0.4
* Doesn't use the default Minitest for testing coz I will be using RSpec.

i) Addind RSpec:

In Gemfile, add/replace:
```
group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "rspec-rails"
  gem "factory_bot_rails", :require => false
  gem "faker"
  gem "database_cleaner-active_record"
end
```
In Terminal, Run:
```
bundle && rails g rspec:install
```

Create these folder and files, through running the following in terminal(in our app directory):
```
mkdir spec/support && touch spec/support/factory_bot.rb && touch spec/factories.rb
```

Configure FactoryBot by adding:
```
# spec/support/factory_bot.rb

require 'factory_bot'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  FactoryBot.find_definitions
end
```

In rails_helper.rb:
Require support files
```
require_relative 'support/factory_bot'
```
Then uncomment
```
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }
```

When User model is generated (or any model) RSpec will generate a factory in factories.rb file. Modify it to look like:
```
# spec/factories.rb

FactoryBot.define do
end
```

Run Tests with:
```
rspec
```

##### Optional:

Add in .rspec file:
```
--format documentation 
```

ii) Setup DatabaseCleaner:

Run:
```
touch spec/support/database_cleaner.rb
```
Then Add the following to spec/support/factory_bot.rb file: 

```
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, :js => true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
```

Create a simple Model(Attributes: name, email & password)
```
rails g model user name email password_digest && rails db:create db:migrate
```

Uncomment bcrypt & bundle
```
bundle
```

Add validations to user.rb:
```
  has_secure_password
  validates :email, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :name, presence: true
```

Set up validation test:
In spec/models/user_spec.rb, add:
```
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
```
In spec/factories.rb, add:
```
# spec/factories.rb

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password { 'password' }
    password_confirmation { 'password' }
  end
end
```
In terminal, Run:
```
spec
```

Create Users Controller:
```
rails g controller api/v1/users
```
Add the following to the api/v1/users_controller.rb file:
```
class Api::V1::UsersController < ApplicationController
  before_action :set_user, only: [:show, :update, :destroy]

  def index
    render json: { users: User.all }
  end

  def show
    render json: { user: @user }, status: :ok
  end

  def create
    @user = User.new(user_params)

    if @user.save
      render json: { message: "User created successfully 👍", user: @user }, status: :created
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      render json: { message: "User updated successfully 👍", User: @user }, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    render json: { message: "User deleted successfully ❌" }, status: :ok
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.permit(:name, :email, :password, :password_confirmation)
  end
end
```
Modify config/routes.rb file to the following:
```
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users
    end
  end
end
```

Add The following User controller test in(spec/api/v1/users_spec.rb):
```
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
```

##### Contacts:
* Email: elibiz443@gmail.com
* Phone/WhatsApp: +254768998781
