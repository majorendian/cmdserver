module Cmdserver::Cmdprotocol
    # Protocol stuff goes here.
    # Should be loaded from ~/.cmdserver/modules/*.rb
    @protocol = {}

    module_function
    def extend_protocol()
        @protocol = {
            "dummy" => -> cs, args { cs.puts "Dummy reply"}
        }
    end

    def default_action(cs, args)
        cs.puts args
    end

    def get_protocol_hash()
        extend_protocol()
        return @protocol
    end

    # Default behaviour when querry was not found
    def default(cs, args)
        # NOTE: args is a String
        default_action(cs, args)
    end

end
