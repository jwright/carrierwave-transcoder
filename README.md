Carrierwave Transcoder
======================

## DESCRIPTION

A simple way to transcode videos through a [CarrierWave](https://github.com/carrierwaveuploader/carrierwave) process method.

This currently only supports [AWS Elastic Transcoder](https://aws.amazon.com/elastictranscoder) but it is wrapped with a pluggable interface where other transcoding services can be implemented easily.

## RELEASING A NEW GEM

1. Bump the VERSION in `lib/carrierwave_transcoder/version.rb`
1. Commit changes and push to GitHub
1. run `bundle exec rake release`

## CONTRIBUTING

1. Clone the repository `git clone https://github.com/jwright/carrierwave-transcoder`
1. Create a feature branch `git checkout -b my-awesome-feature`
1. Codez!
1. Commit your changes (small commits please)
1. Push your new branch `git push origin my-awesome-feature`
1. Create a pull request `hub pull-request -b jwright:master -h jwright:my-awesome-feature`

## LICENSE

Copyright (c) 2017, [Jamie Wright](http://brilliantfantastic.com).

This project is licensed under the [MIT License](LICENSE.md).
