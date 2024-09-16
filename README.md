This project provides the hosting, networking, storage, the infrastructure tu run [IPA](https://github.com/private-attribution/ipa). Before starting with this setup please clone and build IPA as we'll need it to generate keys for the infrastructure to work.

Currently, we have only included instructions for AWS, but the intent is to expand to other clouds in the future.

# Dev

This project uses the following frameworks:

*EKSCTL* is used to manage the AWS EKS infrastructure. Creating the K8s cluster, setting the instance type, etc.

*Minikube* is a local K8s cluster you can use for dev. *Docker Desktop*  works fine to create a local Minikube and IPA images on different platforms.

*Helm* is used to deploy changes to the cluster created by EKSCTL. Because of this we generally don't use *kubectl* to apply changes, but to observe the state of the cluster.

## Local Setup

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

### Keys and configuration

You will need a set of keys, certificates and a `network.toml` to start each helper. These files are expected to be placed in the `config` folder.

The following binaries require you to compile the IPA project (not ipa-infra). Please change the following environemtn variables accordingly, using `localhost` if you intend to test locally.

```
cd <IPA project>
export HELPER1_HOSTNAME=<DNS name or localhost>
export HELPER2_HOSTNAME=<DNS name or localhost>
export HELPER3_HOSTNAME=<DNS name or localhost>

cd /target/release/
mkdir config

# generate keys and cert
./helper keygen --name $HELPER1_HOSTNAME --tls-cert config/h1.pem --tls-key config/h1-cert.key --mk-public-key config/h1_mk.pub --mk-private-key config/h1_mk.key
./helper keygen --name $HELPER2_HOSTNAME --tls-cert config/h2.pem --tls-key config/h2-cert.key --mk-public-key config/h2_mk.pub --mk-private-key config/h2_mk.key
./helper keygen --name $HELPER3_HOSTNAME --tls-cert config/h3.pem --tls-key config/h3-cert.key --mk-public-key config/h3_mk.pub --mk-private-key config/h3_mk.key

# use public info to generate network.toml

./helper confgen --keys-dir config --ports 443 443 443 --hosts $HELPER1_HOSTNAME $HELPER2_HOSTNAME $HELPER3_HOSTNAME

# copy generated config into this project. E.g. cp config <IPA-INFRA>/config


cp -r config ../../../ipa-infra/

# Or if config dir already exists

cp config/* ../../../ipa-infra/config/
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

To start (or restart) all helpers you can use the following script:

```
./restart-helpers.sh
```

Following are some example commands you can try out.

```
kubectl describe pods
```

This gets details about all pods. You can use this to know if the server is up and running or understand any problems.

```
kubectl logs -l app=h1-helper-shard --tail=100 -f
```

Gets the logs for helper 1.

```
kubectl exec --stdin --tty h1-helper-deployment-84bd8fd699-2b7gg -- /bin/bash
```

SSH into a host.

```
helm upgrade h1 .
```

Upgrades a single helper with new changes:

# Prod Cluster creation

An EKSCTL template is included in the `/eksctl` folder to create the cluster.

If you want to make changes to the cluster, you can deploy a cluster upgrade.

```
eksctl upgrade cluster -f eksctl/cluster-config.yaml
```

On way to apply Instance Type changes require is to modify the EC2 Launch Template associated with that nodegroup.

## Troubleshooting

*What if my cluster is stuck on a IPA Query?*

You can simply restart it using `./restart-helpers.sh `

