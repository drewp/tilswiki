class Asset
  VERSIONS = [['thumb', '100'], ['half', '350'], ['full', '700']]
  attr_accessor :filename, :page

  def self.create(page, file)
    asset = Asset.new(page)
    asset.filename = file.original_filename

    dir = asset.storage_dir

    FileUtils.mkdir(dir) unless File.exists?(dir)

    FileUtils.mv(file.path, File.join(dir, asset.filename))
    asset.create_versions!

    return asset
  end

  def self.delete_all(page)
    FileUtils.rm_rf(storage_dir(page))
  end

  def self.storage_dir(page)
    Rails.root.join("public", "assets", page)
  end

  def initialize(page)
    @page = page
  end

  def create_versions!
    VERSIONS.each do |version, geometry|
      original.change_geometry(geometry) do |x, y, img|
        img.scale(x, y).write(storage_dir / version_name(version))
      end
    end
  end

  # Array with one array for each version: [version, path, width, height]
  def versions
    versions = VERSIONS.map(&:first).map do |version|
      file = "#{storage_dir}/#{basename}.#{version}.#{extension}"
      if File.exist?(file)
        image = Magick::Image.read(file).first
        [version, "/assets/#{@page}/#{basename}.#{version}.#{extension}", image.columns, image.rows]
      else
        nil
      end
    end.compact

    image = Magick::Image.read("#{storage_dir}/#{basename}.#{extension}").first
    versions << ['original', "/assets/#{@page}/#{basename}.#{extension}", image.columns, image.rows]
  end

  def name
    @filename
  end

  def url(version)
    "/assets/#{@page}/#{basename}.#{version.to_s}.#{extension}"
  end

  def original
    @original ||= Magick::Image.read(storage_dir / @filename).first
  end

  def storage_dir
    Rails.root.join("public", "assets", @page)
  end

  def extension
    # TODO: delegate to some File method
    @filename =~ /\.(.+)$/ && $1
  end

  def basename
    # TODO: use File.basename
    @filename =~ /^(.+)\./ && $1
  end

  def version_name(version)
    "#{basename}.#{version}.#{extension}"
  end
end
