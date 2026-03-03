require 'rails_helper'

RSpec.describe Api::AgentsController, type: :controller do
  let!(:admin) { users(:bob) }
  let!(:agent) { agents(:bob_website_agent) }

  before do
    admin.update!(admin: true) unless admin.admin?
    # Regenerate token if nil (has_secure_token sets it on create but fixtures may not have it)
    admin.regenerate_api_token if admin.api_token.blank?
    sign_in admin
    request.headers['Authorization'] = "Bearer #{admin.api_token}"
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
        # Missing required name field; type is valid but name is blank
        { agent: { type: 'Agents::ManualEventAgent', name: '' } }
      end

      it 'returns unprocessable entity' do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
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
    it 'executes the agent' do
      allow_any_instance_of(Agent).to receive(:check)
      post :run, params: { id: agent.id }
      expect(response).to have_http_status(:accepted)
      expect(JSON.parse(response.body)['status']).to eq('Agent executed')
    end
  end
end
