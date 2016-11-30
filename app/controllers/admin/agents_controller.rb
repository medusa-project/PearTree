module Admin

  class AgentsController < ControlPanelController

    ##
    # XHR only
    #
    def create
      @agent = Agent.new(sanitized_params)
      begin
        @agent.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @agent }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        handle_error(e)
        keep_flash
        render 'create'
      else
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Agent \"#{@agent.name}\" created."
        keep_flash
        render 'create' # create.js.erb will reload the page
      end
    end

    def destroy
      agent = Agent.find(params[:id])
      begin
        agent.destroy!
      rescue => e
        handle_error(e)
      else
        flash['success'] = "Agent \"#{agent.name}\" deleted."
      ensure
        redirect_to :back
      end
    end

    ##
    # XHR only
    #
    def edit
      agent = Agent.find(params[:id])
      render partial: 'admin/agents/form',
             locals: { agent: agent, context: :edit }
    end

    def index
      @limit = Option::integer(Option::Key::RESULTS_PER_PAGE)
      @start = params[:start] ? params[:start].to_i : 0

      @agents = Agent.all.order(:name).offset(@start).limit(@limit)
      @new_agent = Agent.new
    end

    private

    def sanitized_params
      params.require(:agent).permit(:description, :last_name, :name, :uri,
                                    :variant_name)
    end

    ##
    # XHR only
    #
    def update
      agent = Agent.find(params[:id])
      begin
        agent.update!(sanitized_params)
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: agent }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        handle_error(e)
        keep_flash
        render 'update'
      else
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Agent \"#{agent.name}\" updated."
        keep_flash
        render 'update' # update.js.erb will reload the page
      end
    end

  end

end
