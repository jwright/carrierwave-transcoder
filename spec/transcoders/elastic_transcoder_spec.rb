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
  let(:fog_credentials) do
    {
      provider: "AWS",
      aws_access_key_id: "ACCESS",
      aws_secret_access_key: "SECRET",
      region: "us-east-1"
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
  let(:uploader) { double(:uploader, fog_credentials: fog_credentials) }

  describe "#initialize" do
    it "initializes with the uploader" do
      expect(described_class.new(uploader, options).uploader).to eq uploader
    end

    it "initializes with some options" do
      expect(described_class.new(uploader, options).options).to eq options
    end

    it "defaults the inputs key with the input file" do
      options.delete(:inputs)

      subject = described_class.new(uploader, file_options.merge(options))

      expect(subject.options[:inputs][0][:key]).to eq "uploads/user.mp4"
    end

    it "defaults the outputs key with the input file and output extension" do
      options.merge!(output_extension: ".webm")
      options[:outputs][0].delete(:key)

      subject = described_class.new(uploader, file_options.merge(options))

      expect(subject.options[:outputs][0][:key]).to eq "user.webm"
      expect(subject.options[:outputs][0][:preset_id]).to eq "preset-id"
    end
  end

  describe "#transcode" do
    let(:job_id) { "BLAH" }
    let(:merged_options) { file_options.merge(options) }
    let(:response) { {} }

    subject do
      described_class.new(uploader, merged_options, @callback, @errback)
    end

    before do
      Aws.config[:stub_responses] = true
      allow_any_instance_of(Aws::ElasticTranscoder::Client).to \
        receive(:wait_until).and_return response
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

      it "calls the succeed callback" do
        @callback = Proc.new { |response| @response = response }

        expect(@callback).to receive(:call).and_call_original

        subject.transcode.join

        expect(@response).to eq response
      end
    end

    context "with a failure response" do
      before do
        allow_any_instance_of(Aws::ElasticTranscoder::Client).to \
          receive(:wait_until).and_raise Aws::Waiters::Errors::WaiterFailed
      end

      xit "does not update the file path"

      it "calls the failure callback" do
        @errback = Proc.new { |e| @error = e }

        expect(@errback).to receive(:call).and_call_original

        subject.transcode.join

        expect(@error).to be_instance_of Aws::Waiters::Errors::WaiterFailed
      end
    end
  end
end
