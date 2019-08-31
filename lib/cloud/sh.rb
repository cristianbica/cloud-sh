# frozen_string_literal: true

require "cloud/sh/version"
require "gli"

require "cloud/sh/config"

require "cloud/sh/helpers/commands"

require "cloud/sh/commands/refresh"
require "cloud/sh/commands/k8s_tail"
require "cloud/sh/commands/k8s_exec"

require "cloud/sh/providers/digital_ocean"

module Cloud
  module Sh
    class Error < StandardError; end
    module_function

    def config
      @config ||= Cloud::Sh::Config.new
    end
  end
end

module Kernel
  def cloud_sh_exec(*cmd, env: nil)
    cmd = cmd.flatten.map(&:to_s).join(" ")
    args = env ? [env, cmd] : [cmd]
    message = "Executing: #{cmd}"
    message << " (#{env.inspect})" if env
    stdout, stderr, status = Open3.capture3(*args)
    unless status.success?
      puts "Command: #{cmd}"
      puts "ENV: #{env.inspect}" if env
      puts "Stdout:\n#{stdout}\n"
      puts "Stderr:\n#{stderr}\n"
      raise "Command failed!!!"
    end
    stdout
  end
end

class OpenStruct
  def merge(other)
    other.each_pair do |k, v|
      self[k] = v
    end
  end
end
