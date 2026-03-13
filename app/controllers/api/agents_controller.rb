# API agents controller with Bearer token authentication
# Mirrors the functionality of the main agents controller but uses Bearer auth
module Api
  class AgentsController < ApiController
    def index
      @agents = current_user.agents.order("agents.id desc")
      render json: @agents
    end

    def show
      @agent = current_user.agents.find_by_id(params[:id])
    end

    def create
      @agent = current_user.agents.new(agent_params)
      if @agent.save
        render json: @agent, status: :created
      else
        render json: { errors: @agent.errors }, status: :unprocessable_entity
      end
    end

    def update
      @agent = current_user.agents.find_by_id(params[:id])
      if @agent
        if @agent.update(agent_params)
          render json: @agent, status: :ok
        else
          render json: { errors: @agent.errors }, status: :unprocessable_entity
        end
      else
        render json: { error: 'Agent not found' }, status: :not_found
      end
    end

    def destroy
      @agent = current_user.agents.find_by_id(params[:id])
      if @agent
        @agent.destroy
        head :no_content
      else
        render json: { error: 'Agent not found' }, status: :not_found
      end
    end

    def run
      @agent = current_user.agents.find_by_id(params[:id])
      if @agent
        @agent.check
        render json: { status: 'Agent executed' }, status: :accepted
      else
        render json: { error: 'Agent not found' }, status: :not_found
      end
    end

    def leave_scenario
      @agent = current_user.agents.find_by_id(params[:id])
      if @agent
        scenario = @agent.scenarios.find_by_id(params[:scenario_id])
        if scenario
          @agent.scenarios.delete(scenario)
          render json: { status: 'Agent removed from scenario' }, status: :ok
        else
          render json: { error: 'Scenario not found' }, status: :not_found
        end
      else
        render json: { error: 'Agent not found' }, status: :not_found
      end
    end

    def reemit_events
      @agent = current_user.agents.find_by_id(params[:id])
      if @agent
        @agent.events.update_all(expired: false)
        render json: { reemitted: @agent.events.count }, status: :ok
      else
        render json: { error: 'Agent not found' }, status: :not_found
      end
    end

    def remove_events
      @agent = current_user.agents.find_by_id(params[:id])
      if @agent
        @agent.events.delete_all
        render json: { removed: @agent.events.count }, status: :ok
      else
        render json: { error: 'Agent not found' }, status: :not_found
      end
    end

    def destroy_memory
      @agent = current_user.agents.find_by_id(params[:id])
      if @agent
        @agent.memory = {}
        @agent.save
        render json: { status: 'Memory cleared' }, status: :ok
      else
        render json: { error: 'Agent not found' }, status: :not_found
      end
    end

    def handle_details_post
      @agent = current_user.agents.find_by_id(params[:id])
      if @agent
        content, status = @agent.trigger_web_request(request)

        if content.is_a?(String)
          render plain: content, status: status || 200
        elsif content.is_a?(Hash)
          render json: content, status: status || 200
        else
          head(status)
        end
      else
        render json: { error: 'Agent not found' }, status: :not_found
      end
    end

    def toggle_visibility
      @agent = current_user.agents.find_by_id(params[:id])
      if @agent
        @agent.disabled = !@agent.disabled
        @agent.save
        render json: { status: @agent.disabled ? 'disabled' : 'enabled' }, status: :ok
      else
        render json: { error: 'Agent not found' }, status: :not_found
      end
    end

    def propagate
      ids = params[:agent_ids].to_s.split(',').map(&:to_i)
      agents = current_user.agents.where(id: ids)
      agents.each do |agent|
        agent.check if agent.can_be_scheduled?
      end
      render json: { propagated: agents.count }, status: :ok
    end

    def type_details
      render json: { name: 'AgentsController' }
    end

    def event_descriptions
      render json: {
        agents: AgentsController.event_description
      }
    end

    def self.event_description
      'Returns a human readable description of what this Agent creates.'
    end

    def validate
      @agent = current_user.agents.new(agent_params)
      valid = @agent.valid?
      render json: { valid: valid, errors: @agent.errors.full_messages }, status: :ok
    end

    def complete
      @agent = current_user.agents.find_by_id(params[:id])
      if @agent
        # Mark agent as completed/completed successfully
        # This is a custom action for SalesAutomation integration
        render json: { status: 'Agent completed' }, status: :ok
      else
        render json: { error: 'Agent not found' }, status: :not_found
      end
    end

    def destroy_undefined
      undefined_agents = current_user.agents.where(disabled: true)
      undefined_agents.each(&:destroy)
      render json: { destroyed: undefined_agents.count }, status: :ok
    end

    private

    def agent_params
      return {} unless params[:agent]

      permitted = [
        :memory,
        :name,
        :type,
        :schedule,
        :disabled,
        :keep_events_for,
        :propagate_immediately,
        :drop_pending_events,
        :service_id,
        source_ids: [],
        receiver_ids: [],
        scenario_ids: [],
        controller_ids: [],
        control_target_ids: [],
      ]

      if params[:agent].fetch(:options, "").kind_of?(ActionController::Parameters)
        permitted << { options: {} }
      else
        permitted << :options
      end

      params.require(:agent).permit(permitted)
    end
  end
end
