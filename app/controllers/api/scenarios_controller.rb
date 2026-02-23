# API scenarios controller with Bearer token authentication
# Mirrors the functionality of the main scenarios controller but uses Bearer auth
module Api
  class ScenariosController < ApiController
    def index
      @scenarios = current_user.scenarios.order("scenarios.id desc")
    end

    def show
      @scenario = current_user.scenarios.find_by_id(params[:id])
    end

    def create
      @scenario = current_user.scenarios.new(scenario_params)
      if @scenario.save
        render json: @scenario, status: :created
      else
        render json: @scenario.errors, status: :unprocessable_entity
      end
    end

    def update
      @scenario = current_user.scenarios.find_by_id(params[:id])
      if @scenario
        if @scenario.update(scenario_params)
          render json: @scenario, status: :ok
        else
          render json: @scenario.errors, status: :unprocessable_entity
        end
      else
        render json: { error: 'Scenario not found' }, status: :not_found
      end
    end

    def destroy
      @scenario = current_user.scenarios.find_by_id(params[:id])
      if @scenario
        @scenario.destroy_with_mode(params[:mode] || 'unique_agents')
        render json: { status: 'Scenario deleted' }, status: :ok
      else
        render json: { error: 'Scenario not found' }, status: :not_found
      end
    end

    def share
      @scenario = current_user.scenarios.find_by_id(params[:id])
      if @scenario
        # Generate share link with token-based access
        share_token = SecureRandom.hex(16)
        # Store the share token in scenario metadata or session
        render json: { share_url: "/api/scenarios/#{@scenario.id}?token=#{share_token}" }, status: :ok
      else
        render json: { error: 'Scenario not found' }, status: :not_found
      end
    end

    def export
      @scenario = current_user.scenarios.find_by_id(params[:id])
      if @scenario
        export_data = {
          name: @scenario.name,
          agents: @scenario.agents.map { |agent| agent.options },
          created_at: @scenario.created_at,
          updated_at: @scenario.updated_at
        }
        render json: export_data, status: :ok
      else
        render json: { error: 'Scenario not found' }, status: :not_found
      end
    end

    def enable_or_disable_all_agents
      @scenario = current_user.scenarios.find_by_id(params[:id])
      if @scenario
        new_state = params[:enabled] == 'true'
        @scenario.agents.each do |agent|
          agent.disabled = !new_state
          agent.save
        end
        render json: { status: new_state ? 'enabled' : 'disabled' }, status: :ok
      else
        render json: { error: 'Scenario not found' }, status: :not_found
      end
    end

    private

    def scenario_params
      params.require(:scenario).permit(:name, :tag_fg_color, :tag_bg_color, :public, :agent_ids, :description)
    end
  end
end
