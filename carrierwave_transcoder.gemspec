# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "carrierwave_transcoder/version"

Gem::Specification.new do |spec|
  spec.name          = "carrierwave_transcoder"
  spec.version       = CarrierWave::Transcoder::VERSION
  spec.authors       = ["Jamie Wright"]
  spec.email         = ["jamie@brilliantfantastic.com"]

  spec.summary       = %q{CarrierWave extension to transcode videos with a
                          third-party transcoding service.}
  spec.description   = %q{A simple way to transcode videos through a
                          CarrierWave process method.}
  spec.homepage      = "https://github.com/jwright/carrierwave_transcoder"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "carrierwave"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
