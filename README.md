# pitcgi


## Description

pitcgi is account management tool for cgi.


## Installation

### Archive Installation

    $ rake install


### Gem Installation

    $ gem install pitcgi


### Setup
```sh
$ sudo mkdir /etc/pitcgi
$ sudo chgrp www-data /etc/pitcgi
$ sudo chmod 770 /etc/pitcgi
$ sudo adduser `echo $USER` www-data
```

## Features/Problems


## Synopsis

command:

    $ pitcgi set twitter.com

open 'twitter.com' config with $EDITOR.

    $ pitcgi get twitter.com | lv

get config of 'twitter.com' by YAML.

    $ pitcgi switch dev

switch profile to 'dev'


ruby lib.
```ruby
require "pitcgi"

config = Pitcgi.get("twitter.com", :require => {
  "username" => "default value",
  "password" => "default value"
})

Pitcgi.get("vox.com", :require => {
  "username" => "default value",
  "password" => "default value"
  "nickname" => "default value"
})
```
Pitcgi.get open $EDITOR with `require` hash if the setting does not have
required keys.


## Copyright

Author:
* sanadan <jecy00@gmail.com>

Copyright:
* Copyright (c) 2008 cho45
* Copyright (c) 2014 sanadan

License:
* Ruby's
