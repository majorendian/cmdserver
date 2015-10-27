require "socket"
require "pathname"
require "cmdserver/version"

module Cmdserver

    module CmdProtocol
        # Protocol stuff goes here.
        # Should be loaded from ~/.cmdserver/modules/*.rb
        @protocol_hash = {}
        def self.extend_protocol()
            @protocol_hash = {
                "dummy" => -> cs, args { cs.puts "Dummy reply"}
            }
        end

        def self.default_action(cs, args)
            cs.puts args
        end

        module_function
        def getProtocolHash()
            self.extend_protocol()
            return @protocol_hash
        end

        # Default behaviour when querry was not found
        module_function
        def default(cs, args)
            # NOTE: args is a String
            self.default_action(cs, args)
        end
    end

    class Settings

        def initialize(config_dir="~/.cmdserver/")
            @workdir = Pathname.new(File.expand_path(config_dir))
            @config_rc = @workdir + "configrc"
            @module_dir = @workdir + "modules"
            if not @workdir.exist?
                Dir.mkdir @workdir
                if not @config_rc.exist?
                    File.new @config_rc, "w"
                end
            end
            if not @module_dir.exist?
                Dir.mkdir @module_dir
            end
            # Load modules contained within the module
            # directories
            load_modules()
        end

        def load_modules
            Dir.glob("#{@module_dir}/*.rb").each do |mod|
                CmdProtocol.extend_protocol()
                puts "Loading module: #{mod}"
                require mod
            end
        end
    end

    class TCPCommandServer

        attr_accessor :socket

        def initialize(port, settings=nil, hash={}, debug=false)
            if settings.nil?
                @settings = Settings.new()
            end
            @socket = TCPServer.new(port)
            @cmd_hash = hash # hash of commands
            @debug = debug
            load_cmd_proto()
        end

        def load_cmd_proto()
            phash = CmdProtocol.getProtocolHash()
            phash.each_key do |key|
                @cmd_hash[key] = phash[key]
            end
        end

        def registerCallback(string, aproc)
            @cmd_hash[string] = aproc
        end

        def start()
            loop do
                client = @socket.accept
                Thread.new{ process_client(client) }
            end
        end

        def process_client(client)
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
                        Cmdserver::CmdProtocol.default(client, request)
                    end
                else
                    client.close()
                    break
                end
            end
        end
    end
end


#server = TCPCommandServer.new(2121, {}, false)
#server.start()
