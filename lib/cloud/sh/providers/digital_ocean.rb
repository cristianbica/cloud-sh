# frozen_string_literal: true

require "cloud/sh/providers/base"
require "open3"

module Cloud
  module Sh
    module Providers
      class DigitalOcean < Base
        def self.refresh_k8s_configs
          return if File.exist?(kube_config) && (Time.now.to_i - File.mtime(kube_config).to_i) < 3600
          configs = Cloud::Sh.config.accounts.map { |account| new(account).k8s_configs }.flatten.compact
          config = configs.shift
          configs.each do |cfg|
            config["clusters"] += cfg["clusters"]
            config["contexts"] += cfg["contexts"]
            config["users"] += cfg["users"]
          end
          config["current-context"] = config["contexts"].first["name"]
          File.write(kube_config, YAML.dump(config))
        end

        def self.kube_config
          File.expand_path(".kube/cloud_sh_config", "~/")
        end

        def servers
          doctl.compute.droplet.list.format("Name,PublicIPv4").no_header(true).map(:name, :ip).each do |server|
            yield server if block_given?
          end
        end

        def databases
          list = []
          doctl.db.list.no_header(true).map(:id, :name, :engine).each do |cluster|
            account.find_database(cluster.name)&.enrich(cluster)
            defaultdb_uri = doctl.db.conn.with(cluster.id).format("URI").no_header(true).map(:uri).first.uri
            dbs = [OpenStruct.new(name: "")] if cluster.engine == "redis"
            dbs ||= doctl.db.db.list.with(cluster.id).no_header(true).map(:name)
            dbs.each do |db|
              uri = URI.parse(defaultdb_uri).tap { |uri| uri.path = "/#{db.name}" }.to_s
              database = OpenStruct.new(cluster: cluster, name: db.name, uri: uri)
              yield database if block_given?
              list << database
            end
          end
          list
        end

        def clusters
          doctl.k8s.cluster.list.no_header(true).map(:id, :name).map do |cluster|
            account.find_cluster(cluster.name)&.enrich(cluster)
            next if cluster.ignore
            cluster.context = k8s_context(account, cluster)
            cluster.pods = kubectl.context(cluster.context).get.pod.all_namespaces(true).no_headers(true).map(:namespace, :name).map do |pod|
              pod.name = k8s_pod_name(pod.name)
              pod
            end.group_by(&:itself).keys.group_by(&:namespace)
            yield cluster if block_given?
          end.compact
        end

        def k8s_configs
          doctl.k8s.cluster.list.no_header(true).map(:id, :name).map do |cluster|
            account.find_cluster(cluster.name)&.enrich(cluster)
            next if cluster.ignore
            cluster_config = YAML.load(doctl.k8s.cluster.config.show.with(cluster.id).execute)
            cluster_config["contexts"].first["name"] = k8s_context(account, cluster)
            cluster_config
          end
        end

        def k8s_context(account, cluster)
          [
            account.name,
            (cluster.alias unless cluster.default)
          ].compact.join("-").tr("._", "-")
        end

        def k8s_pod_name(name)
          parts = name.split("-")
          parts.pop if parts.last =~ /^[a-z0-9]{5}$/
          parts.pop if parts.last =~ /^[a-f0-9]{8,10}$/
          parts.pop if parts.last =~ /^[a-f0-9]{8,10}$/
          parts.join("-")
        end

        def doctl
          command_chain("doctl").context(account.context)
        end

        def kubectl
          command_chain("kubectl").kubeconfig(Cloud::Sh::Providers::DigitalOcean.kube_config)
        end
      end

      add_provider("do", DigitalOcean)
    end
  end
end
