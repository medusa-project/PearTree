module Api

  class ItemsController < ApiController

    before_action :enforce_json_content_type, only: :update

    ##
    # Responds to DELETE /api/items/:id
    #
    def destroy
      item = Item.find_by_repository_id(params[:id])
      begin
        raise ActiveRecord::RecordNotFound unless item
        item.destroy!
      rescue ActiveRecord::RecordNotFound => e
        render text: "#{e}", status: :not_found
      rescue => e
        render text: "#{e}", status: :internal_server_error
      else
        render text: 'Success'
      end
    end

    ##
    # Responds to GET /api/items and /api/collections/:collection_id/items
    #
    def index
      @start = params[:start].to_i
      @limit = params[:limit].to_i
      @limit = DEFAULT_RESULTS_LIMIT if @limit < 1
      @limit = MAX_RESULTS_LIMIT if @limit > MAX_RESULTS_LIMIT

      finder = ItemFinder.new.
          collection_id(params[:collection_id]).
          query(params[:q]).
          include_children(true).
          include_unpublished(true).
          filter_queries(params[:fq]).
          sort(params[:sort]).
          start(@start).
          limit(@limit)

      @items = finder.to_a

      @current_page = finder.page
      @count = finder.count
      @num_results_shown = [@limit, @count].min

      render json: {
          start: @start,
          limit: @limit,
          numResults: @items.count,
          results: @items.select(&:present?).map { |item|
            {
                id: item.repository_id,
                url: api_item_url(item)
            }
          }
      }
    end

    ##
    # Responds to GET /api/items/:id
    #
    def show
      @item = Item.find_by_repository_id(params[:id])
      raise ActiveRecord::RecordNotFound unless @item
      render json: @item
    end

    ##
    # Responds to PUT /api/items/:id
    #
    def update
      item = Item.find_by_repository_id(params[:id])
      begin
        raise ActiveRecord::RecordNotFound unless item

        item.update_from_json(request.body.read)
      rescue ActiveRecord::RecordNotFound => e
        render text: "#{e}", status: :not_found
      rescue => e
        render text: "#{e}", status: :internal_server_error
      else
        render text: 'Success'
      end
    end

  end

end