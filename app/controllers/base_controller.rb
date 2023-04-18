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
