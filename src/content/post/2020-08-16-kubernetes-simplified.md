+++
author = "Ryan Heywood"
title = "Kubernetes - Simplified"
date = "2020-08-16 21:57:03 -0500"
description = ""
tags = ["simplified", "kubernetes", "docker"]
featured = true
+++

*This article assumes a basic knowledge of Docker.*

This is the first article in a series of posts called "Simplified", where I
take a look at systems that I think aren't adequately explained in their own
"getting started" documentation. Today, I'm taking a look at one of the most
complicated systems I've used to date.

<!--more-->

## What the Fuck is Kubernetes?

Kubernetes is self described as an "open-source system for automating
deployment, scaling, and management of containerized applications".[1] While
I think this is mostly true, it also undersells the power of Kubernetes.
Because of the many features that Kubernetes (k8s) has, and the depth of the
"Kubernetes Basics"[2] pages, it is often seen as an overwhelming unachievable
goal.

In my own words, Kubernetes is a system with a collection of user-provided
resource configurations that when configured and deployed will automatically
manage those resources.  Resources in Kubernetes can be anything as simple as a
network policy allowing inbound traffic to a service[3], or as complicated as
an automatically scaling Prometheus instance[4].

Resources, whose configuration files are called "Manifests", can be defined as
either JSON or YAML. For the sake of simplicity, this guide will use YAML.

## Why would I want Kubernetes? Is it worth it?

Kubernetes will automatically manage your resources for you. If configured
correctly, it can survive even if a "node", or a server in the cluster, becomes
unaccessible, with no input required from the user. Kubernetes through some
service providers can scale up workloads to massive amounts temporarily, which
can be incredibly useful if your service becomes very popular and you suddenly
gain a lot of traffic.

Running a Kubernetes system means you can reduce your downtime to an insanely
small level, and increase your computational capacity to an insanely large
level. While this may not seem useful up front, you may consider it essential
down the line.

#### Why not just use Docker Compose?

Docker Compose is a software that I have a reasonable amount of experience with
but at times I commonly notice that I'm continuing to add stuff on top of my
container images just to get them to work properly.

Docker Compose does not survive a machine failure, or a node that has been
made unrecoverable. If you lose the machine that Docker-Compose runs on, you
have now lost all the information in that Docker-Compose system.

Kubernetes has multiple implementations, provided by DigitalOcean, Linode, AWS,
GCP, Azure, as well as some bare-metal implementations such as [kind] and
[minikube] for testing, and [microk8s] and [k3s] for production machines.
These implementations allow for better integration with Kubernetes in a way
that can - most times - survive the loss of a node.

### Setting up a Cluster

If you'd like to follow along with this guide, I heavily recommend using the
program [kind], as it will let you deploy Kubernetes manifests locally. You can
test that your cluster is working by using the command `kubectl version`.

#### Where is the State?

When deploying a Manifest to Kubernetes, the basics of the interaction is that
POST requests are made to Kubernetes REST endpoints, creating the resources and
storing them in an etcd key-value distributed storage.

## Hello World

The universal sign of someone's first program is to say "Hello World". We're
going to set up the Docker container "nginxdemos/hello". We first need to
start the program in our cluster. To do this, we can set up one of three
things:

- a pod
- a replicaset
- a deployment

### What is a Pod?

Defined as a Kubernetes concept, a pod is "a group of one or more containers
with shared storage/network resources", as well as the configuration required
for running those containers[6]. It is the smallest computational unit for
Kubernetes; if you want to deploy a single container, you can deploy it in a
pod.

Pods do not automatically restart, and when they die, they are automatically
deleted from Kubernetes completely. This means that they are not a good option
for declarative configuration.

We can make a pod for our cluster, but it will be removed from existence if it
crashes. This means it is not a good resource for our use-case (as we can
instead delete a resource ourselves later if we really want it gone).

### What is a ReplicaSet?

Defined as a Kubernetes concept, a replica set is "[a resource whose] purpose
is to maintain a stable set of replica Pods running at any given time"[7].
Its sole purpose is to make sure that a certain quantity of pods is running
at once.

ReplicSets have an optional "template" that can be used for creating new pods.
The template will be used as the basis of the pod's configuration, along with a
label that is used for tracking the pod. All pods that match the labels used
by the ReplicaSet will be "adopted" by the ReplicaSet.

ReplicaSets should not be managed by hand, due to their nature of adopting
Pods that match labels defined by the ReplicaSet. While we will not be doing
advanced configuration in this guide, it is not a good idea to use a
ReplicaSet, as the ReplicaSet does not ensure that Pods match the configuration
that the ReplicaSet creates them with.

## What is a Deployment?

Defined as a Kubernetes concept [one I think is misnamed], a Deployment
provides declarative updates for ReplicaSets[8]. A more appropriate description
is that when a Deployment is updated, a ReplicaSet is created with the
appropriate configuration to make sure Pods are deployed with the desired
specification template.

A Deployment creates ReplicaSets with certain labels to make sure the
ReplicaSet only knows about pods made with its own configuration. This makes
them useful for gradual rollouts, so services can use an older version of a
ReplicaSet (with an old version of some software) while a new version is being
set up by the deployment, creating a low - if not zero - downtime system.

---

For our use case, we will be using Deployments. Manifests in Kubernetes require
a few specific fields to tell the Kubernetes controller how to create the
required resources. The fields are `apiVersion`, `kind`, `metadata`, and
`spec`[9]. For a Deployment, the API Version is `apps/v1`, the Kind is a
"Deployment", the metadata will contain the name of the resource, and the
spec will contain the configuration for that resource. We can also use a label
to assign a name to our app, commonly the type of software used.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-hello-world
  labels:
    app: nginx
spec:
```

The specification for deployments[8] specifies that we need an amount of
replicas (how many pods of our container we want running), a selector to
determine how to find our pods, and a specification for the pod.

Selectors are required because the Deployment doesn't know how to find pods
that are managed by the ReplicaSet. We can define some labels for our Pods and
use those labels with our selector so the Deployment can track its own pods.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-hello-world
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
```

The `spec` portion of the template defines the specification used when
creating pods. We will make one container using the `nginxdemos/hello`
image[10] and allow traffic on port 80.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-hello-world
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginxdemos/hello
        ports:
        - containerPort: 80
```

You can apply the following configuration file by saving it to a file, such as
"k8s-nginx-deployment.yaml", then running `kubectl apply -f
k8s-nginx-deployment.yaml`. Once that is finished, you should be able to run
the command `kubectl get all` and see a Deployment, which has made a
ReplicaSet, which has made a Pod. *You may also see a Kubernetes service. This
is important, but not relevant to our Deployment.*

You can also now kill your pod using `kubectl delete <your pod here>`. It will
be automatically recreated by the ReplicaSet. To ensure a high availability of
the service, you may consider increasing replicas to 2 or more.

## Accessing our Deployment

Kubernetes by default does not expose your applications publicly. We will need
to create a linking between our pods and the outside system - in this case,
the system you're testing on.

A Service is another type of Kubernetes resource, "an abstract way of exposing
an application running on a set of Pods as a network service"[11]. The various
forms of Services can allow your Pods to be accessible from inside the cluster
(like a microservice) or accessible from an "external" IP (when using `kind`,
this could be your system's localhost).

Similarly to the `selector` field in the above Deployment, we can give our
Service a selector to the pods. Unlike the Deployment selector, we can only
match the exact labels (this is similar with the now-deprecated
ReplicationControllers):

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-incoming-http
spec:
  selector:
    app: nginx
```

We can now define the port that is externally visible. The `port` field is the
externally accessible port, and the `targetPort` is the port on the pod. The
`type: NodePort` option specifies that it will open a port on the Nodes running
the Pods. In the future, this article may include information how to set up an
IP address for the Service and future articles may include a Simplification of
how the LoadBalancer type and Ingress resources work.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-incoming-http
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 80
  type: NodePort
```

You can now open up a port on your system using `kubectl` to forward requests
to your Service: `kubectl port-forward svc/nginx-incoming-http 8080`. You
can now open your web browser and go to `http://localhost:8080` and view the
example page. Alternatively, you can use the format `local:remote` when
specifying the IP addresses for port-forward.

---

This article is a live post and will be updated if amendment is needed to
clarify explanations of certain topics.

EDIT-2020-08-17: Add sections "Why would I want Kubernetes", "Why not just use
Docker Compose", and "Where is the State"

[1]: https://kubernetes.io/#kubernetes-k8s-docs-concepts-overview-what-is-kubernetes-is-an-open-source-system-for-automating-deployment-scaling-and-management-of-containerized-applications
[2]: https://kubernetes.io/docs/tutorials/kubernetes-basics/
[3]: https://docs.cilium.io/en/v1.8/policy/language/#services-based
[4]: https://github.com/prometheus-operator/prometheus-operator
[5]: https://kind.sigs.k8s.io/docs/user/quick-start/
[6]: https://kubernetes.io/docs/concepts/workloads/pods/
[7]: https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/
[8]: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
[9]: https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/
[10]: https://hub.docker.com/r/nginxdemos/hello
[11]: https://kubernetes.io/docs/concepts/services-networking/service/
[kind]: https://kind.sigs.k8s.io/
[minikube]: https://minikube.sigs.k8s.io/docs/
[microk8s]: https://microk8s.io/
[k3s]: https://k3s.io/
