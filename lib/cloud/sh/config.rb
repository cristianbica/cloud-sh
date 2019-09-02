# frozen_string_literal: true

module Cloud
  module Sh
    class Config
      attr_reader :accounts, :raw

      def initialize
        @accounts = []
        read_config
      end

      def read_config
        return unless File.exist?(config_file)
        @raw = YAML.safe_load(File.read(config_file))
        load_accounts
      end

      def load_accounts
        raw["accounts"].each do |account_config|
          accounts << Account.new(account_config)
        end
      end

      def config_file
        File.expand_path(".config/cloud-sh.yml", "~")
      end

      def aliases_file
        File.expand_path(".cloud_sh_aliases", "~/")
      end
    end

    class Account
      attr_reader :name, :kind, :context, :default, :clusters, :databases

      def initialize(config)
        @name = config["name"]
        @kind = config["kind"]
        @context = config["context"]
        @default = config.key?("default") && !!config["default"]
        @clusters = []
        @databases = []
        load_clusters(config)
        load_databases(config)
      end

      def load_clusters(config)
        return unless config.key?("clusters")
        config["clusters"].each do |cluster_config|
          clusters << Cluster.new(cluster_config)
        end
      end

      def load_databases(config)
        return unless config.key?("databases")
        config["databases"].each do |database_config|
          databases << Database.new(database_config)
        end
      end

      def find_cluster(name)
        clusters.find { |cluster| cluster.name == name } || clusters.push(Cluster.new("name" => name)).last
      end

      def find_database(name)
        databases.find { |database| database.name == name } || databases.push(Database.new("name" => name)).last
      end

      def ignore_database?(name)
        databases.any? do |database|
          database.name == name && database.ignore
        end
      end
    end
    class Cluster
      attr_reader :name, :alias, :default, :ignore

      def initialize(config)
        @name = config["name"]
        @alias = config["alias"] || @name
        @default = config.key?("default") && !!config["default"]
        @ignore = config.key?("ignore") && !!config["ignore"]
      end

      def enrich(object)
        object.alias = @alias
        object.default = default
        object.ignore = ignore
      end
    end

    class Database
      attr_reader :name, :alias, :default, :ignore

      def initialize(config)
        @name = config["name"]
        @alias = config["alias"] || @name
        @default = config.key?("default") && !!config["default"]
        @ignore = config.key?("ignore") && !!config["ignore"]
      end

      def enrich(object)
        object.alias = @alias
        object.default = default
        object.ignore = ignore
      end
    end
  end
end
