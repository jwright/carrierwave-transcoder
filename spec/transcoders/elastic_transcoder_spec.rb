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
      output_key_prefix: "transcoded/"
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
  end
end
