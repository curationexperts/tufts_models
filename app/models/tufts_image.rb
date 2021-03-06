class TuftsImage < TuftsBase
  has_file_datastream 'Thumbnail.png', control_group: 'E', versionable: false
  has_file_datastream 'Archival.tif', control_group: 'E', versionable: false, default: true
  has_file_datastream 'Advanced.jpg', control_group: 'E', versionable: false
  has_file_datastream 'Basic.jpg', control_group: 'E', versionable: false

  include CollectionMember

  def self.default_content_ds
    'Basic.jpg'
  end

  def create_derivatives
    create_advanced
    create_basic
    create_thumbnail
  end

  # Advanced Datastream
  #   The advanced datastream is a high-resolution jpeg file used in the advanced image viewer in the TDL. The advanced datastream is used to generate the basic and thumbnail datastreams.
  #   Format: jpg, high quality (8/12) -- or 69/100
  #   Resolution: Same as archival datastream.
  #   Colorspace: Same as archival datastream.
  #   Pixel dimensions: Same as archival datastream, unless the resulting file is greater than 1 MB. If smaller files are required, set the size of the long side of the image to 1200 pixels.
  def create_advanced
    image_service = ImageGeneratingService.new(self, 'Advanced.jpg', 'image/jpeg', 69)
    output_path = image_service.generate
    original_size_mb = File.size(output_path).to_f / 2**20
    if original_size_mb > 1.0
      image_service.generate_resized(1200)
    end
  end


  # Basic Datastream
  #   The basic datastream is a medium-size jpeg used in the TDL interface. It is derived from the advanced datastream.
  #   Format: jpg, maximum quality (12/12) -- or 100/100
  #   Resolution: Same as archival datastream
  #   Colorspace: Same as archival datastream
  #   Pixel dimensions: All basic datastreams MUST be 600 pixels on the long side of the image for proper display in the TDL.
  def create_basic
    ImageGeneratingService.new(self, 'Basic.jpg', 'image/jpeg', 100).generate_resized(600)
  end

  # Thumbnail Datastream
  #   The thumbnail datastream is a small-size png used in the TDL interface and search results displays.
  #   Format: png, maximum quality (12) -- or 100/100
  #   Resolution: Same as archival datastream
  #   Colorspace: Same as archival datastream
  #   Pixel dimensions: All thumbnail datastream images MUST be 120 pixels on the long side of the image for proper display in the TDL.
  def create_thumbnail
    ImageGeneratingService.new(self, 'Thumbnail.png', 'image/png').generate_resized(120)
  end

  def has_thumbnail?
    true
  end

  def self.to_class_uri
    'info:fedora/cm:Image.4DS'
  end

  # @param [String] dsid Datastream id
  # @param [String] type the content type to test
  # @return [Boolean] true if type is a valid mime type for image
  def valid_type_for_datastream?(dsid, type)
    %Q{image/tif image/x-tif image/tiff image/x-tiff application/tif application/x-tif application/tiff application/x-tiff}.include?(type)
  end
end
