module Admin

  class ElementsController < ControlPanelController

    class ImportMode
      MERGE = 'merge'
      REPLACE = 'replace'
    end

    ##
    # XHR only
    #
    def create
      @element = Element.new(sanitized_params)
      begin
        @element.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @element }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        flash['error'] = "#{e}"
        keep_flash
        render 'create'
      else
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Element \"#{@element.name}\" created."
        keep_flash
        render 'create' # create.js.erb will reload the page
      end
    end

    def destroy
      element = Element.find(params[:id])
      begin
        element.destroy!
      rescue => e
        flash['error'] = "#{e}"
      else
        flash['success'] = "Element \"#{element.name}\" deleted."
      ensure
        redirect_to :back
      end
    end

    ##
    # XHR only
    #
    def edit
      element = Element.find(params[:id])
      render partial: 'admin/elements/form',
             locals: { element: element, context: :edit }
    end

    ##
    # Responds to POST /admin/elements/import
    #
    def import
      begin
        raise 'No elements specified.' if params[:elements].blank?

        json = params[:elements].read.force_encoding('UTF-8')
        struct = JSON.parse(json)
        ActiveRecord::Base.transaction do
          if params[:import_mode] == ImportMode::REPLACE
            Element.delete_all # skip callbacks & validation
          end
          struct.each do |hash|
            e = Element.find_by_name(hash['name'])
            if e
              e.update_from_json_struct(hash)
            else
              Element.from_json_struct(hash).save!
            end
          end
        end
      rescue => e
        flash['error'] = "#{e}"
        redirect_to admin_elements_path
      else
        flash['success'] = "#{struct.length} elements created or updated."
        redirect_to admin_elements_path
      end
    end

    ##
    # Responds to GET /elements
    #
    def index
      @elements = Element.all.order(:name)
      respond_to do |format|
        format.html { @new_element = Element.new }
        format.json {
          headers['Content-Disposition'] = "attachment; filename=elements.json"
          render text: JSON.pretty_generate(@elements.as_json)
        }
      end
    end

    ##
    # Responds to GET /elements/schema
    #
    def schema
      render xml: Item.xml_schema
    end

    ##
    # XHR only
    #
    def update
      element = Element.find(params[:id])
      begin
        element.update!(sanitized_params)
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: element }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        flash['error'] = "#{e}"
        keep_flash
        render 'update'
      else
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Element \"#{element.name}\" updated."
        keep_flash
        render 'update' # update.js.erb will reload the page
      end
    end

    private

    def sanitized_params
      params.require(:element).permit(:description, :name)
    end

  end

end
