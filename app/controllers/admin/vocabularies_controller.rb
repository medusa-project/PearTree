module Admin

  class VocabulariesController < ControlPanelController

    def create
      @vocabulary = Vocabulary.new(sanitized_params)
      begin
        @vocabulary.save!
      rescue ActiveRecord::RecordInvalid
        response.headers['X-PearTree-Result'] = 'error'
        render partial: 'shared/validation_messages',
               locals: { entity: @vocabulary }
      rescue => e
        response.headers['X-PearTree-Result'] = 'error'
        flash['error'] = "#{e}"
        keep_flash
        render 'create'
      else
        response.headers['X-PearTree-Result'] = 'success'
        flash['success'] = "Vocabulary \"#{@vocabulary.name}\" created."
        keep_flash
        render 'create' # create.js.erb will reload the page
      end
    end

    ##
    # Responds to POST /vocabularies/:id/delete-vocabulary-terms
    #
    def delete_vocabulary_terms
      if params[:vocabulary_terms]&.respond_to?(:each)
        count = params[:vocabulary_terms].length
        if count > 0
          ActiveRecord::Base.transaction do
            VocabularyTerm.destroy_all(id: params[:vocabulary_terms])
          end
          flash['success'] = "Deleted #{count} vocabulary term(s)."
        end
      else
        flash['error'] = 'No vocabulary terms to delete (none checked).'
      end
      redirect_to :back
    end

    def destroy
      vocabulary = Vocabulary.find(params[:id])
      begin
        vocabulary.destroy!
      rescue => e
        flash['error'] = "#{e}"
      else
        flash['success'] = "Vocabulary \"#{vocabulary.name}\" deleted."
      ensure
        redirect_to admin_vocabularies_url
      end
    end

    ##
    # Responds to POST /admin/vocabularies/import
    #
    def import
      begin
        raise 'No vocabulary specified.' if params[:vocabulary].blank?

        json = params[:vocabulary].read.force_encoding('UTF-8')
        vocab = Vocabulary.from_json(json)
        vocab.save!
      rescue => e
        flash['error'] = "#{e}"
        redirect_to admin_vocabularies_path
      else
        flash['success'] = "Vocabulary imported as #{vocab.name}."
        redirect_to admin_vocabularies_path
      end
    end

    ##
    # Responds to GET /admin/vocabularies
    #
    def index
      @vocabularies = Vocabulary.all.order(:name)
      @vocabulary = Vocabulary.new # for the new-vocabulary form
    end

    ##
    # Responds to GET /admin/vocabularies/:id
    #
    def show
      @vocabulary = Vocabulary.find(params[:id])

      respond_to do |format|
        format.html do
          @new_vocabulary_term = VocabularyTerm.new(vocabulary_id: @vocabulary.id)
        end
        format.json do
          filename = "#{CGI.escape(@vocabulary.name)}.json"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
          render text: JSON.pretty_generate(@vocabulary.as_json)
        end
      end
    end

    def update
      @vocabulary = Vocabulary.find(params[:id])
      if request.xhr?
        begin
          @vocabulary.update!(sanitized_params)
        rescue ActiveRecord::RecordInvalid
          response.headers['X-PearTree-Result'] = 'error'
          render partial: 'shared/validation_messages',
                 locals: { entity: @vocabulary }
        rescue => e
          response.headers['X-PearTree-Result'] = 'error'
          flash['error'] = "#{e}"
          keep_flash
          render 'update'
        else
          response.headers['X-PearTree-Result'] = 'success'
          flash['success'] = "Vocabulary \"#{@vocabulary.name}\" updated."
          keep_flash
          render 'update' # update.js.erb will reload the page
        end
      else
        begin
          @vocabulary.update!(sanitized_params)
        rescue ActiveRecord::RecordInvalid
          response.headers['X-PearTree-Result'] = 'error'
          render 'show'
        rescue => e
          response.headers['X-PearTree-Result'] = 'error'
          flash['error'] = "#{e}"
          render 'show'
        else
          response.headers['X-PearTree-Result'] = 'success'
          flash['success'] = "Vocabulary \"#{@vocabulary.name}\" updated."
          redirect_to :back
        end
      end
    end

    private

    def sanitized_params
      params.require(:vocabulary).permit(:key, :name)
    end

  end

end
