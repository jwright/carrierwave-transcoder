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
        receive(:new).with(Hash).and_call_original
      expect_any_instance_of(CarrierWave::Transcoders::ElasticTranscoder).to \
        receive(:transcode)

      subject.transcode_video :elastic_transcoder, { opts: :options }
    end

    it "passes in the fog settings to the transcoder" do
      credentials = { provider: "aws",
                      aws_access_key_id: "ACCESS",
                      aws_secret_access_key: "SECRET" }
      fog_provider = "fog/aws"
      allow(subject).to receive(:fog_credentials).and_return(credentials)
      allow(subject).to receive(:fog_provider).and_return(fog_provider)

      expect(CarrierWave::Transcoders::ElasticTranscoder).to \
        receive(:new).with({ fog_provider: fog_provider,
                             fog_credentials: credentials })
        .and_call_original

      subject.transcode_video :elastic_transcoder
    end
  end
end
