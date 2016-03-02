module Deserialization

  def self.included(mod)
    mod.extend ClassMethods
  end

  module ClassMethods

    ##
    # @param [Nokogiri::XML::Node] node
    # @param [String] metadata_pathname
    # @return [Entity]
    # @raises [RuntimeError]
    #
    def from_lrp_xml(node, metadata_pathname)
      namespaces = {
          'lrp' => 'http://www.library.illinois.edu/lrp/terms#'
      }

      entity = self.new

      #################### technical metadata ######################

      # id
      id = node.xpath('lrp:repositoryId', namespaces).first
      entity.id = id.content.strip if id
      if !id or entity.id.blank?
        raise "lrp:repositoryId is missing or invalid for entity in "\
        "#{metadata_pathname}"
      end

      # metadata pathname
      entity.metadata_pathname = metadata_pathname

      # bib ID
      bib_id = node.xpath('lrp:bibId', namespaces).first
      entity.bib_id = bib_id ? bib_id.content.strip : nil

      # created
      created = node.xpath('lrp:created', namespaces).first
      entity.created = created ? DateTime.parse(created.content.strip) : nil

      # last modified
      last_modified = node.xpath('lrp:lastModified', namespaces).first
      entity.last_modified = last_modified ?
          DateTime.parse(last_modified.content.strip) : nil

      # published
      published = node.xpath('lrp:published', namespaces).first
      entity.published = published ?
          %w(true 1).include?(published.content.strip) : false

      # representative item ID
      rep_item_id = node.xpath('lrp:representativeItemId', namespaces).first
      entity.representative_item_id = rep_item_id.content.strip if rep_item_id

      # subclass
      subclass = node.xpath('lrp:subclass', namespaces).first
      entity.subclass = subclass ? subclass.content.strip : nil

      # web ID
      web_id = node.xpath('lrp:webId', namespaces).first
      entity.web_id = web_id ? web_id.content.strip : entity.id

      if entity.kind_of?(Item)
        # collection
        col = node.xpath('lrp:collectionId', namespaces).first
        entity.collection_id = col.content.strip if col
        if !col or entity.collection_id.blank?
          raise "lrp:collectionId is missing or invalid for item with "\
          "lrp:repositoryId #{entity.id} (#{metadata_pathname})"
        end

        # page number
        page = node.xpath('lrp:pageNumber', namespaces).first
        entity.page_number = page.content.strip.to_i if page

        # parent item
        parent = node.xpath('lrp:parentId', namespaces).first
        entity.parent_id = parent.content.strip if parent

        # access master (pathname)
        am = node.xpath('lrp:accessMasterPathname', namespaces).first
        if am
          bs = Bytestream.new
          bs.type = Bytestream::Type::ACCESS_MASTER
          bs.repository_relative_pathname = am.content.strip
          # width
          width = node.xpath('lrp:accessMasterWidth', namespaces).first
          bs.width = width.content.strip.to_i if width
          # height
          height = node.xpath('lrp:accessMasterHeight', namespaces).first
          bs.height = height.content.strip.to_i if height
          # media type
          mt = node.xpath('lrp:accessMasterMediaType', namespaces).first
          if mt
            bs.media_type = mt.content.strip
          else
            bs.detect_media_type rescue nil
          end
          entity.bytestreams << bs
        else # access master (URL)
          am = node.xpath('lrp:accessMasterURL', namespaces).first
          if am
            bs = Bytestream.new
            bs.type = Bytestream::Type::ACCESS_MASTER
            bs.url = am.content.strip
            # media type
            mt = node.xpath('lrp:accessMasterMediaType', namespaces).first
            if mt
              bs.media_type = mt.content.strip
            else
              bs.detect_media_type rescue nil
            end
            entity.bytestreams << bs
          end
        end

        # full text
        id = node.xpath('lrp:fullText', namespaces).first
        entity.full_text = id.content.strip if id

        # preservation master (pathname)
        pm = node.xpath('lrp:preservationMasterPathname', namespaces).first
        if pm
          bs = Bytestream.new
          bs.type = Bytestream::Type::PRESERVATION_MASTER
          bs.repository_relative_pathname = pm.content.strip
          mt = node.xpath('lrp:preservationMasterMediaType', namespaces).first
          if mt
            bs.media_type = mt.content.strip
          else
            bs.detect_media_type rescue nil
          end
          entity.bytestreams << bs
        else # preservation master (URL)
          pm = node.xpath('lrp:preservationMasterURL', namespaces).first
          if pm
            bs = Bytestream.new
            bs.type = Bytestream::Type::ACCESS_MASTER
            bs.url = pm.content.strip
            # width
            width = node.xpath('lrp:preservationMasterWidth', namespaces).first
            bs.width = width.content.strip.to_i if width
            # height
            height = node.xpath('lrp:preservationMasterHeight', namespaces).first
            bs.height = height.content.strip.to_i if height
            # media type
            mt = node.xpath('lrp:preservationMasterMediaType', namespaces).first
            if mt
              bs.media_type = mt.content.strip
            else
              bs.detect_media_type rescue nil
            end
            entity.bytestreams << bs
          end
        end
      end

      # subpage number
      page = node.xpath('lrp:subpageNumber', namespaces).first
      entity.subpage_number = page.content.strip.to_i if page

      #################### descriptive metadata ######################

      # normalized date
      date = node.xpath('lrp:date', namespaces).first
      if date
        # TODO: gonna have to parse this carefully
        #entity.date = Date.parse(date.content.strip)
      end

      # everything else
      descriptive_elements = Element.all.
          select{ |e| e.type == Element::Type::DESCRIPTIVE }.map(&:name)
      md_nodes = node.xpath('lrp:*', namespaces)
      md_nodes.each do |md_node|
        if descriptive_elements.include?(md_node.name)
          e = Element.named(md_node.name)
          e.value = md_node.content.strip
          entity.metadata << e
        end
      end

      entity.instance_variable_set('@persisted', true)
      entity
    end

  end

end
