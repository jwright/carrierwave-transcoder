require_relative "carrierwave_transcoder/transcoders"

module CarrierWave
  module Transcoder
    VALID_TRANSCODERS = [:elastic_transcoder]

    attr_accessor :options

    def transcode_video(*args)
      options = args.to_h
      transcoder = options.fetch(:transcoder)

      raise ArgumentError,
        "Invalid transcoder. Supported types are "\
        "#{VALID_TRANSCODERS.map { |t| t.to_s.humanize }.join(", ")}." \
        unless valid_transcoder?(transcoder)

      self.options = options
      # We should not transcode until after the file is already on AWS
      self.class.after :store, :transcode
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
      transcoder = self.options.delete(:transcoder)
      unless transcoder.nil?
        klass = CarrierWave::Transcoders.const_get(transcoder.to_s.classify)
        klass.new(self, file_options.merge(options)).transcode
      end
    end

    def valid_transcoder?(transcoder)
      VALID_TRANSCODERS.include?(transcoder)
    end
  end
end
