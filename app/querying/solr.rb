##
# Singleton class interfacing with Solr.
#
class Solr

  include Singleton

  SCHEMA = YAML.load(File.read(File.join(__dir__, 'schema.yml')))

  ##
  # @param doc [Hash]
  #
  def add(doc)
    Rails.logger.info("Adding Solr document: #{doc['id']}")
    client.add(doc)
  end

  def commit
    client.commit
  end

  ##
  # @param id [String]
  #
  def delete(id)
    Rails.logger.info("Deleting Solr document: #{id}")
    client.delete_by_id(id)
  end

  alias_method :delete_by_id, :delete

  def get(endpoint, options = {})
    Rails.logger.debug("Solr request: #{endpoint}; #{options}")
    client.get(endpoint, options)
  end

  ##
  # Deletes everything.
  #
  def purge
    Rails.logger.info('Purging Solr')
    client.update(data: '<delete><query>*:*</query></delete>')
  end

  ##
  # @param term [String] Search term
  # @return [Array] String suggestions
  #
  def suggestions(term)
    suggestions = []
    result = get('suggest', params: { q: term })
    if result['spellcheck']
      struct = result['spellcheck']['suggestions']
      if struct.any?
        suggestions = struct[1]['suggestion']
      end
    end
    suggestions
  end

  ##
  # Creates the set of fields needed by the application. This requires
  # Solr 5.2+ with the ManagedIndexSchemaFactory enabled and a mutable schema.
  #
  def update_schema
    http = HTTPClient.new
    url = PearTree::Application.peartree_config[:solr_url].chomp('/') + '/' +
        PearTree::Application.peartree_config[:solr_core]

    response = http.get("#{url}/schema")
    current = JSON.parse(response.body)

    # delete obsolete dynamic fields
    dynamic_fields_to_delete = current['schema']['dynamicFields'].select do |cf|
      !SCHEMA['dynamicFields'].map{ |sf| sf['name'] }.include?(cf['name'])
    end
    dynamic_fields_to_delete.each do |df|
      post_fields(http, url, 'delete-dynamic-field', { 'name' => df['name'] })
    end

    # add new dynamic fields
    dynamic_fields_to_add = SCHEMA['dynamicFields'].reject do |kf|
      current['schema']['dynamicFields'].
          map{ |sf| sf['name'] }.include?(kf['name'])
    end
    post_fields(http, url, 'add-dynamic-field', dynamic_fields_to_add)

    # delete obsolete copyFields
    copy_fields_to_delete = current['schema']['copyFields'].select do |kf|
      !SCHEMA['copyFields'].map{ |sf| "#{sf['source']}#{sf['dest']}" }.
          include?("#{kf['source']}#{kf['dest']}") if SCHEMA['copyFields']
    end
    post_fields(http, url, 'delete-copy-field', copy_fields_to_delete)

    # add new copyFields
    if SCHEMA['copyFields']
      copy_fields_to_add = SCHEMA['copyFields'].reject do |kf|
        current['schema']['copyFields'].
            map{ |sf| "#{sf['source']}#{sf['dest']}" }.
            include?("#{kf['source']}#{kf['dest']}")
      end
      post_fields(http, url, 'add-copy-field', copy_fields_to_add)
    end
  end

  private

  def client
    config = PearTree::Application.peartree_config
    @client = RSolr.connect(url: config[:solr_url].chomp('/') + '/' +
        config[:solr_core]) unless @client
    @client
  end

  ##
  # @param http [HTTPClient]
  # @param url [String]
  # @param key [String]
  # @param fields [Array]
  # @raises [RuntimeError]
  #
  def post_fields(http, url, key, fields)
    if fields.any?
      json = JSON.generate({ key => fields })
      response = http.post("#{url}/schema", json,
                           { 'Content-Type' => 'application/json' })
      message = JSON.parse(response.body)
      if message['errors']
        raise "Failed to update Solr schema: #{message['errors']}"
      end
    end
  end

  ##
  # Returns a list of fields that will be copied into a "search-all" field
  # for easy searching.
  #
  # @return [Array] Array of strings
  #
  def search_all_fields
    dest = Entity::SolrFields::SEARCH_ALL
    fields = Element.all.uniq(&:name).map do |t|
      { source: t.solr_multi_valued_field, dest: dest }
    end
    fields << { source: SolrFields::FULL_TEXT, dest: dest }
    fields
  end

end
