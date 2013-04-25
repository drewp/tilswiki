require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Asset, "class methods" do
  it 'should provide the storage dir when provided the page' do
    Asset.should respond_to(:storage_dir)
    Asset.storage_dir('asset_spec').should == Rails.root.join("public", "assets", 'asset_spec')
  end
end

describe Asset, "with a valid instance" do
  before :each do
    @page = 'valid_instance'
    @asset = Asset.new(@page)
    @asset.filename = 'myfile.jpg'
  end

  it "should use original file name as name" do
    @asset.name.should == @asset.filename
  end

  it "should know its version name for a given version" do
    @asset.version_name('half').should == [@asset.basename, 'half', @asset.extension].join('.')
  end

  it "should know its page asset directory" do
    @asset.page_asset_path.should == File.join('/assets', @asset.page)
  end

  it "should compute its URL" do
    @asset.url(:half).should == File.join("/assets", @asset.page, @asset.version_name(:half))
  end
end

describe Asset, "creation from uploaded tempfile" do
  before do
    @page = 'asset_spec'
    @storage_dir = Asset.storage_dir(@page)

    FileUtils.cp(Rails.root.join('spec', 'files', 'test.jpg'), '/tmp/panzer.jpg')
    @ratio = 2048 / 1536.0

    # @file = {
    #   "size"         => 877838,
    #   "content_type" => "image/jpeg",
    #   "filename"     => "panzer.jpg",
    #   "tempfile"     => File.open('/tmp/asset_spec.jpg')
    # }

    @file = Rack::Test::UploadedFile.new('/tmp/panzer.jpg', 'image/jpeg', true)

    @asset = Asset.create(@page, @file)
  end

  it "should create the storage dir" do
    File.exists?(@storage_dir).should be_true
  end

  it "should move the uploaded file to storage dir" do
    File.exists?(@storage_dir / @file['filename']).should be_true
  end

  it "should have a list of all versions with paths" do
    @asset.versions.map(&:first).should == ['thumb', 'half', 'full', 'original']
    @asset.versions.map { |v| v[1] }.should  == [
      '/assets/asset_spec/panzer.thumb.jpg',
      '/assets/asset_spec/panzer.half.jpg',
      '/assets/asset_spec/panzer.full.jpg',
      '/assets/asset_spec/panzer.jpg'
    ]
  end

  it "should create a thumb version" do
    File.exists?(@storage_dir / 'panzer.thumb.jpg').should be_true
  end

  it "should resize thumb and keep aspect ratio" do
    @thumb = Magick::Image.read(@storage_dir / 'panzer.thumb.jpg').first

    (@thumb.columns.to_f / @thumb.rows).should be_close(@ratio, 0.01)
  end

  it "should create version called half" do
    File.exists?(@storage_dir / 'panzer.half.jpg').should be_true
  end

  it "should make half version half the width of the content area" do
    Magick::Image.read(@storage_dir / 'panzer.half.jpg').first.columns.should == 350
  end

  it "keeps aspect ratio of half version" do
    @half = Magick::Image.read(@storage_dir / 'panzer.half.jpg').first

    (@half.columns.to_f / @half.rows).should be_close(@ratio, 0.01)
  end

  it "should create version called full" do
    File.exists?(@storage_dir / 'panzer.full.jpg').should be_true
  end

  it "should make full version the width of the content area" do
    Magick::Image.read(@storage_dir / 'panzer.full.jpg').first.columns.should == 700
  end

  it "keeps aspect ratio of full version" do
    @full = Magick::Image.read(@storage_dir / 'panzer.full.jpg').first

    (@full.columns.to_f / @full.rows).should be_close(@ratio, 0.01)
  end
end
