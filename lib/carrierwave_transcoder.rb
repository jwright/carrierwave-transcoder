require_relative "carrierwave_transcoder/transcoders"

module CarrierWave
  module Transcoder
    extend ActiveSupport::Concern

    VALID_TRANSCODERS = [:elastic_transcoder]

    attr_accessor :options

    included do
      after :store, :transcode
    end

    def transcode_video(*args)
      options = args.to_h
      transcoder_type = options.fetch(:transcoder)

      raise ArgumentError,
        "Invalid transcoder. Supported types are "\
        "#{VALID_TRANSCODERS.map { |t| t.to_s.humanize }.join(", ")}." \
        unless valid_transcoder?(transcoder_type)

      self.options = options
    end

    private

    def file_options
      {
        basename: sanitized_file.basename,
        content_type: sanitized_file.content_type,
        extension: sanitized_file.extension,
        filename: sanitized_file.filename,
        store_dir: store_dir
      }
    end

    def transcode(_file)
      transcoder.validate!
      transcoder.transcode
    end

    def transcoder_class
      transcoder = options.delete(:transcoder)
      unless transcoder.nil?
        klass = CarrierWave::Transcoders.const_get(transcoder.to_s.classify)
      end
    end

    def transcoder
      @transcoder ||= transcoder_class.new(self, file_options.merge(options))
    end

    def valid_transcoder?(transcoder)
      VALID_TRANSCODERS.include?(transcoder)
    end
  end
end
