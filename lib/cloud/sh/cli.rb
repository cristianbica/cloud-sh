# frozen_string_literal: true

module Cloud
  module Sh
    class Cli
      extend GLI::App
      subcommand_option_handling :normal
      arguments :strict
      program_desc "Cloud shell helpers"

      desc "Refresh aliases"
      command :refresh do |c|
        c.switch :force, negatable: false, default_value: false, desc: "Force refresh"
        c.action do |global_options, options, args|
          Cloud::Sh::Commands::Refresh.execute(global_options, options, args)
        end
      end

      # desc "SSH Into machines"
      # arg_name 'hostname_or_ip'
      # command :ssh do |c|
      #   c.action do |global_options, options, args|
      #     Cloud::Commands::Ssh.execute(global_options, options, args)
      #   end
      # end

      # desc "DB Commands"
      # command :db do |c|
      #   c.desc "Open a cli to to the db"
      #   c.arg "database_name_or_url"
      #   c.command :cli do |sc|
      #     sc.flag :cli, desc: "DB CLI tool to use (psql, mysql, mycli)", required: false, default_value: "auto", arg_name: "cli"
      #     sc.action do |global_options, options, args|
      #       Cloud::Commands::Db::Cli.execute(global_options, options, args)
      #     end
      #   end

      #   c.desc "Dump the database content to a sql file"
      #   c.arg "database_name_or_url"
      #   c.command :dump do |sc|
      #     sc.action do |global_options, options, args|
      #       Cloud::Commands::Db::Dump.execute(global_options, options, args)
      #     end
      #   end
      # end

      desc "K8S Commands"
      command :k8s do |c|
        c.desc "Open a shell in a container"
        c.command :exec do |sc|
          sc.flag :context, desc: "K8S Context", required: true, arg_name: "context"
          sc.flag :namespace, desc: "K8S Namespace", required: true, arg_name: "namespace"
          sc.flag :pod, desc: "K8S Pod (prefix)", required: true, arg_name: "pod"
          sc.flag :cmd, desc: "Shell / Command to execute", required: false, arg_name: "cmd", default_value: "bash"
          sc.action do |global_options, options, args|
            Cloud::Sh::Commands::K8sExec.execute(global_options, options, args)
          end
        end

        c.desc "Tail output for a pod"
        c.command :tail do |sc|
          sc.flag :context, desc: "K8S Context", required: true, arg_name: "context"
          sc.flag :namespace, desc: "K8S Namespace", required: true, arg_name: "namespace"
          sc.flag :pod, desc: "K8S Pod (prefix)", required: true, arg_name: "pod", default_value: "all"
          sc.flag :tail, desc: "Number of lines to tail initially", required: false, arg_name: "tail", default_value: "10"
          sc.action do |global_options, options, args|
            puts [global_options, options, args].inspect
            Cloud::Sh::Commands::K8sTail.execute(global_options, options, args)
          end
        end
      end
    end
  end
end
