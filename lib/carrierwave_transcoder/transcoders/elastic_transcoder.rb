module CarrierWave
  module Transcoders
    class ElasticTranscoder
      attr_reader :options

      def initialize(options)
        @options = default_options_with(options.symbolize_keys)
      end

      def transcode
      end

      private

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
