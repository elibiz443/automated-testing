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

##### Contacts:
* Email: elibiz443@gmail.com
* Phone/WhatsApp: +254768998781




