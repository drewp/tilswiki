class Asset
  VERSIONS = [['thumb', '100'], ['half', '350'], ['full', '700']]
  attr_accessor :filename, :page

  def self.create(page, file)
    asset = Asset.new(page, file.original_filename)

    Dir.mkdir(asset.storage_dir) unless Dir.exists?(asset.storage_dir)
    FileUtils.mv(file.path, asset.storage_path(:original))
    asset.create_versions!

    return asset
  end

  def self.delete_all(page)
    FileUtils.rm_rf(storage_dir(page))
  end

  def self.storage_dir(page)
    Rails.root.join("public", "assets", page)
  end

  def initialize(page, filename = nil)
    @page = page
    @filename = filename
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
      file = storage_path(version)

      if File.exist?(file)
        image = Magick::Image.read(file).first
        [version, url(version), image.columns, image.rows]
      else
        nil
      end
    end.compact

    image = original
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
    File.extname(filename)[1..-1]
  end

  def basename
    File.basename(filename, '.*')
  end

  def version_name(version)
    version.to_s == 'original' ? filename : "#{basename}.#{version}.#{extension}"
  end

  def storage_path(version)
    File.join(storage_dir, version_name(version))
  end
end
