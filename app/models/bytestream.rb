class Bytestream

  class Shape
    ORIGINAL = :original
    SQUARE = :square
  end

  class Type
    ACCESS_MASTER = :access_master
    PRESERVATION_MASTER = :preservation_master
  end

  attr_accessor :height # Integer
  attr_accessor :media_type # String
  attr_accessor :pathname # String
  attr_accessor :type # Bytestream::Type
  attr_accessor :width # Integer

  ##
  # Attempts to detect the media type and assigns it to the instance.
  #
  # @raise [RuntimeError] if pathname is not set
  #
  def detect_media_type
    if self.pathname and File.exist?(self.pathname)
      self.media_type = MIME::Types.of(self.pathname).first.to_s
    else
      raise 'Pathname not set'
    end
  end

  def is_audio?
    self.media_type and self.media_type.start_with?('audio/')
  end

  def is_image?
    self.media_type and self.media_type.start_with?('image/')
  end

  def is_pdf?
    self.media_type and self.media_type == ('application/pdf')
  end

  def is_text?
    self.media_type and self.media_type.start_with?('text/plain')
  end

  def is_video?
    self.media_type and self.media_type.start_with?('video/')
  end

  ##
  # Reads the width and height (if an image) and assigns them to the instance.
  #
  # @raise [RuntimeError] if pathname is not set
  #
  def read_dimensions
    raise 'Pathname is not set' unless self.pathname
    if self.is_image?
      glue = '|'
      # TODO: use ruby or IIIF instead
      output = `identify -format "%[fx:w]#{glue}%[fx:h]" #{self.pathname}`
      parts = output.split(glue)
      if parts.length == 2
        self.width = parts[0].strip.to_i
        self.height = parts[1].strip.to_i
      end
    end
  end

end
