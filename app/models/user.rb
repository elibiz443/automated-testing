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
