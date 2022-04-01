# transformer-k8s-ingress-nginx

### Overview
This project provides an example of deploying [StreamSets Transformer Engine](https://streamsets.com/products/dataops-platform/transformer-etl-engine/) on Kubernetes using an [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) Ingress Controller for use with [StreamSets DataOps Platform](https://streamsets.com/products/dataops-platform/)

### Prerequisites
* API Credentials for an admin account on DataOps Platform
* [jq](https://stedolan.github.io/jq/) must be installed on the machine where this project's scripts are run
* [uuidgen](https://man7.org/linux/man-pages/man1/uuidgen.1.html) must be installed on the machine where this project's scripts are run


### Deploy the Ingress Controller
Follow the steps [here](https://kubernetes.github.io/ingress-nginx/deploy/) to deploy ````ingress-nginx```` on your cluster.  If your Kubernetes cluster is on a public cloud, use a Load-Balancer type deployment, else use a NodePort. For this example I will deploy on GKE using a Load-Balancer type Ingress Controller.


### Get the Ingress Controller's External IP
After you have deployed the Ingress Controller, get its external IP:

  <img src="images/nginx-service-ip.png" width="70%">

### (Optional) Create a DNS entry for the Ingress Controller's External IP 
To use a hostname rather than an IP address for the Transformer URL, assign an FQDN to the Ingress Controller's external IP by adding an entry to your DNS.  For example, I'll assign the name ````streamsets.onefoursix.com```` to my Ingress Controller's IP address.  If you don't have access to a DNS, you can skip this step and just use the Ingress Controller's IP address instead.

### Clone this project to your local machine
Clone this project to your local machine in order to edit the deploy script and manifests.

### Edit the deploy.sh script
Edit the ````deploy.sh```` script and set these variables at the top of the script (see below for details):

````
# Control Hub Org ID
SCH_ORG_ID=<YOUR ORG ID>

# Control Hub Base URL (with no trailing slash)
# Typically https://na01.hub.streamsets.com
SCH_URL=<CONTROL HUB URL>

# Control Hub user CRED ID 
CRED_ID=<YOUR CRED ID>

# Control Hub user CRED TOKEN 
CRED_TOKEN=<YOUR CRED TOKEN>

# The Kubernetes namespace to deploy Transformer in 
# The namespace must exist in advance
KUBE_NAMESPACE=<YOUR NAMESPACE>

## Set the URL for Transformer as it will be exposed through the Ingress Controller
## It is recommended to use path-based routing (see below for an example)
TRANSFORMER_EXTERNAL_URL=<YOUR TRANSFORMER INGRESS URL>
````

Important points:

* The ````CRED_ID```` and ````CRED_TOKEN```` should be generated for a Control Hub Account with Provisioining Role, typically an administrator.

* The Kubernetes Namespace must exist in advance.

* The ````TRANSFORMER_EXTERNAL_URL```` must correspond to the Ingress Controller's base URL plus the path-prefix to the Transformer instance as set in the ````ingress.yaml```` (see below). For this example I'll use the url ````http://streamsets.onefoursix.com/transformer````

### Edit transformer.yaml

Edit the file ````yaml/transformer.yaml```` and set the version of Transformer to use. For example, for Spark 3.x clusters that require Scala 2.12, set:

 ```` image: streamsets/transformer:scala-2.12_4.2.0```` 
 
 or for Spark 2.x clusters that require Scala 2.11, set 
 
```` image: streamsets/transformer:scala-2.11_4.2.0````

See the [Cluster Compatibility Matrix](https://docs.streamsets.com/portal/platform-transformer/latest/transformer/Installation/Install-Reqs.html#concept_yyv_s5y_5pb) for details.

### Edit ingress.yaml

By default the path prefix is set to ````/transformer````.  This path prefix will be appended to the base URL of the Ingress Controller to match the value set in the ````deploy.sh```` script's ````TRANSFORMER_EXTERNAL_URL```` variable, which in my environment is ````http://streamsets.onefoursix.com/transformer````.

### Execute the deploy.sh script
Execute the ````deploy.sh```` script.  You should see output like this:

````
$ ./deploy.sh
Context "gke_streamsets-onefoursix_us-west1-a_cluster-1" modified.
secret/streamsets-transformer-creds created
configmap/streamsets-transformer-config created
serviceaccount/streamsets-transformer created
role.rbac.authorization.k8s.io/streamsets-transformer created
rolebinding.rbac.authorization.k8s.io/streamsets-transformer created
persistentvolumeclaim/streamsets-transformer-pvc created
deployment.apps/transformer created
service/transformer created
ingress.networking.k8s.io/transformer created
````

### Confirm that Transformer is heartbeating to Control Hub
After a minute or so, you should see the instance of Transformer has registered and is heartbeating to Control Hub:

  <img src="images/transformer-heartbeat.png" width="70%">

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


