RSpec.describe CarrierWave::Transcoder do
  class DummyVideoUploader < CarrierWave::Uploader::Base
    include CarrierWave::Transcoder
  end

  subject { DummyVideoUploader.new }

  describe "#transcode_video" do
    it "requires a valid transcoder" do
      expect { subject.transcode_video :blah }.to raise_error ArgumentError
    end

    xit "transcodes video with the specified transcoder"
    xit "cannot transcode non-supported media"
  end
end
