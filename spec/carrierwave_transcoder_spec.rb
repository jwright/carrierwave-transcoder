RSpec.describe CarrierWave::Transcoder do
  class DummyVideoUploader < CarrierWave::Uploader::Base
    include CarrierWave::Transcoder
  end

  subject { DummyVideoUploader.new }

  describe "#transcode_video" do
    it "requires a valid transcoder" do
      expect { subject.transcode_video :blah }.to raise_error ArgumentError
    end

    it "transcodes video with the specified transcoder" do
      expect(CarrierWave::Transcoders::ElasticTranscoder).to \
        receive(:new).with(:opts).and_call_original
      expect_any_instance_of(CarrierWave::Transcoders::ElasticTranscoder).to \
        receive(:transcode)

      subject.transcode_video :elastic_transcoder, :opts
    end

    xit "cannot transcode non-supported media"
  end
end
