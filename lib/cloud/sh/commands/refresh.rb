# frozen_string_literal: true

require "cloud/sh/commands/base"

module Cloud
  module Sh
    module Commands
      class Refresh < Base
        attr_reader :aliases

        def execute
          Cloud::Sh::Providers::DigitalOcean.refresh_k8s_configs(force: options[:force])
          build_aliases
          save_aliases
        end

        def build_aliases
          @aliases = {}
          config.accounts.each do |account|
            puts "Refreshing account #{account.name}"
            build_ssh_aliases(account)
            build_db_aliases(account)
            build_k8s_aliases(account)
          end
        end

        def save_aliases
          print "Saving aliases ... "
          aliases_text = aliases.map do |alias_name, cmd|
            "alias #{alias_name}=\"#{cmd}\""
          end.join("\n")
          File.write(config.aliases_file, aliases_text)
          puts "DONE"
        end

        def build_ssh_aliases(account)
          print " Refreshing SSH aliases ... "
          provider = cloud_provider(account)
          provider.servers do |server|
            add_alias(:do, account, :ssh, server.name, "ssh #{server.ip}")
          end
          puts "DONE"
        end

        def build_db_aliases(account)
          print " Refreshing DB aliases ... "
          provider = cloud_provider(account)
          provider.databases do |database|
            next if database.cluster.ignore

            if database.cluster.engine == "pg"
              add_alias(:do, account, :psql, database.cluster, database.name, "psql \\\"#{database.uri}\\\"")
              add_alias(:do, account, :pgdump, database.cluster, database.name, pgdump_command(database))
              add_alias(:do, account, :pgcli, database.cluster, database.name, "pgcli \\\"#{database.uri}\\\"")
            elsif database.cluster.engine == "mysql"
              add_alias(:do, account, :mysql, database.cluster, database.name, mysql_command(database))
              add_alias(:do, account, :mysqldump, database.cluster, database.name, mysqldump_command(database))
              add_alias(:do, account, :mycli, database.cluster, database.name, "pgcli \\\"#{database.uri}\\\"")
            elsif database.cluster.engine == "redis"
              add_alias(:do, account, :redis, database.cluster, database.name, "redli -u \\\"#{database.uri}\\\"")
            else
              puts "Don't know how to handle database engine #{database.cluster.engine}"
            end
          end
          puts "DONE"
        end

        def build_k8s_aliases(account)
          print " Refreshing K8S aliases ... "
          add_alias(:k8s, account, :ctl, kubectl)
          provider = cloud_provider(account)
          provider.clusters do |cluster|
            add_alias(:k8s, account, :switch, :to, cluster, kubectl("config use-context", cluster.context))
            add_alias(:k8s, account, :ctl, cluster, kubectl("--context #{cluster.context}"))
            cluster.pods.each do |namespace, pods|
              add_alias(:k8s, account, cluster, namespace, :tail, :all, "cloud-sh k8s tail --context #{cluster.context} --namespace #{namespace}")
              pods.each do |pod|
                add_alias(:k8s, account, cluster, namespace, :tail, pod.name, "cloud-sh k8s tail --context #{cluster.context} --namespace #{namespace} --pod #{pod.name}") unless pod.name == "console"
                add_alias(:k8s, account, cluster, namespace, :exec, pod.name, "cloud-sh k8s exec  --context #{cluster.context} --namespace #{namespace} --pod #{pod.name}")
                add_alias(:k8s, account, cluster, namespace, :rails, :console, "cloud-sh k8s exec --context #{cluster.context} --namespace #{namespace} --pod #{pod.name} --cmd 'bundle exec rails console'") if pod.name == "console"
              end
            end
          end
          puts "DONE"
        end

        def kubectl(*parts)
          [
            "kubectl",
            "--kubeconfig=#{Cloud::Sh::Providers::DigitalOcean.kube_config}",
            parts
          ].flatten.join(" ")
        end

        def mysql_command(database)
          uri = URI.parse(database.uri)
          [ :mysql, mysql_connection_params(uri), uri.path.delete("/")].join(" ")
        end

        def mysqldump_command(database)
          uri = URI.parse(database.uri)
          dump_name = "#{database.name}-`date +%Y%m%d%H%M`.sql"
          [ :mysqldump, mysql_connection_params(uri), uri.path.delete("/"), "> #{dump_name}"].join(" ")
        end

        def mysql_connection_params(uri)
          [
            "--host=#{uri.host}",
            "--user=#{uri.user}",
            "--password=#{uri.password}",
            "--port=#{uri.port}",
            "--ssl-mode=REQUIRED"
          ].join(" ")
        end

        def pgdump_command(database)
          dump_name = "#{database.name}-`date +%Y%m%d%H%M`.sql"
          "pg_dump \\\"#{database.uri}\\\" -f #{dump_name}"
        end

        def add_alias(*parts, cmd)
          alias_name = parts.map { |part| normalize_alias_part(part) }.compact.join("-")
          aliases[alias_name] = cmd
        end

        def normalize_alias_part(part)
          return nil if part.respond_to?(:default) && part.default

          if part.respond_to?(:alias)
            part = part.alias
          elsif part.respond_to?(:name)
            part = part.name
          elsif part.respond_to?(:to_s)
            part = part.to_s
          end
          part.tr("._", "-")
        end

        def cloud_provider(account)
          @cloud_providers ||= {}
          @cloud_providers[account] ||= Cloud::Sh::Providers.build(account)
        end
      end
    end
  end
end
