require 'rails_helper'

RSpec.describe Api::ScenariosController, type: :controller do
  let(:token) { 'secret_api_token_123' }
  let!(:admin) { users(:bob) }
  let!(:scenario) { scenarios(:bob_weather) }

  before do
    ENV['HUGINN_API_TOKEN'] = token
    admin.update!(admin: true) unless admin.admin?
    request.headers['Authorization'] = "Bearer #{token}"
  end

  describe 'GET #index' do
    it 'returns a successful response with scenarios' do
      get :index
      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response).to be_an(Array)
      expect(json_response.first['id']).to eq(scenario.id)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:valid_params) do
        { scenario: { name: 'New Scenario', description: 'Test description' } }
      end

      it 'creates a new scenario' do
        expect {
          post :create, params: valid_params
        }.to change(Scenario, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        { scenario: { name: '' } }
      end

      it 'returns unprocessable entity' do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
      end
    end
  end
end
