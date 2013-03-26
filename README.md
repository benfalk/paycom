# Paycom

This gem interfaces with the paycom system and allows you to do
common tasks against it without having to use their website.

## Installation

Add this line to your application's Gemfile:

    gem 'paycom'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install paycom

## Usage

```ruby

require 'paycom'

login = Paycom::Login.new 'user_name', 'password', 'ssn_last_four_digits'

# This will fill out the week vanillia style
Paycom.week_punch login, Date.today

# This will fill out next week
Paycom.week_punch login, 1.week.from_now

```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
