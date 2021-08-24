require 'capistrano/configuration'
require 'aws-sdk-ec2'
require 'colorize'
require 'terminal-table'
require 'yaml'
require_relative 'utils'
require_relative 'ec2-handler'
require_relative 'status-table'

# Load extra tasks
load File.expand_path("../tasks/ec2.rake", __FILE__)

module Capistrano
  module DSL
    module Ec2

      def ec2_handler
        @ec2_handler ||= CapEC2::EC2Handler.new
      end

      def ec2_role(name, options={})
        aws_client = options.delete(:aws_client)
        filter_by_stage = options.delete(:filter_by_stage)
        raise ArgumentError, 'aws_client must be set' unless aws_client.is_a?(Array)

        ec2_handler.get_servers_for_role(name, aws_client, filter_by_stage).each do |(server, client)|
          env.role(name, CapEC2::Utils.contact_point(server),
                   options_with_instance_id(options, server, client))
        end
      end

      def env
        Configuration.env
      end

      private

      def options_with_instance_id(options, server, client)
        options.merge({aws_instance_id: server.instance_id, aws_ec2_client: client})
      end

    end
  end
end

self.extend Capistrano::DSL::Ec2

Capistrano::Configuration::Server.send(:include, CapEC2::Utils::Server)
