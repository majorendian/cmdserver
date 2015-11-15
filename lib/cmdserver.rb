require "socket"
require "pathname"
require "cmdserver/version"
require "cmdserver/cmdprotocol"
require "cmdserver/templates"
require "cmdserver/cli"

module Cmdserver

    class Settings# {{{

        attr_accessor :module_dir
        attr_accessor :workdir

        def initialize(work_dir="~/.cmdserver/")
            @workdir = Pathname.new(File.expand_path(work_dir))
            @module_dir = @workdir + "modules"
            if not @workdir.exist?
                Dir.mkdir @workdir
            end
            if not @module_dir.exist?
                Dir.mkdir @module_dir
            end
            # load_modules is now being called by the
            # TCPCommandServer class
        end

        def load_modules
            Dir.glob("#{@module_dir}/*.rb").each do |mod|
                Cmdserver::Cmdprotocol.extend_protocol()
                puts "Loading module: #{mod}"
                require mod
            end
        end
    end# }}}

    class CustomSettings < Settings# {{{

        def initialize(options)
            @workdir = options[:workdir]
            @module_dir = options[:module_dir]
            super(work_dir=@workdir)
        end
    end# }}}

    class Command # Class provided for the possibilty of future extensibility# {{{
        def initialize
        end

        def call(client_socket, arg_string)
            client_socket.puts "Dummy command call"
        end

    end# }}}

    class TCPCommandServer# {{{

        attr_accessor :socket
        attr_accessor :settings
        attr_writer :reload_settings

        def initialize(port, hash={}, settings=nil, debug=false)
            @socket = TCPServer.new(port)
            @reload_settings = false # Used from Signal.trap to allow module reloading
            @cmd_hash = hash # hash of commands
            @settings = settings
            @debug = debug
            if @settings.nil?
                @settings = Settings.new()
            end
            @settings.load_modules()
            load_cmd_proto()
        end

        def load_cmd_proto()
            phash = Cmdserver::Cmdprotocol.get_protocol_hash()
            phash.each_key do |key|
                @cmd_hash[key] = phash[key]
            end
            puts phash if @debug
        end

        def registerCallback(string, aproc)
            @cmd_hash[string] = aproc
        end


        # "Private" schelued updater.
        # Allows for loading of modules
        # without having to restart the server
        def _updater_
            loop do
                sleep 2
                if @reload_settings
                    @settings.load_modules()
                    @reload_settings = false
                end
            end
        end

        # Start the local updater,
        # and the socket => thread loop
        def start()
            # Start the local updater
            Thread.new{ _updater_ }
            loop do
                begin
                    client = @socket.accept
                rescue SystemCallError
                    exit -1
                end

                Thread.new{ process_client(client) }
            end
        end

        def process_client(client)# {{{
            #NOTE: This should remain as an isolated thread process
            loop do
                request = client.gets
                if not request.nil?
                    request.chomp!
                    puts "Got '#{request}'" if @debug
                    real_key = nil
                    @cmd_hash.each_key do |key|
                        if request.include? key
                            real_key = key
                        end
                    end
                    puts "real_key:#{real_key}" if @debug
                    if not real_key.nil?
                        begin
                            request.sub! real_key, ""
                            request.lstrip!
                            request.chomp!
                            if @cmd_hash.key? real_key
                                puts "Request after processing: #{request}" if @debug
                                @cmd_hash[real_key].call(client, request)
                            end
                        rescue Exception
                            puts "ERROR: #{$!}"
                            raise $!
                        end
                    else
                        Cmdserver::Cmdprotocol.default(client, request)
                    end
                else
                    client.close()
                    break
                end
            end
        end# }}}
    end# }}}
end
