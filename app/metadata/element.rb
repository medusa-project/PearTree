##
# Application element archetype. This is a way of expressing a certain set of
# elements that are available for use in the application. This class in
# particular has no relationships, but {MetadataProfileElement}s and
# {ItemElement}s (for example) can only be created if there is an {Element}
# with a matching name present. If that {Element} is later renamed or deleted,
# the corresponding {MetadataProfileElement}s and {ItemElement}s are not
# affected, which is a safety feature.
#
# # Attributes
#
# * `created_at`  Managed by ActiveRecord.
# * `description` Optional information about the element.
# * `name`        Element name.
# * `updated_at`  Managed by ActiveRecord.
#
class Element < ApplicationRecord

  validates :name, presence: true, format: { with: /\A[-a-zA-Z0-9]+\Z/ },
            uniqueness: { case_sensitive: false }

  before_update :restrict_name_changes
  before_destroy :restrict_delete_of_used_elements

  ##
  # @param struct [Hash] Deserialized JSON structure.
  # @return [Element] New non-persisted instance.
  #
  def self.from_json_struct(struct)
    e = Element.new
    e.update_from_json_struct(struct)
    e
  end

  ##
  # @return [Integer]
  #
  def num_usages_by_items
    ItemElement.where(name: self.name).count
  end

  ##
  # @return [Integer]
  #
  def num_usages_by_metadata_profiles
    MetadataProfileElement.where(name: self.name).count
  end

  def to_param
    self.name
  end

  def update_from_json_struct(struct)
    self.name = struct['name']
    self.description = struct['description']
    self.save!
  end

  ##
  # Returns an Enumerable of all usages of a given element by all items.
  #
  # @return [Enumerable<String>] of hashes with `collection_id`, `item_id`,
  #                              `element_name, `element_value`, and
  #                              `element_uri` keys.
  #
  def usages
    sql = "SELECT collections.repository_id AS collection_id,
          items.repository_id AS item_id, entity_elements.name,
          entity_elements.value, entity_elements.uri
        FROM entity_elements
        LEFT JOIN items ON entity_elements.item_id = items.id
        LEFT JOIN collections ON collections.repository_id = items.collection_repository_id
        LEFT JOIN metadata_profiles ON metadata_profiles.id = collections.metadata_profile_id
        LEFT JOIN metadata_profile_elements ON metadata_profile_elements.metadata_profile_id = metadata_profiles.id
        WHERE entity_elements.item_id IS NOT NULL
          AND entity_elements.name = $1
          AND collections.public_in_medusa = true
          AND metadata_profile_elements.name = $2
        ORDER BY collection_id, item_id, entity_elements.name,
          entity_elements.value ASC"
    values = [[nil, self.name], [nil, self.name]]
    ActiveRecord::Base.connection.exec_query(sql, 'SQL', values)
  end


  private

  ##
  # Disallows instances with any uses from being destroyed.
  #
  def restrict_delete_of_used_elements
    self.num_usages_by_items == 0 and self.num_usages_by_metadata_profiles == 0
  end

  ##
  # Disallows the name from being changed.
  #
  def restrict_name_changes
    self.name_was == self.name
  end

end
