module Cmdserver::Templates
    class BasicTemplate

        attr_reader :body

        def initialize
            @body = <<TEMPLATE
module Cmdserver::Cmdprotocol
    def self.extend_protocol()
        # Replace the bellow with your own commands.
        # Each key is a command your server will accept and
        # call the Proc or Command associated with it.
        # 'Command' can also be a class as long as it has a 'call' method
        @protocol["extension"] = -> client_socket, argument { client_socket.puts "Command recieved" }
    end

    # Replace the bellow with your own default 'command not found' action
    def self.default_action(client_socket, argument)
        client_socket.puts "No such command: '\#{argument}'"
    end
end
TEMPLATE
        end
    end
end
