# AUTOMATED-TESTING

This is a Rails 7 API for Simple Authentication app that tackles testing CRUD functionality Using:
* RSpec
* FactoryBot
* Faker
* DatabaseCleaner
* Bcrypt

### Steps to run the app:
```
git clone git@github.com:elibiz443/automated-testing.git && bundle && rails db:create db:migrate db:seed
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

## Version Two

We're going to create api/v2/users_controller.rb where we will add the following:

* jwt gem (For token based authentication)
* shoulda-matchers gem (So as to provide one-liners to test common Rails functionality )

And we are also going to add sessions_controller for authentication.

Start by running the following in terminal:
```
rails g model AuthToken token_digest user:references && rails db:migrate && rails g controller api/v2/sessions && touch app/controllers/base_controller.rb
```

Remember to modify api/v2/sessions_controller.rb, api/v2/users_controller.rb, user.rb, config/routes.rb and base_controller.rb to look as follows:
```
# api/v2/sessions_controller.rb
class Api::V2::SessionsController < BaseController
  before_action :authenticate_user!, except: [:create]

  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      token = user.generate_auth_token
      render json: { token: token, message: "Welcome #{user.name} 👍", user: user }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def destroy
    @current_user.invalidate_token
    head :ok
  end
end

# api/v2/users_controller.rb
class Api::V2::UsersController < BaseController
  before_action :set_user, only: [:show, :update, :destroy]
  before_action :authenticate_user!, except: [:create]

  def index
    render json: { users: User.all }
  end

  def show
    render json: { user: @user }, status: :ok
  end

  def create
    @user = User.new(user_params)

    if @user.save
      token = @user.generate_auth_token
      render json: { message: "User created successfully 👍", token: token, user: @user }, status: :created
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

# base_controller.rb
class BaseController < ActionController::API
  before_action :authenticate_user!

  private

  def authenticate_user!
    token = request.headers["Authorization"]&.split(' ')&.last
    user = User.find_by_token(token)
    if user.nil?
      render json: { error: "Invalid token" }, status: :unauthorized
    else
      @current_user = user
    end
  end
end

#user.rb
class User < ApplicationRecord
  has_one :auth_token, dependent: :destroy
  
  has_secure_password
  validates :email, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :name, presence: true

  default_scope {order('users.created_at ASC')}

  def generate_auth_token
    secret_key = Rails.application.secret_key_base
    payload = { user_id: self.id }
    token = JWT.encode(payload, secret_key)
    AuthToken.create(user: self, token_digest: token)
    token
  end

  def self.find_by_token(token)
    begin
      decoded_payload = JWT.decode(token, Rails.application.secret_key_base)[0]
      User.find(decoded_payload['user_id'])
    rescue JWT::DecodeError
      nil
    end
  end

  def invalidate_token
    auth_token.destroy
  end
end

#routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users
    end
  end

  namespace :api do
    namespace :v2 do
      resources :users
      post "/login", to: "sessions#create"
      delete "/logout", to: "sessions#destroy"
    end
  end
end
```

Now that everything is perfect, we can add/modify tests to the controllers we added as follows:
```
# spec/requests/api/v2/users_spec.rb

require 'rails_helper'

RSpec.describe "Api::V2::Users", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:valid_attributes) { FactoryBot.attributes_for(:user) }
  let(:invalid_attributes) { FactoryBot.attributes_for(:user, email: '') }
  let(:new_attributes) { FactoryBot.attributes_for(:user, name: "Jane") }
  let!(:user_to_delete) { FactoryBot.create(:user) }
  let(:auth_token) { FactoryBot.create(:auth_token) }
  let!(:token) { { "Authorization" => "Bearer #{ auth_token.token_digest }" } }

  describe "GET #index" do
    it "returns a success response" do
      get "/api/v2/users", headers: token
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      get "/api/v2/users/#{user.to_param}", headers: token
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    context "with valid user params" do
      it "creates a new user" do
        expect {
          post "/api/v2/users", params: valid_attributes 
        }.to change(User, :count).by(1)
      end

      it "returns a success response" do
        post "/api/v2/users", params: valid_attributes
        expect(response).to have_http_status(:created)
      end

      it "returns a success message" do
        post "/api/v2/users", params: valid_attributes
        expect(response.body).to include("User created successfully 👍")
      end

      it "returns the created user" do
        post "/api/v2/users", params: valid_attributes 
        expect(JSON.parse(response.body)["user"]).to be_present
      end
    end

    context "with invalid user params" do
      it "does not create a new user" do
        expect { post "/api/v2/users", params: invalid_attributes }.to_not change(User, :count)
      end
      
      it "returns status code 422" do
        post "/api/v2/users", params: invalid_attributes
        expect(response).to have_http_status(422)
      end
      
      it "returns an error message" do
        post "/api/v2/users", params: invalid_attributes
        expect(JSON.parse(response.body)["errors"]).to be_present
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      it "updates the requested user" do
        put "/api/v2/users/#{user.id}", params: new_attributes, headers: token
        user.reload
        expect(user.name).to eq("Jane")
      end

      it "returns a success response" do
        put "/api/v2/users/#{user.id}", params: valid_attributes, headers: token
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid params" do
      it "returns an unprocessable entity response" do
        put "/api/v2/users/#{user.id}", params: invalid_attributes, headers: token
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested user" do
      expect { delete "/api/v2/users/#{user_to_delete.id}", headers: token }.to change(User, :count).by(-1)
    end

    it "returns a success response" do
      delete "/api/v2/users/#{user.id}", headers: token
      expect(response).to have_http_status(:ok)
    end
  end
end

# spec/requests/api/v2/sessions_spec.rb

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

# spec/models/auth_token_spec.rb

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

# spec/models/auth_token_spec.rb

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
```

N/B: shoulda-matchers gem was added to development test group and shoulda.rb file was added to spec/support directory. Also add the following to spec/rails_helper.rb:
```
require 'shoulda/matchers'
require 'support/shoulda'
```

## Third Section
We are going to add home to our app. This is the section that will be accessed after authentication.

Start by:
```
rails g model home detail && rails db:migrate && rails g controller home index
```

Add the following cod:
```
# models/home.rb
class Home < ApplicationRecord
  validates :detail, presence: true
end

# controllers/home_controller.rb
class HomeController < BaseController
  before_action :authenticate_user!

  def index
    render json: { home: Home.all }
  end
end

# spec/models/home_spec.rb
require 'rails_helper'

RSpec.describe Home, type: :model do
  describe "validations" do
    it { should validate_presence_of(:detail) }
  end
end

# spec/requests/home_spec.rb
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
```

###### That's it. Voilà. Happy coding 🙌 

Additional:
Accessing Test Console:
```
RAILS_ENV=test rails c
```

##### Contacts:
* Email: elibiz443@gmail.com
* Phone/WhatsApp: +254768998781
