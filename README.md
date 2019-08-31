# Cloud shell helpers

Wrapper around `doctl`, `kubectl` to build aliases for easier access to cloud server and services.
Special mention to [kubetail](https://github.com/johanhaleby/kubetail) which does the multiple kubernetes containers tailing.

## Features

- DigitalOcean aliases for ssh-ing to droplets
- DigitalOcean aliases for connecting to your databases (MySQL, Postgres, Redis)
- Refreshes DigitalOcean certificate for kubernetes
- Kubernetes aliases for tailing single or multiple pods and opening a shell inside a pod

## Installation

### Requirements

- recent version of ruby (2.6+)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [doctl](https://github.com/digitalocean/doctl)

If you're using DigitalOcean's Databases you'll need some clients for the aliases to work.
- A MySQL client ([mysql](https://dev.mysql.com/downloads/) - version 8 needed for TLS, [mycli](https://www.mycli.net))
- A Postgres client ([psql](https://www.postgresql.org/download/), [pgcli](https://www.pgcli.com))
- Redis client (you'll need [redli](https://github.com/IBM-Cloud/redli) as it needs TLS support)

### Install

Install the `cloud-sh` gem

```sh
gem install cloud-sh
```

## Usage

Login to your DigitalOcean account(s) using `doctl auth init --context context-name`.

Write a YAML file to `~/.config/cloud-sh.yml`

```
- name: personal      # name of the account; will be used to prefix aliases
  kind: do            # cloud kind (do - digitalocean only support for now)
  default: true       # if true don't use the name to prefix aliases (default: false)
  context: default    # doctl context
  clusters:           # customize K8S clusters aliases
  - name: k8s-01      # name as it is at DigitalOcean
    alias: staging    # alias name to be used in aliases (defaults to name)
    default: true     # if true don't use the name / alias as prefix (default: false)
    ignore: true      # don't create aliases for this (default: false)
  databases:          # customize databases aliases
  - name: pg-01       # name as it is at DigitalOcean
    alias: staging    # alias name to be used in aliases (defaults to name)
    default: true     # if true don't use the name / alias as prfix (default: false)
    ignore: true      # don't create aliases for this (default: false)
```

After that you can run `cloud-sh refresh` you'll get the aliases written to `~/.cloud_sh_aliases`.

### Shell Integration

1. Manual Integration

Run `cloud-sh refresh` to generate the aliases in `~/cloud_sh_aliases` and load the aliases with `source ~/cloud_sh_aliase`.

2. Automatic Integration

Setup a cron job to generate aliases:

```
10 * * * * ~/.cloud-sh/bin/cloud-sh refresh 2>&1 | logger -t cloud-sh
```

And load the aliases using for shell. For `zsh` I'm adding to `.zshrc`:

```
reload_cloud_sh() {
  source ~/.cloud_sh_aliases
}
add-zsh-hook precmd reload_cloud_sh
```

### Digital Ocean aliases
```
do-[account-name]-ssh-[dashed-droplet-name]

do-[account-name]-psql-[db-cluster-name]-[db-name]
do-[account-name]-pgcli-[db-cluster-name]-[db-name]
do-[account-name]-pgdump-[db-cluster-name]-[db-name]

do-[account-name]-mysql-[db-cluster-name]-[db-name]
do-[account-name]-mycli-[db-cluster-name]-[db-name]
do-[account-name]-mysqldump-[db-cluster-name]-[db-name]

do-[account-name]-redis-[db-cluster-name]
```

### K8S aliases

Cloud-sh will write a `~/.kube/cloud_sh_config` with the clusters configuration for `kubectl`. If you don't have a different `kubectl` config you can make a symbolic link from `~/.kube/config` to `~/.kube/cloud_sh_config` or you pass `--kubeconfig='~/.kube/cloud_sh_config'` to `kubectl`.

Note: For K8S it will try to guess a pod name by removing the groups or random groups of chars from the end (5 random alpa numeric or 8-10 hexa)

```
# Switch current kubectl context
k8s-[account-name]-switch-to-[cluster-name]
k8s-personal-switch-to-k8s-01 # switch to cluster k8s-01 of the personal account
k8s-switch-to-k8s-01 # switch to cluster k8s-01 of the default account

# Execute kubectl in a given cluster
k8s-[account-name]-ctl-[cluster-name]
k8s-personal-ctl-k8s-01 get pod --all-namespaces

# Tail all pods in a namespace
k8s-[account-name]-[cluster-name]-[namespace]-tail-all

# Tail by pod name (prefix). Supported arguments:
# --tail - number of initial lines (default: 10)
k8s-[account-name]-[cluster-name]-[namespace]-tail-[pod-name]

# Exec a shell in a specific pod. Supported arguments:
# --cmd - command to be executed (default: bash)
k8s-[account-name]-[cluster-name]-[namespace]-exec-[-pod-name]

# if there's a pod named console then it will run bundle exec rails console in that pod
k8s-[account-name]-[cluster-name]-[namespace]-rails-console
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cristianbica/cloud-sh.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
