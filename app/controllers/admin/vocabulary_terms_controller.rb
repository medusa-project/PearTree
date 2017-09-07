module Admin

  class VocabularyTermsController < ControlPanelController

    ##
    # XHR only
    #
    def create
      @vocabulary_term = VocabularyTerm.new(sanitized_params)
      begin
        @vocabulary_term.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @vocabulary_term }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        handle_error(e)
        keep_flash
        render 'create'
      else
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Vocabulary term \"#{@vocabulary_term}\" created."
        keep_flash
        render 'create' # create.js.erb will reload the page
      end
    end

    def destroy
      term = VocabularyTerm.find(params[:id])
      begin
        term.destroy!
      rescue => e
        handle_error(e)
      else
        flash['success'] = "Vocabulary term \"#{term}\" deleted."
      ensure
        redirect_back fallback_location: admin_vocabulary_terms_path
      end
    end

    ##
    # XHR only
    #
    def edit
      term = VocabularyTerm.find(params[:id])
      render partial: 'admin/vocabulary_terms/form',
             locals: { vocabulary_term: term,
                       context: :edit }
    end

    ##
    # XHR only
    #
    def update
      term = VocabularyTerm.find(params[:id])
      begin
        term.update!(sanitized_params)
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: term }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        handle_error(e)
        keep_flash
        render 'update'
      else
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Vocabulary term \"#{term}\" updated."
        keep_flash
        render 'update' # update.js.erb will reload the page
      end
    end

    private

    def sanitized_params
      params.require(:vocabulary_term).permit(:string, :uri, :vocabulary_id)
    end

  end

end
