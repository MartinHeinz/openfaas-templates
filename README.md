# Going Serverless with Go, OpenFaaS and k3s

## Setup Cluster

### "Production" Cluster

```shell
curl -sfL https://get.k3s.io | sh -

sudo cat /var/lib/rancher/k3s/server/node-token  # This is K3S_TOKEN

export K3S_URL="http://localhost:6443"
export K3S_TOKEN="..."

sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) /home/martin/.kube/config

kubectl get node
kubectl config view

```

If you get `connection refused` error try running `systemctl restart k3s`

To add worker nodes, `ssh` into other machine, export variables as shown above and run `curl -sfL https://get.k3s.io | sh -`


### Install CLI

```shell
curl -sL https://cli.openfaas.com | sudo sh
```

### Deploy OpenFaaS

```shell
git clone https://github.com/openfaas/faas-netes

kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml

PASSWORD=$(head -c 12 /dev/urandom | shasum| cut -d' ' -f1)
kubectl -n openfaas create secret generic basic-auth \
--from-literal=basic-auth-user=admin \
--from-literal=basic-auth-password="$PASSWORD"

cd faas-netes && \
kubectl apply -f ./yaml

export OPENFAAS_URL=http://127.0.0.1:31112

kubectl port-forward svc/gateway -n openfaas 31112:8080 &
```

Open <http://127.0.0.1:31112> in browser and login with `admin` and `echo $PASSWORD`

### Create Function

```shell
faas-cli new --lang <TEMPLATE_NAME> <NAME> --prefix="<DOCKER_HUB_USERNAME>" # can also use GitHub registry
```

Images need to be pushed to remote registry, because _OpenFaaS_ doesn't recognize local repositories. That's why, you need to specify prefix, which is a username + repository in remote registry.

If you don't want to push images, then you can use `helm` and pass it `openfaasImagePullPolicy` and `faasnetesd.imagePullPolicy` parameters to use local docker images:

```shell
helm upgrade openfaas chart/openfaas --install \
  --set "faasnetesd.imagePullPolicy=IfNotPresent" \
  --set "openfaasImagePullPolicy=IfNotPresent" \
  --namespace openfaas  \
  --set functionNamespace=openfaas-fn \
  --set operator.create=true
```

### Build and Deploy Function

```shell
cd template/<TEMPLATE_NAME>/
go mod tidy

cd ../functions
faas-cli build -f <FUNC_NAME>.yml
faas-cli push -f <FUNC_NAME>.yml
faas-cli deploy -f <FUNC_NAME>.yml
```

_Golang_ module system is used, therefore before building image, you first need to download all dependencies with `go mod tidy`

## Create Own Template

_See: <https://github.com/openfaas/faas-cli/blob/master/guide/TEMPLATE.md>_

```shell
faas-cli template pull https://github.com/MartinHeinz/golang-openfaas-k3s --overwrite

# Or

export OPENFAAS_TEMPLATE_URL="https://github.com/MartinHeinz/golang-openfaas-k3s"
faas-cli template pull

faas-cli new --list
```

### Testing Template

```shell
# From this project root directory
faas-cli new --lang <TEMPLATE_NAME> <NAME> --prefix="<DOCKER_HUB_USERNAME>" # can also use GitHub registry

# <NAME> directory and <NAME>.yml is created
```

At this point you can build, push and deploy the function

## Troubleshooting Functions

View functions and their logs:

```console
$ kubectl get deploy -n openfaas-fn
NAME             READY     UP-TO-DATE   AVAILABLE    AGE
<FUNCTION_NAME>   0/1       1            0           11m
nodeinfo          1/1       1            1           7h3m

kubectl logs -n openfaas-fn deploy/<FUNCTION_ANME>
```

See if function failed to start:

```shell
kubectl describe -n openfaas-fn deploy/<FUNCTION_NAME>
```

### Debugging Functions
Run with Docker:
```shell
docker run --name debug-test-func \
  -p 8081:8080 -ti <DOCKER_HUB_USERNAME>/<FUNC_NAME>:latest sh
```

Start function when inside container:

```console
~ $ fprocess=./handler ./fwatchdog &
```

cURL the container:

```shell
curl -vvv --header "Content-Type: application/json" \
          --request POST \
          --data '{"key":"value"}' \
          127.0.0.1:8081
```

Setting timeouts for function:

```yaml
functions:
    func_name:
      ...
      environment:
          read_timeout: 20
          write_timeout: 20
```

_See also (live debugging): <https://www.youtube.com/watch?v=iv57ctMc6g8>_


#### Resources
- <https://github.com/openfaas/templates/blob/master/template/dockerfile/function/Dockerfile>
- <https://rancher.com/docs/k3s/latest/en/configuration/>
- <https://blog.alexellis.io/test-drive-k3s-on-raspberry-pi/>
- <https://github.com/openfaas-incubator/ofc-bootstrap>
- <https://github.com/openfaas/faas-cli/blob/master/guide/TEMPLATE.md>
- <https://docs.openfaas.com/deployment/troubleshooting/#function-execution-logs>
