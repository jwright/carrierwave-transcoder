require "aws-sdk-elastictranscoder"

module CarrierWave
  module Transcoders
    class ElasticTranscoder
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
          thread = Thread.new do
            begin
              response = client.wait_until(:job_complete,
                                           { id: response.job.id },
                                           { delay: 10 })
              store! response
            rescue Aws::Waiters::Errors::WaiterFailed => e
              errback.call(e) unless errback.nil?
            end
          end
          thread.abort_on_exception = true
          thread
        rescue Exception => e
          errback.call(e) unless errback.nil?
        end
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

      def store!(response)
        callback.call(response) unless callback.nil?
      end
    end
  end
end
