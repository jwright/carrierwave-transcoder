RSpec.describe CarrierWave::Transcoder do
  include Spec::Helpers::FileHelper

  class DummyVideoUploader < CarrierWave::Uploader::Base
    include CarrierWave::Transcoder
  end

  let(:credentials) do
    {
      provider: "aws",
      aws_access_key_id: "ACCESS",
      aws_secret_access_key: "SECRET",
      region: "us-east-1"
    }
  end
  let(:file) { fixture_file("user.mp4", "video/mp4") }

  subject { DummyVideoUploader.new }

  describe "#transcode_video" do
    before do
      allow_any_instance_of(CarrierWave::Transcoders::ElasticTranscoder).to \
        receive_messages(transcode: nil, validate!: true)
    end

    after { subject.remove! }

    it "requires a valid transcoder" do
      expect { subject.transcode_video [:transcoder, :blah] }.to \
        raise_error ArgumentError
    end

    it "transcodes video with the specified transcoder after it is stored" do
      subject.transcode_video [:transcoder, :elastic_transcoder],
                              [:opts, :options]

      expect(CarrierWave::Transcoders::ElasticTranscoder).to \
        receive(:new).with(subject, Hash).and_call_original
      expect_any_instance_of(CarrierWave::Transcoders::ElasticTranscoder).to \
        receive(:transcode)

      subject.store! file
    end

    it "sets the options on the transcoder" do
      subject.transcode_video [:transcoder, :elastic_transcoder],
                              [:opts, :options]

      expect(subject.options).to eq({ transcoder: :elastic_transcoder,
                                      opts: :options })
    end

    it "passes in the file settings to the transcoder" do
      allow(subject).to receive(:fog_credentials).and_return(credentials)

      subject.transcode_video [:transcoder, :elastic_transcoder]

      expect(CarrierWave::Transcoders::ElasticTranscoder).to \
        receive(:new).with(subject, hash_including({ basename: "user",
                                                     content_type: "video/mp4",
                                                     extension: "mp4",
                                                     filename: "user.mp4",
                                                     store_dir: "uploads" }))
        .and_call_original

      subject.store! file
    end

    it "validates the options with the transcoder" do
      subject.transcode_video [:transcoder, :elastic_transcoder]

      expect_any_instance_of(CarrierWave::Transcoders::ElasticTranscoder).to \
        receive(:validate!).at_least(:once)

      subject.store! file
    end

    it "transcodes videos after it saves it to AWS" do
      expect(subject._after_callbacks[:store]).to include :transcode
    end
  end
end
