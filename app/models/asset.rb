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
        img.scale(x, y).write(storage_path(version))
      end
    end
  end

  # Array with one array for each version: [version, path, width, height]
  def versions
    versions = VERSIONS.map(&:first).map do |version|
      # file = "#{storage_dir}/#{basename}.#{version}.#{extension}"
      file = File.join(storage_dir, version_name(version))

      if File.exist?(file)
        image = Magick::Image.read(file).first
        [version, url(version), image.columns, image.rows]
      else
        nil
      end
    end.compact

    image = Magick::Image.read("#{storage_dir}/#{basename}.#{extension}").first
    versions << ['original', url(:original), image.columns, image.rows]
  end

  def name
    @filename
  end

  def url(version)
    "#{page_asset_path}/#{version_name(version)}"
  end

  def original
    @original ||= Magick::Image.read(storage_path(:original)).first
  end

  def storage_dir
    self.class.storage_dir(page)
  end

  def page_asset_path
    File.join('', 'assets', page)
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
    version.to_s == 'original' ? filename : "#{basename}.#{version}.#{extension}"
  end

  def storage_path(version)
    File.join(storage_dir, version_name(version))
  end
end
