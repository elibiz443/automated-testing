class Api::V2::SessionsController < BaseController
  before_action :authenticate_user!, except: [:create]

  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      token = user.generate_auth_token
      render json: { token: token, message: "Welcome #{user.name} 👍", user: user }, status: :ok
    else
      render json: { error: "Invalid email or password ❌" }, status: :unauthorized
    end
  end

  def destroy
    @current_user.invalidate_token
    render json: { message: "Logged Out!" }, status: :ok
  end
end
