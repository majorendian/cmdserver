require "socket"
require "pathname"

module CmdProtocol
    # Protocol stuff goes here.
    # Should be loaded from ~/.tcpcmdserv/modules/*.rb
    @protocol_hash = {}
    def self.extend_protocol()
        @protocol_hash = {
            "dummy" => -> cs, args { cs.puts "Dummy reply"}
        }
    end
    module_function
    def getProtocolHash()
        self.extend_protocol()
        return @protocol_hash
    end


end

class Settings

    def initialize
        @workdir = Pathname.new(File.expand_path("~/.tcpcmdsrv/"))
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

    def initialize(port, hash={}, debug=false)
        @socket = TCPServer.new(port)
        puts "Started command server at #{port}"
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
                        if @cmd_hash.key? real_key
                            request.chomp!
                            puts "Request after processing: #{request}" if @debug
                            @cmd_hash[real_key].call(client, request)
                        end
                    rescue Exception
                        puts "ERROR: #{$!}"
                        raise $!
                    end
                end
            else
                client.close()
                break
            end
        end
    end
end


settings = Settings.new()
settings.load_modules()
server = TCPCommandServer.new(2121, {}, false)
server.start()
