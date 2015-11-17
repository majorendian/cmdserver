# Cmdserver

Cmdserver gives you the ability to design a very simple command server.
Simply create a .rb module under `~/.cmdserver/modules/` and override the module `Cmdserver::Cmdprotocol`.   
Fire up your server and you are done! It is ready to respond to the commands you have defined.  

From version 1.0.0 the `cmdserver` executable is provided for even faster development startup. Please read the __Using 'cmdserver'__ section to learn more. Also, `@protocol_hash` has been renamed to `@protocol` and `Cmdserver::CmdProtocol` to `Cmdserver::Cmdprotocol` so make sure to introduce these changes to your own modules or otherwise they will not load properly.

## Future plans

Currently, the server requests and responses are being sent in plaintext, which isn't exaclty the best idea. However, The server isn't ment as a substitute for SSH or other RCE tools. That is the reason why I haven't included support for SSL. It should be possible to hack this into your server through the modules, but it might be a bit painfull to do so (I haven't tried honestly). So, if there is enough requests to add this in, I might start working on it.  
Besides that, there aren't any more future plans besides necessary bugfixes, documentation and examples.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cmdserver'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cmdserver

## Using the 'cmdserver' executable

With version 1.0.0, you can now easily create a module by issuing `cmdserver --skel > ~/.cmdserver/modules/test.rb`. This will generate  
a skeleton file which will be loaded by the server during startup. Within the skeleton file there is a quick and dirty manual of  
what you should do in order to get started. If the `~/.cmdserver/modules` path doesn't exits, create it. Otherwise it will be created the first time the executable is started.  
To start the server, just type `cmdserver -p PORTNUMBER` where PORTNUMBER is the port you wish your server to listen at.  
The skeleton file already has the `extension` command defined. To test if everything is working as it should, connect to your server via `telnet` or `netcat` through the specified port, and send it the command string `extension`.  
The server should respond with `Command recieved`.  

To daemonize the process supply the -d switch.  
Here is an example session:  

```
$> cmdserver -dp 2121
Loading module: /home/user/.cmdserver/modules/test.rb
Forking server to the background...
$> nc localhost 2121
extension
Command recieved
^C
$> 
```  

You can also force the server to reload all modules by sending it the SIGHUP signal.

Other switches that are available:
```
$> cmdserver --help
Usage: cmdserver [options]
    -d, --daemon                     Daemonize process
    -p, --port PORTNUM               Specify arbitrary port
    -w, --workdir WORKDIR            Active working directory. '~/.cmdserver/' by default.
					Without -m specified, module directory is set to 'WORKDIR/modules'.
					This directory is also where 'cmdserver.log' gets created.
    -m, --module-dir MODULE_DIR      Load modules from MODULE_DIR instead of '~/.cmdserver/modules'
        --skel                       Dumps a simple module template to standard output.
        --debug                      Turn on debugging information.
    -h, --help                       Display this help message
    -v, --version                    Display version information and exit
```

## Using the programming API

By default, Cmdserver looks into `~/.cmdserver/modules` for any .rb files present. It then `require`-s them into the program.   
In these .rb files, you override the module `Cmdserver::Cmdprotocol` as demonstrated bellow   

```ruby
module Cmdserver::Cmdprotocol
    def self.extend_protocol
        @protocol["CustomCommand"] = -> client_socket, arguments { client_socket.puts "You sent: #{arguments}" }
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

The `@protocol` can be destroyed in any module. The hash gets copied into the core on a per-module basis. Note that this can introduce
conflicts when many modules define the same keys for commands.
    

Then, in your program
```ruby
require "cmdserver"
server = Cmdserver::TCPCommandServer.new(1234)
server.start()
```

That starts the main loop which will then start accepting connections.   

You then connect to the specified port (1234 in our case) and write `CustomCommand`. The server will
then execute your function.   

The functions can also be specified in the constructor itself as a hash:   

```ruby
require "cmdserver"
server = Cmdserver::TCPCommandServer.new(1234, {
    "CustomCommand" => -> client, args { client.puts "Running custom command" }
})
server.start()
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/majorendian/Modular-Tcp-Command-Server


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

