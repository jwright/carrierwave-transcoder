require "aws-sdk-elastictranscoder"

module CarrierWave
  module Transcoders
    class ElasticTranscoder
      attr_reader :options

      def initialize(options)
        @options = default_options_with(options.symbolize_keys)
      end

      def transcode
        response = client.create_job(options)
        client.wait_until(:job_complete, { id: response.job.id }, { delay: 10 })
      end

      private

      def client
        @client ||= Aws::ElasticTranscoder::Client.new \
          region: options[:fog_credentials][:region],
          access_key_id: options[:fog_credentials][:aws_access_key_id],
          secret_access_key: options[:fog_credentials][:aws_secret_access_key],
          validate_params: options[:validate_params]
      end

      def default_options_with(options)
        {
          inputs: [{
            key: "#{options[:store_dir]}/#{options[:filename]}"
          }],
          outputs: [{
            key: "#{options[:basename]}#{options[:output_extension]}"
          }]
        }.merge(options) do |key, old_value, new_value|
          if options[key].is_a?(Array)
            [(old_value + new_value).reduce(Hash.new, :merge)]
          else
            new_value
          end
        end
      end
    end
  end
end
