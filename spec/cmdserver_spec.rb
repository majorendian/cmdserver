require 'spec_helper'
require 'socket'
require 'pathname'

describe Cmdserver do

    it 'has a version number' do
        expect(Cmdserver::VERSION).not_to be nil
    end

    it "has settings" do
        expect(Cmdserver::Settings).not_to be nil
    end

    it "has a tcp command server" do
        expect(Cmdserver::TCPCommandServer).not_to be nil
    end

    it "has a protocol" do
        expect(Cmdserver::CmdProtocol).not_to be nil
    end

    it "has a default behaviour function for the protocol" do
        expect(Cmdserver::CmdProtocol.respond_to? "default").not_to be nil
    end

    it "can create a settings object" do
        @settings = Cmdserver::Settings.new()
        @settings.should be_an_instance_of Cmdserver::Settings
    end

    it "creates it's config directory ~/.cmdserver" do
        expect(Pathname.new(File.expand_path("~/.cmdserver")).exist?).to be true
    end


    it "can create a tcp command server object" do
        @server = Cmdserver::TCPCommandServer.new(2123)
        @server.should be_an_instance_of Cmdserver::TCPCommandServer
        @server.socket.close()
        @server = nil
    end

    it "can respond to the 'dummy' querry" do
        server = Cmdserver::TCPCommandServer.new(2122)
        thr = Thread.new { server.start() }
        client = TCPSocket.new("localhost",2122)
        client.puts "dummy"
        response = client.gets
        response.chomp!
        expect(response).to eq "Dummy reply"
        thr.kill()
        server.socket.close()
        server = nil
    end

    it "echoes strings back by default" do
        server = Cmdserver::TCPCommandServer.new(2121)
        thr = Thread.new { server.start() }
        client = TCPSocket.new("localhost",2121)
        random_string = (0...8).map { (65 + rand(26)).chr }.join
        client.puts random_string
        response = client.gets
        response.chomp!
        expect(response).to eq(random_string)
        thr.kill()
        server.socket.close()
        server = nil
    end

    it "can be easily overriden and extended" do
        module Cmdserver::CmdProtocol
            def self.extend_protocol()
                @protocol_hash["extension"] = -> cs, args { cs.puts "Extended!" }
            end

            def self.default_action(cs, args)
                cs.puts "No such command"
            end
        end
        server = Cmdserver::TCPCommandServer.new 2223
        thr = Thread.new { server.start }
        client = TCPSocket.new "localhost", 2223

        client.puts "extension"
        response = client.gets
        response.chomp!

        random_string = (0...8).map { (65 + rand(26)).chr }.join
        client.puts random_string
        last_defined_default = client.gets
        last_defined_default.chomp!

        server.socket.close()
        thr.kill()
        server = nil

        expect(response).to eq("Extended!")
        expect(last_defined_default).to eq("No such command")

    end
    it "accepts Cmdserver::Command derived classes and any classes with a 'call' method" do
        class MyCommand < Cmdserver::Command
            def call(cs, args)
                cs.puts "Something something #{args}"
            end
        end

        class CustomClass
            def call(cs, args)
                cs.puts "Unrelated class"
            end
        end

        command = MyCommand.new()
        unrel = CustomClass.new()

        server = Cmdserver::TCPCommandServer.new 2222, { "sillyness" => command, "unrel" => unrel }
        thr = Thread.new { server.start }
        client = TCPSocket.new "localhost", 2222

        client.puts "sillyness one"
        response = client.gets
        response.chomp!
        client.puts "unrel"
        response_2 = client.gets
        response_2.chomp!

        server.socket.close()
        thr.kill()
        server = nil

        expect(response).to eq("Something something one")
        expect(response_2).to eq("Unrelated class")
    end
end
