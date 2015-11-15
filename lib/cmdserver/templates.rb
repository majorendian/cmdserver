module Cmdserver::Templates
    class BasicTemplate

        attr_accessor :body

        def initialize
            @body = <<TEMPLATE
module Cmdserver::Cmdprotocol
    def self.extend_protocol()
        # Replace the bellow with your own functions
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
