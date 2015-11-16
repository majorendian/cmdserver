module Cmdserver::CLI

    DAEMON_NAME = "cmdserver"
    DAEMON_LOGFILE = "cmdserver.log"

    class Daemonizer
        def initialize()
            @dprocess = nil
            @daemon_pid_file = nil
            @daemon_pid = nil
            @daemon_running = false
        end

        def daemonize()
            puts "Forking server to the background..."

            if @dprocess.nil?
                puts "FATAL ERROR: No daemon process specified!"
                exit -1
            end

            pid = fork
            if not pid
                #child
                daemon_preparation()
                @dprocess.call()
                puts "Server started."
            end
            return pid
        end

        def daemon_preparation
            $0 = DAEMON_NAME
            Process.setsid
            Signal.trap("HUP", proc { _handle_sighup } ) 
            Signal.trap("TERM", proc { _handle_sigterm } )
        end

        def _handle_sighup()
            # Placeholder
        end

        def _handle_sigterm()
            # Placeholder
        end
    end

    class ServerDaemonizer < Daemonizer
        def initialize(server)
            super()
            @server = server
            @dprocess = -> { server.start() }
        end

        def daemon_preparation
            super()
            logpath = Pathname.new(@server.settings.workdir) + Pathname.new(DAEMON_LOGFILE)
            $stdout.reopen(logpath, "a")
            $stderr = $stdout
        end

        # NOTE: Could use some logging mechanism...
        def _handle_sighup()
            @server.reload_settings = true
        end

        def _handle_sigterm()
            @server.socket.close()
        end
    end
end
