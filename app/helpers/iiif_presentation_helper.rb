module IiifPresentationHelper

  MIN_CANVAS_SIZE = 1200

  ##
  # @param subitem [Item] Subitem or page
  # @return [Hash<Symbol,Object>]
  #
  def iiif_canvas_for(subitem)
    struct = {
        '@id': item_iiif_canvas_url(subitem, subitem.repository_id),
        '@type': 'sc:Canvas',
        label: subitem.title,
        height: canvas_height(subitem),
        width: canvas_width(subitem),
        metadata: iiif_metadata_for(subitem)
    }
    struct[:images] = iiif_images_for(subitem, 'access') if subitem.is_image?
    struct
  end

  ##
  # @param item [Item]
  # @return [Array]
  #
  def iiif_canvases_for(item)
    items = item.items_in_iiif_presentation_order.to_a
    if items.any?
      return items.map { |subitem| iiif_canvas_for(subitem) }
    else
      return [ iiif_canvas_for(item) ]
    end
  end

  ##
  # @param item [Item]
  # @param annotation_name [String] 'access' or 'preservation'
  # @return [Array]
  #
  def iiif_images_for(item, annotation_name)
    images = []
    bs = item.access_master_binary || item.preservation_master_binary
    if bs
      images << {
          '@type': 'oa:Annotation',
          '@id': item_iiif_annotation_url(item, annotation_name),
          motivation: 'sc:painting',
          resource: {
              '@id': iiif_image_url(item, 1000),
              '@type': 'dctypes:Image',
              'format': bs.media_type,
              service: {
                  '@context': 'http://iiif.io/api/image/2/context.json',
                  '@id': bs.iiif_image_url,
                  profile: 'http://iiif.io/api/image/2/profiles/level2.json'
              },
              height: bs.height,
              width: bs.width
          },
          on: item_iiif_canvas_url(item, item.repository_id)
      }
    end
    images
  end

  ##
  # @param item [Item]
  # @return [Array]
  #
  def iiif_media_sequences_for(item)
    if item.variant == Item::Variants::FILE and item.is_pdf?
      sequences = [
          {
              '@id': item_iiif_media_sequence_url(item, :page),
              '@type': 'ixif:MediaSequence',
              label: 'XSequence 0',
              elements: [
                  '@id': item_access_master_binary_url(item),
                  '@type': 'foaf:Document',
                  format: item.access_master_binary.media_type,
                  label: item.title,
                  metadata: [],
                  thumbnail: thumbnail_url(item)
              ]
          }
      ]
    end
    sequences
  end

  ##
  # @param item [Item]
  # @return [Array]
  #
  def iiif_metadata_for(item)
    elements = []
    item.collection.metadata_profile.elements.select(&:visible).each do |pe|
      item_elements = item.elements.
          select{ |ie| ie.name == pe.name and ie.value.present? }
      if item_elements.any?
        elements << {
            label: pe.label,
            value: item_elements.length > 1 ?
                item_elements.map(&:value) : item_elements.first.value
        }
      end
    end
    elements
  end

  ##
  # @param item [Item] Compound object
  # @param variant [String] One of the Item::Variants constant values
  # @return [Hash]
  #
  def iiif_range_for(item, variant)
    subitem = item.items.where(variant: variant).first
    {
        '@id': item_iiif_range_url(item, variant),
        '@type': 'sc:Range',
        label: subitem.title,
        canvases: [ item_iiif_canvas_url(subitem, subitem.repository_id) ]
    }
  end

  ##
  # @param item [Item]
  # @return [Array]
  # @see http://iiif.io/api/presentation/2.1/#range
  #
  def iiif_ranges_for(item)
    ranges = item.items.where('variant NOT IN (?)', [Item::Variants::PAGE]).map do |subitem|
      iiif_range_for(item, subitem.variant)
    end

    top_range = ranges.select{ |r| r[:label] == Item::Variants::TITLE.titleize }.first ||
        ranges.select{ |r| r[:label] == Item::Variants::TABLE_OF_CONTENTS.titleize }.first
    top_range[:viewingHint] = 'top' if top_range

    ranges
  end

  ##
  # @param item [Item]
  # @return [Array]
  #
  def iiif_sequences_for(item)
    # If the item has any pages, they will comprise the sequences.
    if item.pages.count > 0
      sequences = [
          {
              '@id': item_iiif_sequence_url(item, :page),
              '@type': 'sc:Sequence',
              label: 'Pages',
              viewingHint: 'paged',
              canvases: iiif_canvases_for(item)
          }
      ]
    # Otherwise, if it has any items of any variant, they will comprise the
    # sequences.
    elsif item.items.count > 0
      sequences = [
          {
             '@id': item_iiif_sequence_url(item, :item),
             '@type': 'sc:Sequence',
             label: 'Sub-Items',
             canvases: iiif_canvases_for(item)
          }
      ]
    # Otherwise, the item itself will comprise its sequence.
    else
      sequences = [
          {
              '@id': item_iiif_sequence_url(item, :item),
              '@type': 'sc:Sequence',
              label: item.title,
              canvases: iiif_canvases_for(item)
          }
      ]
    end
    sequences
  end

  private

  def canvas_height(item)
    bs = item.access_master_binary || item.preservation_master_binary
    height = bs&.height || MIN_CANVAS_SIZE
    height = MIN_CANVAS_SIZE if height < MIN_CANVAS_SIZE
    height
  end

  def canvas_width(item)
    bs = item.access_master_binary || item.preservation_master_binary
    width = bs&.width || MIN_CANVAS_SIZE
    width = MIN_CANVAS_SIZE if width < MIN_CANVAS_SIZE
    width
  end

end
