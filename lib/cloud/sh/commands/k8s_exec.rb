# frozen_string_literal: true

require "cloud/sh/commands/base"

module Cloud
  module Sh
    module Commands
      class K8sExec < Base
        def execute
          pod = kubectl.context(options[:context]).namespace(options[:namespace]).get.pod.no_headers(true).map(:name).find do |pod|
            pod.name.start_with?(options[:pod])
          end
          raise "Cannot find pod." unless pod
          command = kubectl.context(options[:context]).namespace(options[:namespace]).exec.with(pod.name).stdin(true).tty(true).with(options[:cmd])
          puts "Command: #{command}\n"
          command.replace_current_process
        end

        def kubectl
          command_chain("kubectl").kubeconfig(Cloud::Sh::Providers::DigitalOcean.kube_config)
        end
      end
    end
  end
end

if false
  #!/usr/bin/env ruby

require "optparse"

context = ARGV[0]
namespace = ARGV[1]
pod = ARGV[2]

pod_index = 1
container_name = nil
command = "bash"

OptionParser.new do |opts|
  opts.banner = "Usage: k8s-#{context}-#{namespace}-tail-#{pod} [options]"
  opts.on("-p","--pod [POD_INDEX]", Integer, "Pod index to show (default: 1)") do |v,c|
    pod_index = v
  end
  opts.on("-c","--container [CONTAINER_NAME]", String, "Container name (default: first one found)") do |v|
    container_name = v
  end
  opts.on("-x","--command [COMMAND]", String, "Command to execute (default: bash)") do |v|
    command = v
  end
end.parse(ARGV[3..100])

pods = `kubectl --context #{context} --namespace #{namespace} get pod -o name | cut -f2 -d/ | egrep -e "^#{pod}"`.split("\n").map(&:strip)
if pods.size == 0
  puts "No pods found."
  exit
end

if pod_index <= 0 || pod_index.to_i > pods.size
  puts "Unrecognized pod index. Run the command again with  a valid pod number: "
  pods.each_with_index { |p, i| puts "#{i + 1}. #{p}" }
  puts "\nExample: k8s-#{context}-#{namespace}-tail-#{pod} --pod 1"
  exit
end
pod_name = pods[pod_index.to_i - 1]


containers = `kubectl --context #{context} --namespace #{namespace} get pod #{pod_name} -o jsonpath='{.spec.containers[*].name}'`.split(" ")
container_name ||= containers.first
unless containers.include?(container_name)
  puts "Unrecognized container name. Available options: #{containers.join(", ")}"
  puts "\nExample: k8s-#{context}-#{namespace}-tail-#{pod} --pod #{pod_index} --container #{containers.first}"
  exit
end

puts "Context: #{context}"
puts "Namespace: #{namespace}"
puts "Pod: #{pod_name} (Options: #{pods.map.with_index { |p, i| "#{i + 1} - #{p}" }.join(", ")})"
puts "Container: #{container_name} (Options: #{containers.join(", ")})"
puts "Command: #{command}"

puts ""

cmd = "kubectl --context #{context} --namespace #{namespace} exec #{pod_name} -c #{container_name} -t -i #{command}"
puts "Running: #{cmd}"
puts ""
exec cmd
end
