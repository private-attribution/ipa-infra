This project provides the hosting, networking, storage, the infrastructure tu run [IPA](https://github.com/private-attribution/ipa). Before starting with this setup please clone and build IPA as we'll need it to generate keys for the infrastructure to work.

Currently, we have only included instructions for AWS, but the intent is to expand to other clouds in the future.

### Frameworks

This project uses the following frameworks:

*EKSCTL* is used to manage the AWS EKS infrastructure. Creating the K8s cluster, setting the instance type, etc.

*Minikube* is a local K8s cluster you can use for dev. *Docker Desktop*  works fine to create a local Minikube and IPA images on different platforms.

*Helm* is used to deploy changes to the cluster created by EKSCTL. Because of this we generally don't use *kubectl* to apply changes, but to observe the state of the cluster.

# Keys and configuration

You will need a set of keys, certificates and a `network.toml` to start each helper. These files are expected to be placed in the `config` folder. You will need to create this folder and fill it with the files we'll create in this section.

```
mkdir <CONFIG_DIR>
```

The following binaries require you to compile the IPA project (not ipa-infra) in release mode.

```
cd <IPA project>
cargo build --bin helper --release --no-default-features --features "web-app real-world-infra compact-gate"
```

A script is provided  to generate the keys and certificates for a sharded environment. Choose a number of shards to setup per helper.

```
python3 scripts/create-sharded-conf.py -b <CONFIG_DIR> -s <SHARD_COUNT>
```

Filenames and folders follow a convention used by this next tool which will create the `network.toml` file.

```
# go to the release folder
cd target/release/

./helper sharded-confgen --keys-dir <CONFIG_DIR> --shard-count <SHARD_COUNT> --shards-port 1443 --mpc-port 443
```

You should be ready now. Here's how the config folder looks like for 4 shards:

```
$ tree config
config
├── ghcr_auth.json
├── helper1
│   ├── shard0
│   │   ├── h1-helper-shard-0.h1-helper-shard.default.svc.cluster.local.key
│   │   ├── h1-helper-shard-0.h1-helper-shard.default.svc.cluster.local.pem
│   │   ├── h1-helper-shard-0.h1-helper-shard.default.svc.cluster.local_mk.key
│   │   └── h1-helper-shard-0.h1-helper-shard.default.svc.cluster.local_mk.pub
│   ├── shard1
│   │   ├── h1-helper-shard-1.h1-helper-shard.default.svc.cluster.local.key
│   │   ├── h1-helper-shard-1.h1-helper-shard.default.svc.cluster.local.pem

...

├── helper2
│   ├── shard0
│   │   ├── h2-helper-shard-0.h2-helper-shard.default.svc.cluster.local.key
│   │   ├── h2-helper-shard-0.h2-helper-shard.default.svc.cluster.local.pem
│   │   ├── h2-helper-shard-0.h2-helper-shard.default.svc.cluster.local_mk.key

...

│   └── shard3
│       ├── h3-helper-shard-3.h3-helper-shard.default.svc.cluster.local.key
│       ├── h3-helper-shard-3.h3-helper-shard.default.svc.cluster.local.pem
│       ├── h3-helper-shard-3.h3-helper-shard.default.svc.cluster.local_mk.key
│       └── h3-helper-shard-3.h3-helper-shard.default.svc.cluster.local_mk.pub
└── network.toml
```

# Running IPA on a Cluster

After your Minukube is set or in a Prod bastion, cd into the `ipa-infra` directory and run the following to start a single helper. 

```
helm install <release-name> .

# Example
helm install h1 .
```

The command should take a few seconds to start a helper.

Each helper is separated using Helm's `.Release.Name` as a differentiator. This is useful to test all helpers in a single cluster, but shouldn't be necessary for the real case scenario when each helper runs on a separate cluster.

You will want to scale the cluster to match the SHARD_COUNT. For example:

```
./scale.sh 4
```

To helm install and uninstall all helpers and report collector you can run.

```
./install.sh <SHARD_COUNT>
./uninstall.sh
```

### Connecting to Report Collector and submitting.

You can use the `connect-to` script to "ssh" into the report collector or any of the helpers. E.g.

```
./connect-to.py rc
./connect-to.py h2 3
```

Once inside the RC you can use the following commands to submit an IPAv2 query:

```
report_collector gen-ipa-inputs --count 1000 > input-data-1000.txt

report_collector --network /etc/ipa/network.toml --input-file input-data-1000.txt semi-honest-oprf-ipa-test --max-breakdown-key 64 --per-user-credit-cap 64 --plaintext-match-keys
```

# Utilities

Following are some example commands you can try out.

```
kubectl describe pods
```

This gets details about all pods. You can use this to know if the server is up and running or understand any problems.

```
kubectl logs -l app=h1-helper-shard --tail=100 -f
kubectl logs -l app=h2-helper-shard --tail=100 -f
```

# Prod Cluster creation

An EKSCTL template is included in the `/eksctl` folder to create the cluster.

If you want to make changes to the cluster, you can deploy a cluster upgrade.

```
eksctl upgrade cluster -f eksctl/cluster-config.yaml
```

On way to apply Instance Type changes require is to modify the EC2 Launch Template associated with that nodegroup.

# Troubleshooting

*What if my cluster is stuck on a IPA Query?*

You can simply restart it using `./restart-helpers.sh `

# Local Setup

The following setup is only necessary for your local development.

### Minikube

In Prod you will use an existing K8s cluster, but locally you will want to start your own local Minikube:

```
minikube start
```

You will need an IPA Docker image. To load the image into your Minikube:

```
minikube image load ipa:current
```

The image tag needs to match Helm's `values.yaml`.