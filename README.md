# transformer-k8s-ingress-nginx

### Overview
This project provides an example of deploying one or more instances of [StreamSets Transformer Engine](https://streamsets.com/products/dataops-platform/transformer-etl-engine/) on Kubernetes using an [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) Ingress Controller for use with [StreamSets DataOps Platform](https://streamsets.com/products/dataops-platform/). Multiple instances of Transformer can be installed within the same namespace, or across multiple namespaces. This example will install three instances of Transformer within the same namespace.

### Prerequisites
* API Credentials for an admin account on DataOps Platform
* [jq](https://stedolan.github.io/jq/) must be installed on the machine where this project's scripts are run
* [uuidgen](https://man7.org/linux/man-pages/man1/uuidgen.1.html) must be installed on the machine where this project's scripts are run
* [envsubst](https://linux.die.net/man/1/envsubst) must be installed on the machine where this project's scripts are run. Most systems will have ````envsubst```` installed by default.
* The [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) Ingress Controller must be installed in advance (see below)
* The Kubernetes namespace must be created in advance (see below) 

### Deploy the Ingress Controller
Follow the steps [here](https://kubernetes.github.io/ingress-nginx/deploy/) to deploy ````ingress-nginx```` on your cluster.  If your Kubernetes cluster is on a public cloud, use a Load-Balancer type deployment, else use a NodePort. For this example I will deploy on GKE using a Load-Balancer type Ingress Controller.


### Get the Ingress Controller's External IP
After you have deployed the Ingress Controller, get its external IP:

  <img src="images/nginx-service-ip.png" width="70%">

### (Optional) Create a DNS entry for the Ingress Controller's External IP 
To use a hostname rather than an IP address for the Transformer URL, assign an FQDN to the Ingress Controller's external IP by adding an entry to your DNS.  For example, I'll assign the name ````streamsets.onefoursix.com```` to my Ingress Controller's IP address.  If you don't have access to a DNS, you can skip this step and just use the Ingress Controller's IP address instead.

### Create the Kubernetes Namespace
For this example I will create the namespace ````ns1````

````$ kubectl create ns ns1````

### Clone this project to your local machine
Clone this project to your local machine. I'll download the project to my machine at ````~/transformer-k8s-ingress-nginx````

### Set values in conf.sh
Edit the ````conf/conf.sh```` script and set these environment variables (see below for details):

````
# Control Hub Base URL (with no trailing slash)
# Typically https://na01.hub.streamsets.com
SCH_URL=https://na01.hub.streamsets.com

# Control Hub Org ID
SCH_ORG_ID=<YOUR ORG ID>

# Control Hub user CRED ID 
CRED_ID=<YOUR CRED ID>

# Control Hub user CRED TOKEN 
CRED_TOKEN=<YOUR CRED TOKEN>

## Load Balancer HostName or IP
LOAD_BALANCER_HOST_NAME=<YOUR LOAD BALANCER HOSTNAME OR IP>
````

Important points:

* The ````CRED_ID```` and ````CRED_TOKEN```` should be generated for a Control Hub Account with Provisioining Role, typically an administrator.


* The ````LOAD_BALANCER_HOST_NAME```` must correspond to the Ingress Controller's External IP or hostname as described above. For this example I'll use the hostname ````streamsets.onefoursix.com````


### Deploy a single instance of Transformer
To deploy a single instance of Transformer, execute the script ````deploy-transformer.sh```` with the following arguments (in order):
* transformer-namespace
* transformer-name 
* transformer-image 
* port-number
* transformer-labels

For example:
````
$ ./deploy-transformer.sh ns1 transformer streamsets/transformer:scala-2.12_4.2.0 19630 transformer,dev
````

That command will deploy an instance of Transformer 4.2.0 using the Scala 2.12 image into the namespace ````ns1```` with the Ingress path prefix ````transformer````, with a Service port of ````19630````, and with the Labels ````transformer```` and ````dev````.

You should see output like this:
````
./deploy-transformer.sh ns1 transformer streamsets/transformer:scala-2.12_4.2.0 19630 transformer,dev
Deploying transformer in namespace ns1...
Using existing namespace ns1
Context "gke_streamsets-onefoursix_us-west1-b_cluster-1" modified.
secret/transformer-creds created
Looking for existing Service Accounts...
Creating Service Account streamsets-transformer-sa
serviceaccount/streamsets-transformer-sa created
Looking for existing Roles...
No resources found in ns1 namespace.
Creating Role streamsets-transformer-role
role.rbac.authorization.k8s.io/streamsets-transformer-role created
Looking for existing RolesBindings...
No resources found in ns1 namespace.
Creating Role Binding streamsets-transformer-rb
rolebinding.rbac.authorization.k8s.io/streamsets-transformer-rb created
configmap/transformer-config created
persistentvolumeclaim/transformer-pvc created
deployment.apps/transformer created
service/transformer created
ingress.networking.k8s.io/transformer created
Done
````

### (Optional) Deploy additional instances of Transformer

I'll deploy two more instances of Transformer into the same namespace. 

When deploying more than one instance, make sure to observe the following:

* Each instance's ````transformer-name```` value must be unique
* Each instance's ````transformer-port````must be unique 
 
For example, I'll install instances with the names ````transformer2```` and ````transformer3````, on ports ````19631```` and ````19632```` respectively, using these two commands:

````
$ ./deploy-transformer.sh ns1 transformer2 streamsets/transformer:scala-2.12_4.2.0 19631 transformer,dev

$ ./deploy-transformer.sh ns1 transformer3 streamsets/transformer:scala-2.12_4.2.0 19632 transformer,qa
````
Note that ````transformer3 has the Label ````qa```` rather than ````dev````.

### Confirm that all deployed instances of Transformer are heartbeating to Control Hub
After a minute or so, you should see all deployed instances of Transformer are heartbeating to Control Hub, with the specified Labels:

  <img src="images/t3.png" width="70%">


### Confirm that Transformer is Accessible
Create a new pipeline and make sure Transformer is accessible for Authoring:

  <img src="images/authoring-transformer.png" width="70%">

### Create and Run a Pipeline on Local Spark
Create and run a pipeline on local Spark (which uses the Spark tarball packaged in the Transformer container):

  <img src="images/local-spark.png" width="70%">
  
You should see metrics and status in the UI:

  <img src="images/local-spark-2.png" width="70%">

### Create and Run a Pipeline on a remote Spark Cluster 
Create and Run a Pipeline on a remote Spark Cluster to confirm the callback URL is reachable.  For example, I'll run the same pipeline on Databricks and see the status and metrics returned from Databricks:

  <img src="images/databricks.png" width="70%">


