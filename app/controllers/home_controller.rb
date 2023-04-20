class HomeController < BaseController
  before_action :authenticate_user!

  def index
    render json: { home: Home.all }
  end
end
