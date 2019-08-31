# frozen_string_literal: true

require "cloud/sh/commands/base"

module Cloud
  module Sh
    module Commands
      class K8sTail < Base
        def execute
          puts "Command: #{command}"
          puts "Env: #{env.inspect}\n"
          exec env, command
        end

        def command
          [
            exe,
            "^" + (options[:pod] == "all" ? "." : options[:pod]),
            "--context #{options[:context]}",
            "--namespace #{options[:namespace]}",
            "--regex",
            "--tail #{options[:tail]}",
            "--since 240h",
            "--colored-output pod",
            "--follow true"
          ].join(" ")
        end

        def exe
          File.expand_path("../../../../exe/vendor/kubetail", __dir__)
        end

        def env
          {
            "KUBECONFIG" => Cloud::Sh::Providers::DigitalOcean.kube_config
          }
        end
      end
    end
  end
end
