RSpec.describe CarrierWave::Transcoders::ElasticTranscoder do
  let(:file_options) do
    {
      basename: "user",
      content_type: "video/mp4",
      extension: "mp4",
      filename: "user.mp4",
      store_dir: "uploads"
    }
  end
  let(:fog_options) do
    {
      fog_provider: "fog/aws",
      fog_credentials: {
        provider: "AWS",
        aws_access_key_id: "ACCESS",
        aws_secret_access_key: "SECRET",
        region: "us-east-1"
      }
    }
  end
  let(:options) do
    {
      pipeline_id: "pipeline-id",
      inputs: [{
        key: "uploads/some_file.mp4"
      }],
      outputs: [{
        key: "some_smaller_file.webm",
        preset_id: "preset-id"
      }],
      output_key_prefix: "transcoded/",
      validate_params: false,
      stub_responses: true
    }
  end

  describe "#initialize" do
    it "initializes with some options" do
      expect(described_class.new(options).options).to eq options
    end

    it "defaults the inputs key with the input file" do
      options.delete(:inputs)

      subject = described_class.new(file_options.merge(options))

      expect(subject.options[:inputs][0][:key]).to eq "uploads/user.mp4"
    end

    it "defaults the outputs key with the input file and output extension" do
      options.merge!(output_extension: ".webm")
      options[:outputs][0].delete(:key)

      subject = described_class.new(file_options.merge(options))

      expect(subject.options[:outputs][0][:key]).to eq "user.webm"
      expect(subject.options[:outputs][0][:preset_id]).to eq "preset-id"
    end
  end

  describe "#transcode" do
    let(:job_id) { "BLAH" }
    let(:merged_options) { file_options.merge(fog_options.merge(options)) }

    subject { described_class.new(merged_options) }

    before do
      Aws.config[:stub_responses] = true
      allow_any_instance_of(Aws::ElasticTranscoder::Client).to \
        receive(:wait_until).and_return nil
    end

    it "creates an AWS client with the specified credentials" do
      expect(Aws::ElasticTranscoder::Client).to \
        receive(:new).with({ region: "us-east-1",
                             access_key_id: "ACCESS",
                             secret_access_key: "SECRET",
                             validate_params: false })
        .and_call_original

      subject.transcode
    end

    it "creates a job" do
      expect_any_instance_of(Aws::ElasticTranscoder::Client).to \
        receive(:create_job).with(merged_options).and_call_original

      subject.transcode
    end

    context "with a successful response" do
      xit "updates the file path"
      xit "calls the succeed callback"
    end

    context "with a failure response" do
      xit "does not update the file path"
      xit "calls the failure callback"
    end
  end
end
