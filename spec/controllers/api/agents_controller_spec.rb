require 'rails_helper'

RSpec.describe Api::AgentsController, type: :controller do
  let(:token) { 'secret_api_token_123' }
  let!(:admin) { users(:bob) }
  let!(:agent) { agents(:bob_website_agent) }

  before do
    ENV['HUGINN_API_TOKEN'] = token
    admin.update!(admin: true) unless admin.admin?
    request.headers['Authorization'] = "Bearer #{token}"
  end

  describe 'GET #index' do
    it 'returns a successful response with agents' do
      get :index
      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response).to be_an(Array)
      expect(json_response.first['id']).to eq(agent.id)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:valid_params) do
        { agent: { type: 'Agents::ManualEventAgent', name: 'New Agent' } }
      end

      it 'creates a new agent' do
        expect {
          post :create, params: valid_params
        }.to change(Agent, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        { agent: { type: 'InvalidType', name: '' } }
      end

      it 'returns unprocessable entity' do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:valid_params) do
        { id: agent.id, agent: { name: 'Updated Agent Name' } }
      end

      it 'updates the agent' do
        put :update, params: valid_params
        expect(response).to have_http_status(:ok)
        agent.reload
        expect(agent.name).to eq('Updated Agent Name')
      end
    end
  end

  describe 'POST #run' do
    it 'enqueues the agent' do
      expect_any_instance_of(Agent).to receive(:enqueue_worker)
      post :run, params: { id: agent.id }
      expect(response).to have_http_status(:ok)
    end
  end
end
