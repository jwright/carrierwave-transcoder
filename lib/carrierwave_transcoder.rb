require_relative "carrierwave_transcoder/transcoders"

module CarrierWave
  module Transcoder
    VALID_TRANSCODERS = [:elastic_transcoder]

    def transcode_video(transcoder, options={})
      raise ArgumentError,
        "Invalid transcoder. Supported types are "\
        "#{VALID_TRANSCODERS.map { |t| t.to_s.humanize }.join(", ")}." \
        unless valid_transcoder?(transcoder)

      transcode(transcoder, options)
    end

    private

    def transcode(transcoder, options)
      klass = CarrierWave::Transcoders.const_get(transcoder.to_s.classify)
      klass.new(options).transcode
    end

    def valid_transcoder?(transcoder)
      VALID_TRANSCODERS.include?(transcoder)
    end
  end
end
