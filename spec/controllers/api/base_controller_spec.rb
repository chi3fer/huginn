require 'rails_helper'

RSpec.describe Api::BaseController, type: :controller do
  controller do
    def index
      render json: { message: 'success' }
    end
  end

  describe 'authentication' do
    let(:token) { 'secret_api_token_123' }
    let!(:admin) { users(:bob) } # Assuming bob is admin in fixtures, or create one

    before do
      ENV['HUGINN_API_TOKEN'] = token
      admin.update!(admin: true) unless admin.admin?
    end

    it 'rejects requests without an Authorization header' do
      get :index
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq('error' => 'Missing API token')
    end

    it 'rejects requests with an invalid token' do
      request.headers['Authorization'] = 'Bearer invalid_token'
      get :index
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq('error' => 'Invalid API token')
    end

    it 'accepts requests with a valid token and sets current_user' do
      request.headers['Authorization'] = "Bearer #{token}"
      get :index
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq('message' => 'success')
      expect(controller.current_user).to eq(admin)
    end
  end
end
