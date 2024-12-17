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

A script is provided to generate the keys and certificates for a sharded environment. Choose a number of shards to setup per helper.

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

The workflow to run IPA is a follows. First you setup and prepare a cluster, then you submit a query and finally you scale down the cluster once you're done.

## Cluster Preparation

Each helper is separated using Helm's `.Release.Name` as a differentiator. This is useful to test all helpers in a single cluster, but shouldn't be necessary for the real case scenario when each helper runs on a separate cluster. You will see Release Name in many templates.

To start your query, first you will want to scale the cluster to match the SHARD_COUNT. For example:

```
./scale.sh 4
```

To helm install and uninstall all helpers and report collector you can run.

```
./install.sh <SHARD_COUNT>
```

## Connecting to Report Collector and submitting.

You can use the `connect-to` script to "ssh" into the report collector or any of the helpers. E.g.

```
./connect-to.py rc
./connect-to.py h2 3
```

Once inside the RC you can use the following commands to submit a IPA hybrid query:

```
report_collector --output-file ipa_inputs.txt gen-hybrid-inputs --count 100 --max-conversion-value 5 --max-breakdown-key 5 --seed 15913844266827317901 --quiet 

in_the_clear --input-file ipa_inputs.txt --output-file ipa_output_in_the_clear.json --quiet

crypto_util hybrid-encrypt --input-file ipa_inputs.txt --output-dir . --network /etc/ipa/network.toml

report_collector --network /etc/ipa/network.toml --output-file ipa_output.json --shard-count 4 --wait 2 malicious-hybrid --count 100 --enc-input-file1 helper1.enc --enc-input-file2 helper2.enc --enc-input-file3 helper3.enc --max-breakdown-key 5 --with-dp 0
```

Since creating these files takes a very long time, you might want to copy a pre-generated file (from a bastion) into the report collector.

# Scaling down

To scale down the cluster just run the following commands

```
./uninstall.sh
./scale 1
```

# Utilities

Following are some example commands you can try out.

The following gets details about all pods. You can use this to know if the server is up and running or understand any problems.

```
kubectl describe pods
```

The next one is used to get information about the nodes (the hosts) that run IPA code.

```
kubectl describe nodes
```

The following commands are examples on how to get logs about different shards and the entirety of a helper.

```
kubectl logs h1-helper-shard-0 --tail=100 -f
kubectl logs h2-helper-shard-19 --tail=10000 -f

kubectl logs -l app=h1-helper-shard --tail=100 -f
kubectl logs -l app=h2-helper-shard --tail=100 -f
```

For the last commands you might need to add the option `--max-log-requests=<shard-count>`.

The following prints the EKS node groups, useful to check the current scale of the system or instance types.

```
eksctl get nodegroup --cluster open-helpers
```

Cd into the `ipa-infra` directory and run the following to start a single helper. 

```
helm install <release-name> .

# Example
helm install h1 .
```

The command should take a few seconds to start a helper with the default `values.yaml`

If you need to copy files, say from the report collector image to the bastion (your current host), you can run:

```
kubectl cp helper3_10M.enc default/report-collector-deployment-686b69c48b-7fq9j:/helper3_10M.enc
```

# Creating a custom Docker

The following instructions pertain the IPA project but since the Docker images are also used by this project, sample instructions are included here. 

Remember to replace `<TAG>` with something useful to you.

```
cd <ipa project>

docker build -t ghcr.io/private-attribution/ipa/ipa-helper:<TAG> -f docker/helper.Dockerfile .
docker build -t ghcr.io/private-attribution/ipa/rc:<TAG> -f docker/report_collector.Dockerfile .

docker push ghcr.io/private-attribution/ipa/ipa-helper:<TAG>
docker push ghcr.io/private-attribution/ipa/rc:<TAG>
```

After this you will need to modify `values.yaml` to use your docker image.

# Prod Cluster creation

An EKSCTL template is included in the `/eksctl` folder to create the cluster.

If you want to make changes to the cluster, you can deploy a cluster upgrade.

```
eksctl upgrade cluster -f eksctl/cluster-config.yaml
```

If you want to modify the Helper Instance Types there are 2 options, one way is
to modify the EC2 Launch Template associated with that nodegroup. Another way 
is to delete and create the node groups using EKSCTL:

```
eksctl delete nodegroup -f eksctl/cluster-config.yaml --include="helper*" --exclude="rc"
```

The above command will thankfully only do a dryrun, be sure to check what it's 
planning to do and re-run with `-approve`. Then, to re-create the node groups:

```
eksctl create nodegroup -f eksctl/cluster-config.yaml --include="helper*" --exclude="rc"
```

Check the [EKSCTL](https://eksctl.io/usage/creating-and-managing-clusters/) 
docs for more information.

# Troubleshooting

*What if my cluster is stuck on a IPA Query?*

You can simply restart it using `./restart-helpers.sh `

## DNS

K8s DNS (CoreDNS) presented some challenges, hence including some helpful commands here:

If you want t edit the DNS config

```
kubectl -n kube-system edit configmap coredns
```

The following commands get the configuration.

```
kubectl get pods -n kube-system

kubectl get configmap coredns -n kube-system -o yaml

aws eks describe-addon --cluster-name open-helpers --addon-name coredns
```

Restarting DNS:
```
kubectl rollout restart -n kube-system deployment/coredns
```

Scaling the DNS pods:
```
kubectl scale deployment.apps/coredns -n kube-system --replicas=0
kubectl scale deployment.apps/coredns -n kube-system --replicas=20
```

## Github Docker Repository

We use Github repository (GHCR) to keep Docker images used by the templates in 
this package which are automatically created on each push to main using Github 
Actions. GHCR [requires a token](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry) 
to be able to pull images. 

The template expects the GHCR token to be stored in `config/ghcr_auth.json` and
be of the following form:

```
{"auths":{"ghcr.io":{"auth":"<USERNAME + TOKEN>"}}}
``

To generate that value you will need to concatenate your username with your 
token and base64 the results:

```
echo -n "<username>:<token>" | base64
```


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