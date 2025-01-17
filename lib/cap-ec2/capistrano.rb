require 'capistrano/configuration'
require 'aws-sdk-ec2'
require 'colorize'
require 'terminal-table'
require 'yaml'
require_relative 'utils'
require_relative 'ec2-handler'

module Capistrano
  module DSL
    module Ec2

      def ec2_handler
        @ec2_handler ||= CapEC2::EC2Handler.new
      end

      def ec2_role(name, options={})
        aws_client = options.delete(:aws_client)
        filter_by_stage = options.delete(:filter_by_stage)
        filter_by_stage = true if filter_by_stage.nil?
        raise ArgumentError, 'aws_client must be set' if aws_client.nil?

        ec2_handler.get_servers_for_role(name, aws_client, filter_by_stage).each do |(server, client)|
          env.role(name, CapEC2::Utils.contact_point(server),
                   options_with_instance_id(options, server))
        end
      end

      def env
        Configuration.env
      end

      private

      def options_with_instance_id(options, server)
        options.merge({aws_instance_id: server.instance_id, aws_instance_az: server.placement.availability_zone})
      end

    end
  end
end

self.extend Capistrano::DSL::Ec2

Capistrano::Configuration::Server.send(:include, CapEC2::Utils::Server)
