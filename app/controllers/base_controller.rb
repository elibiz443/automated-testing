class BaseController < ActionController::API
  before_action :authenticate_user!

  private

  def authenticate_user!
    token = request.headers["Authorization"]&.split(' ')&.last
    user_token = AuthToken.find_by(token_digest: token)

    if user_token.nil?
      render json: { error: "Token Doesn't Exist" }, status: :unauthorized
    else
      user_id = user_token.user_id
      user = User.find(user_id)

      if user.nil?
        render json: { error: "Invalid token" }, status: :unauthorized
      else
        @current_user = user
      end
    end
  end
end
