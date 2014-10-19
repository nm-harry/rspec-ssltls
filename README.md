# rspec-ssltls [![Build Status](https://travis-ci.org/otahi/rspec-ssltls.png?branch=master)](https://travis-ci.org/otahi/rspec-ssltls)[![Coverage Status](https://coveralls.io/repos/otahi/rspec-ssltls/badge.png?branch=master)](https://coveralls.io/r/otahi/rspec-ssltls?branch=master)[![Code Climate](https://codeclimate.com/github/otahi/rspec-ssltls.png)](https://codeclimate.com/github/otahi/rspec-ssltls)[![Gem Version](https://badge.fury.io/rb/rspec-ssltls.png)](http://badge.fury.io/rb/rspec-ssltls)


Rspec-ssltls is an rspec plugin for easy SSL/TLS testing.

## Usage

RSpec-ssltls is best described by example. First, require `rspec-ssltls` in your `spec_helper.rb`:

```ruby
# spec/spec_helper.rb
require 'rspec-ssltls'
```

Then, create a spec like this:

```ruby
require 'spec_helper'

describe 'www.example.com:443' do
  it { is_expected.to have_certificate.subject(CN: '*.example.com') }
  it { is_expected.to support_protocol('TLSv1_2') }
  it { is_expected.to support_cipher('AES256-SHA').protocol('TLSv1') }
  it { is_expected.to support_cipher('DES-CBC3-SHA').protocol('SSLv3') }
end
```

You can use followings for `support_protocol` and `support_cipher.protocol`:
```
 OpenSSL::SSL::SSLContext::METHODS
  :TLSv1, :TLSv1_server, :TLSv1_client,
  :TLSv1_2, :TLSv1_2_server, :TLSv1_2_client,
  :TLSv1_1, :TLSv1_1_server, :TLSv1_1_client,
  :SSLv2, :SSLv2_server, :SSLv2_client,
  :SSLv3, :SSLv3_server, :SSLv3_client,
  :SSLv23, :SSLv23_server, :SSLv23_client
```

You can use [ciphers](https://www.openssl.org/docs/apps/ciphers.html) for `support_cipher`.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rspec-ssltls'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rspec-ssltls

## Contributing

1. Fork it ( https://github.com/otahi/rspec-ssltls/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
