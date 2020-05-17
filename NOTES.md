# OLD


Since these services are usually going to be low-traffic and do not require HA, they should be able to share compute/storage resources to minimize cost. However, they should be able to scale if necessary without being completely rewritten.

The infrastructure is not expected to be vendor agnostic. However, as much as possible it should be developed using Infrastructure-as-Code principles. This is because the code serves as a form of documentation and "backup" for the services.

Services are expected to be stateless and to have their interface with the environment defined as explicitly as possible via Docker. State is to be stored exclusively in:

- A Postgresql database in a shared database cluster.
- A resilient object store (e.g. AWS S3).


Because of the cost efficiency and simplicity of their services, I have chosen Digital Ocean as a hosting provider for these services. However, they should eventually be self-hosted, and will be designed as much as possible with self-hosting in mind.

Whether hosted on DO or self-hosted, the services will be managed with Kubernetes.

For simplicity, in the future the shared Postgresql database cluster will simply be called "Postgresql" or "the database". The resilient object store will be called "Spaces" or "the object store".

## Setup Tooling

Part of the intent of this system is to make it easy to deploy individual projects. Therefore, this same model is also used to deploy this project itself.

To setup the project, you first need to bootstrap the CI/CD pipeline. Then you can deploy this repository with the pipeline, thereby creating everything else automatically.

### Install Gitea

Gitea is an open-source, self-hosted Git service.

Gitea was chosen because it has low operational overhead and resource usage.

### Install Concourse

Concourse is an open-source, self-hosted "task runner" that we can use for CI/CD.

Concourse has both a Web and Worker component, but the `concourse/concourse` Docker image bundles both of them together. Since CI/CD is not considered a HA service, only a single Concourse container is needed.

### Connect Concourse and Gitea




## Not-Internet Usage

1. Be _self-sufficient_: able to survive without Internet.

Running without Internet requires hosting local copies of a few cloud services that are normally taken for granted.

1. Docker Registry.
1. Any package repositories.

Internet is still required for initial installation and setup of most services. This system isn't targetting "air-gapped" clusters that can't connect to the Internet. Instead, the intent is to build a system which is Internet-connected, but will continue to work if the Internet goes down for an extended period.



# TODO

- [ ] Shared, air-gappable block storage
- [ ] VPN
- [ ] HTTP application proxy


# Introduction

The `personal-infrastructure` project provides scripts and configurations for deploying personal projects using Kubernetes. 

Goals:

- **Cost Effective:**
- **Low Friction:** Deploying new projects should be easy and "nearly free."
- **Security First:**

## Rationale

### Cost Sharing



## Target Audience

This repository is intended for individuals who:

1. Have multiple (3+) projects/services they want to deploy.
2. Want to use containerization to manage project deployments.
3. Want to allow projects to share compute and storage resources to minimize costs.
4. Are concerned about security, but not enough to spend significant extra money.
5. Want to have complete ownership over your project's deployment platform.

## Costs

Hosting basic Kubernetes cluster plus persistence costs at least $25/month to host in the cloud.

Alternatively, the system could be run on one or more computers that you own and manage in your home.

## Required Functions

- Constructing "digest emails" from Reddit, Hacker News, and other sites.
- Providing Push Notifications based on webhooks for defined events
- Git repository hosting (Public and private)
- Hosting static websites / blogs / wikis
- Provide shared folder sync across devices (Syncthing)
- Providing alternative to Google Analytics (Piwik)
- RSS Feed Reader (Miniflux)
- Run timed jobs at regular intervals.

There should also be support services, which are used to manage the overall cluster:

- Metrics / Monitoring service

## Security First

Personal infrastructure services fall into one of three categories:

- Shared / utility services. Not intended to be used directly, but to be referenced by other deployments.
- Private services. Tools for personal use, e.g. Fathom Analytics.
- Public services. Either websites or webhooks that need to accept requests from the Internet.

Utility services are exposed as ClusterIP Services in k8s, which are internal to the cluster.

Private services are also exposed with ClusterIPs, which means dashboards, etc. are not available on the public Internet. They require a VPN connection.

## Services

- [ ] Syncthing service? (Something to sync to/from Spaces)
- [ ] Personal Wiki / PIM? (Requires Postgresql + Spaces?)
- [ ] Analytics service, e.g. Piwik (Requires Postgresql)
- [ ] Huginn (Requires Postgresql)
- [ ] Personal websites / projects (May require Postgresql and/or Spaces)

## Optional (Not Recommended)

The following common tools are deliberately excluded from the base `personal-infrastructure` distribution:

- K8s Dashboard
- Helm
- Istio

### Kubernetes Dashboard

1. Potential security risk if improprly configured.
1. Encourages ad-hoc changes, which are damaging to IaC effectiveness.


### Helm

1. Benefits of Helm.
    1. All Kubernetes resources and configuration needed for each individual project can be encapsulated into a unit called a "chart."
        1. Charts provide a higher-level abstraction than Docker images but attemt to offer a similar vision -- a package  that can be automatically deployed.
    1. Charts can include other charts as dependencies.
    1. There is a public registry of charts.
    1. Charts impose a consistent pattern for configuring k8s resources.
1. Costs of Helm.
    1. Encourages deployments of charts without understanding the resources being created.
    1. Requires `tiller` server to run in your cluster.


### Istio

# Usage Instructions

## VPN

Note -- the following VPN setup is temporary, should use a diferent place for the certs.

Set the `node-type` label to `vpn` on a single node that you want to be the VPN. This node is going to have a folder created in `/mount` that contains the VPN certificates.

```
kubectl label nodes my-vpn-node role=vpn

kubectl apply -f ./k8s/shared/vpn
```




1. Set up your Kubernetes cluster. (Minikube, DO k8s, GCE, etc.)
    1. Tested with k8s versions: `v1.14.1`.
    1. Required extensions:
        1. CoreDNS
    1. Not Recommended Features/Extensions:
        1. Kubernetes Dashboard
        1. Helm
            1. Helm Installation
                1. Install CLI tool `helm` on your machine.
                1. Deploy Helm server `tiller` by running `helm init`.
        2. Istio
            1. Benefits of Istio
                1.  
    1. Ensure `kubectl` is configured properly. You should be able to run `kubectl cluster-info` and see both the cluster master and the CoreDNS extension.
    1. For DigitalOcean managed Kubernetes:
        1. Follow DO setup guide.
        1. Download and install `doctl` per DO instructions.
        1. Download and install `kubectl`. Ensure kubectl minor version matches cluster minor version.
        1. Run: `doctl kubernetes cluster kubeconfig save my-cluster-name`
1. Testing and diagnostic tips
    1. Creating a "scratch" container (a bash session running as a temporary pod, which cleans itself up automatically).
        1. `kubectl run scratch -i -t --rm --image=ubuntu --generator=run-pod/v1 -- /bin/bash`
    1. Connecting to an internal service from localhost:
        1. Assume service `foo` exposes traffic on port `3000`
        1. Run: `kubectl port-forward service/foo 3000`
        1. Now you can access `foo` service at `localhost:3000` in your browser
        1. Also works for pods, deployments, etc.
1. Set up and deploy shared resources
    1. VPN.
        1. Rationale. A VPN is used to provide another layer of security around accessing personal/internal HTTP dashboards.
        1. Technologies. OpenVPN is used via the `kylemanna/openvpn` Docker image.
            1. From https://gianarb.it/blog/cloud-native-intranet
        1. Requirements.
        1. Installation.
            1. `kubectl apply -f ./k8s/vpn`
    1. HTTP Proxy / API Gateway.
        1. Rationale. A self-managed HTTP proxy is used to allow public routes to be mapped to different services based on the request origin and path.
            1. This reduces the coupling between how services expose their HTTP interfaces, and the public network interface exposed by your cluster.
            1. Consider Huginn and Fathom. Using an HTTP proxy, we can allow incoming webhooks without allowing access to the dashboards outside of the VPN.
        1. Technologies. [Ambassador](https://www.getambassador.io/) was chosen for ease of use.
            1. Ambassador is a version of Envoy that is fully configurable with Kubernetes annotations, and intended for use as an API gateway.
    1. Private Docker Registry.
        1. Rationale. Docker images are required to deploy projects onto the cluster. Open-source images can be published to Docker Hub, but sensitive images must be published to a private registry.
            1. This system includes a private registry so it can continue working without Internet service. If that is not a concern, cloud alternatives like AWS ECR can be used.
        1. Technologies. Docker provides an official `registry` image.
            1. Repository images will be persisted to the shared object store.
        1. Requirements.
            1. Shared object store must be installed.
            1. `registry-s3` secret must be configured.
        1. Installation.
            1. `kubectl apply -f ./k8s/shared/registry`
    1. Postgresql Database Cluster.
        1. Rationale. Provides a place for services to store state. Required for numerous services to function.
            1. Shared database cluster is used to reduce costs.
        1. Technologies. Postgresql is used. MySQL could also be fine.
        1. Requirements.
            1. These instructions assume that your database is being hosted in an external RDBMS.
                1. For example, AWS RDS.
                1. Should be updated to describe self-hosted Postgresql for offline usage.
        1. Installation.
            1. `kubectl apply -f ./k8s/shared/postgresql`
    1. S3-Compatible Object Store.
        1. Rationale. Alternative persistence backend when storing data inappropriate for relational databases.
            1. Allows services to store binary data and files without using a data volume per service.
            1. S3 compatibility is valuable to allow open-source tools like Docker Registry to use it easily.
        1. Technologies. At the present time, an actual cloud-based solution like AWS S3 or DO Spaces is recommended.

          


## Postgresql Setup

For each service, create the user+database for that service with:

```
CREATE USER fathom WITH PASSWORD 'password';
GRANT fathom TO doadmin;
CREATE DATABASE fathom WITH OWNER fathom;
```

The Postgresql database is abstracted behind a service. Configure the service for your database, then:

```
kubectl apply -f k8s/postgresql
```

With that, our deployments can connect to Postgresql at `postgresql.default.svc.cluster.local` with port `25060`.


## Huginn

Deployed via `huginn-server` deployment in k8s. Connects to Postgresql via environment variables

```
kubectl create secret generic huginn-database --from-literal=username=huginn --from-literal=password=PASSWORD
kubectl create secret generic huginn-app --from-literal=token=TOKEN
kubectl create secret generic huginn-invite-code --from-literal=token=TOKEN
kubectl apply -R -f ./k8s/fathom
```

### Huginn Security

Some Huginn integrations depend on having the Huginn HTTP server available on the public Internet to receive webhook events. Therefore, Huginn is a public service.

## Fathom Analytics

See: https://github.com/usefathom/fathom


In database:

```
CREATE USER fathom WITH PASSWORD 'mypassword';
GRANT fathom TO doadmin;
CREATE DATABASE fathom WITH OWNER fathom;
```

In terminal:

```
kubectl create secret generic fathom-database --from-literal url=postgresql://fathom:PASSWORD@DB:PORT/fathom
kubectl apply -R -f ./k8s/fathom
```

Then, you can connect to the container with:

```
kubectl port-forward deployment/fathom 8080
```