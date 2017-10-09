module CarrierWave
  module Transcoder
    VALID_TRANSCODERS = [:elastic_transcoder]

    def transcode_video(transcoder, options={})
      raise ArgumentError,
        "Invalid transcoder. Supported types are "\
        "#{VALID_TRANSCODERS.join(", ")}."
    end
  end
end
