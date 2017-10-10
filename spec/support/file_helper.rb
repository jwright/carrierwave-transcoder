require "rack/test"

module Spec
  module Helpers
    module FileHelper
      def fixture_file(file, type="image/jpg")
        Rack::Test::UploadedFile.new(
          fixture_file_path(file), type)
      end

      def fixture_file_path(file)
        File.join("./spec", "fixtures", "files", file)
      end
    end
  end
end
