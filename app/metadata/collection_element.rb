##
# Encapsulates a metadata element attached to a collection, with a name
# matching one of the persisted {Element} names.
#
class CollectionElement < EntityElement

  belongs_to :collection, inverse_of: :elements, touch: true

  ##
  # @return [Enumerable<CollectionElement>]
  #
  def self.all_available
    Element.all.map { |e| CollectionElement.new(name: e.name) }
  end

  ##
  # @return [CollectionElement] Instance with the given name, or nil if the
  #                             given name is not an available element name.
  #
  def self.named(name)
    all_available.find{ |e| e.name == name }
  end

  def ==(obj)
    obj.kind_of?(CollectionElement) && obj.name == self.name &&
        obj.value == self.value && obj.uri == self.uri &&
        obj.vocabulary_id == self.vocabulary_id
  end

end
