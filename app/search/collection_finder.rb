##
# Provides a convenient ActiveRecord-style Builder interface for Collection
# retrieval.
#
class CollectionFinder < AbstractFinder

  def initialize
    super
    @include_unpublished = false
    @search_children = false
  end

  ##
  # @param bool [Boolean]
  # @return [self]
  #
  def search_children(bool)
    @search_children = bool
    self
  end

  ##
  # @param bool [Boolean]
  # @return [self]
  #
  def include_unpublished(bool)
    @include_unpublished = bool
    self
  end

  private

  def load
    return if @loaded

    result = Collection.search(build_query)

    # Assemble the response aggregations into Facets.
    result.response.aggregations.each do |agg|
      facet = Facet.new
      facet.name = Collection.facet_fields.select{ |f| f[:name] == agg[0] }.
          first[:label]
      facet.field = agg[0]
      agg[1]['buckets'].each do |bucket|
        term = FacetTerm.new
        term.name = bucket['key'].to_s
        term.label = bucket['key'].to_s
        term.count = bucket['doc_count']
        term.facet = facet
        facet.terms << term
      end
      @result_facets << facet
    end

    @result_instances = result.records
    @result_count = result.results.total

    @loaded = true
  end

  ##
  # @return [String] JSON string.
  #
  def build_query
    json = Jbuilder.encode do |j|
      j.query do
        j.bool do
          # Query
          if @query.present?
            j.must do
              # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html
              j.query_string do
                j.query @query[:query]
                j.default_field @query[:field]
                j.default_operator 'AND'
                j.lenient true
              end
            end
          end

          if @filters.any? or !@include_unpublished
            j.filter do
              @filters.each do |field, value|
                j.child! do
                  if value.respond_to?(:each)
                    j.terms do
                      j.set! field, value
                    end
                  else
                    j.term do
                      j.set! field, value
                    end
                  end
                end
              end

              unless @include_unpublished
                j.child! do
                  j.term do
                    j.set! Collection::IndexFields::EFFECTIVELY_PUBLISHED, true
                  end
                end
              end
            end
          end

          if @user_roles.any?
            j.should do
              j.child! do
                j.terms do
                  j.set! Collection::IndexFields::ALLOWED_ROLES, @user_roles
                end
              end
              j.child! do
                j.terms do
                  j.set! Collection::IndexFields::ALLOWED_ROLES, []
                end
              end
            end
          end

          if @user_roles.any? or !@search_children
            j.must_not do
              if @user_roles.any?
                j.child! do
                  j.terms do
                    j.set! Collection::IndexFields::DENIED_ROLES, @user_roles
                  end
                end
              end
              unless @search_children
                j.child! do
                  j.exists do
                    j.field Collection::IndexFields::PARENT_COLLECTIONS
                  end
                end
              end
            end
          end
        end
      end

      # Aggregations
      j.aggregations do
        Collection.facet_fields.each do |facet|
          j.set! facet[:name] do
            j.terms do
              j.field facet[:name]
            end
          end
        end
      end

      # Ordering
      if @orders.any?
        j.sort do
          @orders.each do |order|
            j.set! order[:field] do
              j.order order[:direction]
            end
          end
        end
      end

      # Start
      if @start.present?
        j.from @start
      end

      # Limit
      if @limit.present?
        j.size @limit
      end
    end

    # For debugging
    #File.write('query.json', JSON.pretty_generate(JSON.parse(json)))
    # curl -XGET 'localhost:9200/collections_development/_search?size=0&pretty' -H 'Content-Type: application/json' -d @query.json

    json
  end

end