module Api
  class BaseController < ApplicationController
    skip_before_action :authenticate_user!
    before_action :authenticate_api_token!

    attr_reader :current_user

    private

    def authenticate_api_token!
      token = request.headers['Authorization']&.split(' ')&.last

      if token.blank?
        render json: { error: 'Missing API token' }, status: :unauthorized
        return
      end

      expected_token = ENV['HUGINN_API_TOKEN']

      unless expected_token.present? && ActiveSupport::SecurityUtils.secure_compare(token, expected_token)
        render json: { error: 'Invalid API token' }, status: :unauthorized
        return
      end

      # For a globally configured token, we act as the first admin user
      @current_user = User.where(admin: true).first || User.first
      unless @current_user
        render json: { error: 'No user found' }, status: :unauthorized
      end
    end
  end
end
