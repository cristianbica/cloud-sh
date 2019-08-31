# frozen_string_literal: true

module Cloud
  module Sh
    module Commands
      class Base
        include Cloud::Sh::Helpers::Commands

        attr_reader :options, :args

        def self.execute(global_options, options, args)
          new(options: global_options.merge(options), args: args).execute
        rescue Exception => e
          puts e.backtrace.join("\n")
          puts e.inspect
        end

        def initialize(options:, args:)
          @options = options
          @args = args
        end

        def execute
          raise NotImplementedError
        end

        def config
          Cloud::Sh.config
        end
      end
    end
  end
end
