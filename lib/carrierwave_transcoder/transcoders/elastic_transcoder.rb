require "aws-sdk-elastictranscoder"
require "active_record"
require "carrierwave/utilities/uri"

module CarrierWave
  module Transcoders
    class ElasticTranscoder
      include CarrierWave::Utilities::Uri

      attr_accessor :callback, :errback
      attr_reader :options, :uploader

      def initialize(uploader, options, callback=nil, errback=nil)
        @uploader = uploader
        @options = default_options_with(options.symbolize_keys)
        @callback = callback
        @errback = errback
      end

      def transcode
        begin
          response = client.create_job(options)
          Thread.new do
            begin
              response = client.wait_until(:job_complete,
                                           { id: response.job.id },
                                           { delay: 10 })
              store! response
            rescue Aws::Waiters::Errors::WaiterFailed => e
              errback.call(e) unless errback.nil?
            end
          end
        rescue Exception => e
          errback.call(e) unless errback.nil?
        end
      end

      def validate!
        response = client.read_pipeline(id: options[:pipeline_id])
        bucket = response.pipeline.output_bucket ||
          response.pipeline.content_config.bucket
        raise RuntimeError,
              "Output setting in pipeline must match fog directory." \
              unless bucket == uploader.fog_directory
        true
      end

      private

      def client
        @client ||= Aws::ElasticTranscoder::Client.new \
          region: uploader.fog_credentials[:region],
          access_key_id: uploader.fog_credentials[:aws_access_key_id],
          secret_access_key: uploader.fog_credentials[:aws_secret_access_key],
          validate_params: options[:validate_params]
      end

      def default_options_with(options)
        store_dir = uploader.store_dir || ""
        store_dir += "/" unless store_dir.end_with?("/")
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
        end.merge(output_key_prefix: store_dir)
      end

      def store!(response)
        filename = encode_path(response.job.output.key)
        column = uploader.mounted_as
        unless uploader.model.update_column column, filename
          error = ::ActiveRecord::RecordNotSaved
            .new("Failed to update #{column}", uploader.model)
          errback.call(error) unless errback.nil?
        else
          callback.call(response) unless callback.nil?
        end
      end
    end
  end
end
