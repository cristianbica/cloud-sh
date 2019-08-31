# frozen_string_literal: true

module Cloud
  module Sh
    module Providers
      def self.providers
        @providers ||= {}
      end

      def self.add_provider(name, klass)
        providers[name] = klass
      end

      def self.build(account)
        return providers[account.kind].new(account) if providers.key?(account.kind)
        raise ArgumentError, "Don't know account kind #{account.kind} for account #{account.inspect}"
      end

      class Base
        include Cloud::Sh::Helpers::Commands

        attr_reader :account

        def initialize(account)
          @account = account
        end

        def servers
          raise NotImplementedError
        end

        def databases
          raise NotImplementedError
        end

        def clusters
          raise NotImplementedError
        end
      end
    end
  end
end
