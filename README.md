Capistrano - Slack Notification
===============================

Notify Capistrano ver3 deployment to Slack.

![slack-notification-preview](https://raw.githubusercontent.com/linyows/capistrano-slack_notification/master/misc/preview.png)

[![Gem version](https://img.shields.io/gem/v/capistrano-slack_notification.svg?style=flat-square)][gem]
[gem]: https://rubygems.org/gems/capistrano-slack_notification

Installation
------------

Add this line to your application's Gemfile:

```ruby
gem 'capistrano-slack_notification'
```

And then execute:

```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install capistrano-slack_notification
```

Usage
-----

### Capfile

```ruby
require 'capistrano/slack_notification'
```

### config/deploy.rb

if use webhook

```ruby
set :slack_channel, '#general'
set :slack_endpoint, 'https://hooks.slack.com'
set :slack_path, '/services/T00000000/B00000000/XXXXXXXXXXXXXXXXX'

after 'deploy:started', 'slack:deploy:start'
after 'deploy:finishing', 'slack:deploy:finish'
after 'deploy:finishing_rollback', 'slack:deploy:rollback'
```

if use api that needs channel_id

```sh
$ cap production "slack:channel[general]"
#general: C038M2LE1
```

```ruby
set :slack_channel, 'C038M2LE1'
set :slack_token, 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'

after 'deploy:started', 'slack:deploy:start'
after 'deploy:finishing', 'slack:deploy:finish'
after 'deploy:finishing_rollback', 'slack:deploy:rollback'
```

Contributing
------------

1. Fork it ( https://github.com/linyows/capistrano-slack_notification/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Author
------

- [linyows][linyows]

[linyows]: https://github.com/linyows

License
-------

The MIT License (MIT)
