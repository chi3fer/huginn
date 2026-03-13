# API controller for /api namespace with Bearer token authentication
# This provides JSON endpoints compatible with Sales Brain proxy integration
class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  wrap_parameters false

  before_action :authenticate_bearer_token

  private

  # Authenticate Bearer token from Authorization header
  def authenticate_bearer_token
    auth_header = request.headers['Authorization']

    if auth_header.present? && auth_header.start_with?('Bearer ')
      token = auth_header.sub('Bearer ', '').strip
      user = User.find_by_api_token(token)

      if user
        @current_user = user
      else
        render json: { error: 'Invalid or expired token' }, status: :unauthorized
      end
    else
      render json: { error: 'Authorization header required' }, status: :unauthorized
    end
  end

  def require_bearer_user
    authenticate_bearer_token || return
  end

  def current_user
    @current_user
  end
end
