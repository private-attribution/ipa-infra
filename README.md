## Dev

You will want to clone and build the [IPA](https://github.com/private-attribution/ipa) project to be able to create Docker images or run some helper commands.

### Minikube

To start your local Kubernetes:
```
minikube start
```

You will need an IPA Docker image. To load the image into your Minikube:

```
minikube image load ipa:current
```

The image tag needs to match Helm's `values.yaml`.

### Configuration

You will need a set of keys, certificates and a `network.toml` to start each helper. These files are expected to be placed in the `config` folder.

After you built IPA (not IPA infra, this project):
```
cd <IPA project>/target/release/
mkdir config

# generate keys and cert
./helper keygen --name localhost --tls-cert config/h1.pem --tls-key config/h1-cert.key --mk-public-key config/h1_mk.pub --mk-private-key config/h1_mk.key
./helper keygen --name localhost --tls-cert config/h2.pem --tls-key config/h2-cert.key --mk-public-key config/h2_mk.pub --mk-private-key config/h2_mk.key
./helper keygen --name localhost --tls-cert config/h3.pem --tls-key config/h3-cert.key --mk-public-key config/h3_mk.pub --mk-private-key config/h3_mk.key

# use public info to generate network.toml
./helper confgen --keys-dir config --ports 30001 30002 30003

# copy generated config into this project. E.g. cp config <IPA-INFRA>/config
cp -r config ../../../ipa-infra/
```


### Deploying

After your Minukube is set, inside the `ipa-infra` directory, run the following to start a helper:
```
helm install h1 .
helm install h2 . --set serviceNodePort=30002
helm install h3 . --set serviceNodePort=30003
```

Note the Helm's `Release.Name` is used to separate all resources for each helper.

To upgrade with new changes:
```
helm upgrade h1 .
```

To expose a helper service use either of the following options:
```
kubectl port-forward svc/helper-service 8080:3000
minikube service helper-service --url
```
