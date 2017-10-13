RSpec.describe CarrierWave::Transcoders::ElasticTranscoder do
  let(:file_options) do
    {
      basename: "user",
      content_type: "video/mp4",
      extension: "mp4",
      filename: "user.mp4",
      store_dir: store_dir
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
  let(:fog_directory) { "my-directory" }
  let(:merged_options) { file_options.merge(options) }
  let(:options) do
    {
      pipeline_id: pipeline_id,
      inputs: [{
        key: "uploads/some_file.mp4"
      }],
      outputs: [{
        key: "some_smaller_file.webm",
        preset_id: "preset-id"
      }],
      validate_params: false,
      stub_responses: true
    }
  end
  let(:pipeline_id) { "pipeline-id" }
  let(:store_dir) { "uploads" }
  let(:uploader) do
    double(:uploader, fog_credentials: fog_credentials,
                      fog_directory: fog_directory,
                      store_dir: store_dir)
  end

  describe "#initialize" do
    it "initializes with the uploader" do
      expect(described_class.new(uploader, options).uploader).to eq uploader
    end

    it "initializes with some options" do
      expect(described_class.new(uploader, options).options).to \
        eq options.merge(output_key_prefix: "#{store_dir}/")
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

    it "overwrites the output key prefix with the store directory" do
      subject = described_class.new(uploader, file_options.merge(options))

      expect(subject.options[:output_key_prefix]).to eq "#{store_dir}/"
    end
  end

  describe "#transcode" do
    let(:job_id) { "BLAH" }
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
        receive(:create_job).with(hash_including(merged_options))
          .and_call_original

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

  describe "#validate!" do
    let(:response) do
      {
        pipeline: {
          id: pipeline_id,
          name: "transcoder",
          output_bucket: nil,
          content_config: {
            bucket: nil
          }
        }
      }
    end

    subject { described_class.new(uploader, merged_options) }

    before do
      allow_any_instance_of(Aws::ElasticTranscoder::Client).to \
        receive(:read_pipeline)
          .with(id: pipeline_id)
          .and_return response_struct
    end

    context "when the output pipeline does not match the fog directory" do
      let(:response_struct) do
        response[:pipeline][:content_config].merge!(bucket: "blah")
        JSON.parse(response.to_json, object_class: OpenStruct)
      end

      it "raises an error" do
        expect { subject.validate! }.to \
          raise_error RuntimeError,
            "Output setting in pipeline must match fog directory."
      end
    end

    context "when the output pipeline does match the fog directory" do
      let(:response_struct) do
        response[:pipeline][:content_config].merge!(bucket: fog_directory)
        JSON.parse(response.to_json, object_class: OpenStruct)
      end

      it "returns true" do
        expect(subject.validate!).to be_truthy
      end
    end
  end
end
