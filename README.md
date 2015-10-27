# Cmdserver

Cmdserver gives you the ability to design a very simple command server.
Simply create a .rb module under `~/.cmdserver/modules/` and override the module `Cmdserver::CmdProtocol`.   
Fire up your server and you are done! It is ready to respond to the commands you have defined.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cmdserver'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cmdserver

## Usage

By default, Cmdserver looks into `~/.cmdserver/modules` for any .rb files present. It then `require`s them into the program.   
In these .rb files, you override the module `Cmdserver::CmdProtocol` as demonstrated bellow   

```ruby
module Cmdserver::CmdProtocol
    def self.extend_protocol
        @protocol_hash["CustomCommand"] = -> client_socket, arguments { client_socket.puts "You sent: #{arguments}" }
    end

    def self.default_action(client_socket, arguments)
        client_socket.puts "#{arguments} - Command not recognized"
    end
end
```

Here we defined `CustomCommand` to be the string that will trigger the execution of the function we presented.
The first argument passed to the function is the client socket, the second argument `arguments` is a __string__ of whatever
is left, when we removed `CustomCommand` from the string we initially recieved from the client. This might change in the future.
For now, argument parsing is left up to the individual functions.   

Also note that overriding the default behaviour can be done only once. The last loaded module that redefines `self.default_action` is what is going to happen, when the command is not recognized. By default, it echoes back whatever it recieves.   

The `@protocol_hash` can be destroied in any module. The hash gets copied into the core on a per-module basis. Note that this can introduce
conflicts when many modules define the same keys for commands.
    

Then, in your program
```ruby
require "cmdserver"
server = TCPCommandServer.new(1234)
server.start()
```

That starts the main loop which will then start accepting connections.   

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/majorendian/cmdserver.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

