##
# Converts images using the IIIF image server.
#
class IiifImageConverter

  @@logger = CustomLogger.instance

  ##
  # Converts a single image binary to the given format and writes it as a file
  # in the given directory.
  #
  # @param binary [Binary]
  # @param directory [String] Directory pathname in which to create the new
  #                           image.
  # @param format [Symbol] IIIF image format extension.
  # @return [String] Pathname of the converted image.
  #
  def convert_binary(binary, directory, format)
    format = format.to_s
    if binary.media_type == 'image/jpeg'
      # The binary is already a JPEG, so just download it.
      new_pathname = directory + '/' + binary.object_key

      @@logger.debug("ImageConverter.convert_binary(): downloading "\
          "#{binary.object_key} to #{new_pathname}")

      FileUtils.mkdir_p(File.dirname(new_pathname))

      Aws::S3::Client.new.get_object(
          bucket: Configuration.instance.medusa_s3_bucket,
          key: binary.object_key,
          response_target: new_pathname)
      return new_pathname
    elsif binary.is_image?
      format.gsub!('.', '')
      new_pathname = directory + '/' +
          binary.object_key.split('.')[0...-1].join('.') +
          '.' + format

      if binary.iiif_safe?
        # ?cache=false is supported by Cantaloupe to help reduce the cache size.
        url = binary.iiif_image_url + '/full/full/0/default.' + format +
            '?cache=false'

        @@logger.debug("Creating #{new_pathname}")
        FileUtils.mkdir_p(File.dirname(new_pathname))

        File.open(new_pathname, 'wb') do |file|
          @@logger.info("Downloading #{url} to #{new_pathname}")
          ImageServer.instance.client.get_content(url) do |chunk|
            file.write(chunk)
          end
        end
        return new_pathname
      else
        @@logger.info("ImageConverter.convert_binary(): #{binary} will bog "\
            "down the image server; skipping.")
      end
    else
      @@logger.debug("ImageConverter.convert_binary(): #{binary} is not an "\
          "image; skipping.")
    end
  end

  ##
  # Converts all relevant image binaries associated with an item (or its
  # children, depending on what kind of item it is) to the given format and
  # writes them as files in the given directory.
  #
  # @param item [Item]
  # @param directory [String] Directory pathname in which to create the new
  #                           images.
  # @param format [Symbol] IIIF image format extension.
  # @param task [Task] Supply to receive progress updates.
  # @return [void]
  #
  def convert_images(item, directory, format, task = nil)
    # If the item is a directory variant, convert all of the files within it,
    # at any level in the tree.
    if item.variant == Item::Variants::DIRECTORY
      item.all_files.each do |file|
        file.binaries.each do |bin| # there should be only one
          convert_binary(bin, directory, format)
        end
      end
    # If the item has any child items, convert those.
    elsif item.items.any?
      item.items.each do |subitem|
        binaries = subitem.binaries.where(
            master_type: Binary::MasterType::ACCESS,
            media_category: Binary::MediaCategory::IMAGE)
        count = binaries.count
        binaries.each_with_index do |bin, index|
          task&.progress = index / count.to_f
          convert_binary(bin, directory, format)
        end
      end
    # The item has no child items, so it's likely either standalone or a file
    # variant.
    else
      binaries = item.binaries.where(
          master_type: Binary::MasterType::ACCESS,
          media_category: Binary::MediaCategory::IMAGE)
      count = binaries.count
      binaries.each_with_index do |bin, index|
        task&.progress = index / count.to_f
        convert_binary(bin, directory, format)
      end
    end
    task&.succeeded
  end

end