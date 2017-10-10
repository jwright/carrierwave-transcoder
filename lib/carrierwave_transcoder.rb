require_relative "carrierwave_transcoder/transcoders"

module CarrierWave
  module Transcoder
    VALID_TRANSCODERS = [:elastic_transcoder]

    attr_accessor :options

    def transcode_video(transcoder, options={})
      raise ArgumentError,
        "Invalid transcoder. Supported types are "\
        "#{VALID_TRANSCODERS.map { |t| t.to_s.humanize }.join(", ")}." \
        unless valid_transcoder?(transcoder)

      self.options = { transcoder: transcoder }.merge(options)
      # We should not transcode until after the file is already on AWS
      self.class.after :store, :transcode
    end

    private

    def fog_options
      # fog_provider
      # fog_credentials -> aws_access_key_id, aws_secret_access_key, region
      # fog_directory
      # fog_attributes
      # fog_public
      # fog_authenticated_url_expiration
      # fog_use_ssl_for_aws
      # fog_aws_accelerate

      {
        fog_provider: fog_provider,
        fog_credentials: fog_credentials
      }
    end

    def transcode(_file)
      transcoder = self.options.delete(:transcoder)
      unless transcoder.nil?
        klass = CarrierWave::Transcoders.const_get(transcoder.to_s.classify)
        klass.new(fog_options.merge(options)).transcode
      end
    end

    def valid_transcoder?(transcoder)
      VALID_TRANSCODERS.include?(transcoder)
    end
  end
end
