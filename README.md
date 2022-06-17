# Premise
Personal capstone project merging together some technologies that I've been looking around.
We can see the creation of Kubernetes managed cluster (EKS) on AWS using Terraform. To enrich and automate the experience I used Helm Charts for deploying Ingress-Nginx as Ingress Controller, Metrics Server, Kube Prometheus Stack and Cluster Autoscaler. For the CI part I used Jenkins and for the CD part ArgoCD.
All around in a GitOps style.

In order to be cost-effetive, once created and configured the Kubernetes Control Plane (on the managed solution of AWS, EKS), using the Helm Charts and Terraform, I destroyed all the infrastructure previously created on cloud (`terraform destroy`) and moved to a local Kubernetes Cluster using [K3D](https://k3d.io/v5.4.1/) or [KIND](https://kind.sigs.k8s.io/) (out of fun and the sake of experimenting).

---

# Project goals
- Design & Run well-architected an AWS EKS Cluster based on High-Availability & Cost effectiveness
- DevOps Environment for Kubernetes Cluster
- Use Terraform as Infrastructure-as-Code to Provision the Kubernetes Cluster on AWS
- Use Helm as Infrastructure-as-Code to release Kubernetes applications
- Install Core Applications on Kubernetes Cluster like Prometheus, Grafana and others
- Authenticate to AWS EKS Cluster effectively
- Run CI pipeline using Jenkins with Production setup & Github integration
- ArgoCD for deploying into the Kubernetes Cluster

---

_few words on the project_
# EKS on AWS

## 1. Infrastructure creating
  1. using terraform

## 2. Customizing the infrastructure using Helm Charts
  1. Installed Ingress-Nginx Ingress type Controller
     1. ingress: what can come in
     2. egress: what can go outside of the cluster
     3. enabled HTTPS/SSL
        1. we need a certificate for that
  2. Installed Metrics Server
  3. Based on the Metrics one can setup a Cluster-Autoscaler
  4. Setup a Monitoring stack with Prometheus and Grafana
     1. So Prometheus can collect the metrics exposed by the Metrics-Server and can present them inside some Grafana Dashboards
     2. I used the kube-promethues-stack
        1. all the prometheus stack like server, agents etc
        2. there is also the Altert-Manager
        3. we have also Grafana

## 3. Continuous Delivery with ArgoCD
  1. its like an Operator

---

### Step 1 - Install Terraform
- [cli](https://learn.hashicorp.com/tutorials/terraform/install-cli) or [docker image](https://hub.docker.com/r/hashicorp/terraform)
  - ```bash
    docker run -it --rm hashicorp/terraform:0.12.12 --version
    ```
- check the following [instructions](./doc/auth-terraform-aws.md)
  

### Step 2 - Install Helm
- check the following [instructions](./doc/helm_overview.md)

### Step 3 - Create a local Kubernetes Cluster with K3D / KinD
   - [k3d](./../src/k3d)
   - create a cluster with k3d
     - `k3d cluster create -c k3d.yaml`
   - print the cluster kubeconfig
     - `k3d kubeconfig get my-cluster > ~/.kube/k3d-my-cluster`
       - [my-cluster_kubeconfig.yaml](./../src/k3d/my-cluster_kubeconfig.yaml)
   - [kind](./../src/k3d/k3d-demo/kind.yaml)

### Step 3 - Deploying Core applications before the other apps
#### 1. [Metrics-Server](https://github.com/helm/charts/tree/master/stable/metrics-server)
   1. it collects metrics of nodes and pods so it is mandatory to set up autoscaling policies

#### 2. [Cluster Autoscaler](https://github.com/kubernetes/autoscaler)
  1. it requires metrics-server
  2. [chart value used](./helm_overview/charts/cluster-autoscaler/values.yaml)
     1. [cluster-autoscaler chart](https://artifacthub.io/packages/helm/cluster-autoscaler/cluster-autoscaler)
     2. reference parameter tooked from [main.tf](./auth-tf-aws/main.tf)
  3. ```
      helm install cluster-autoscaler autoscaler/cluster-autoscaler --namespace kube-system -f notes/helm_overview/charts/cluster-autoscaler/values.yaml
     ```
  4. Setup an autosclaler group
     1. min and max capacity -> [main.tf](./auth-tf-aws/main.tf)

#### 3. Ingress Controller: [Ingress-Nginx](https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx)
  1. Exposes website pubblicly
  2. It's an Nginx web server which recieves HTTP/S requests from outside and it routes them to a specific server according to some rules called **Ingress Objects**

### 3. Enable HTTPS/SSL with Ingress
  1. **[lecture](https://www.udemy.com/course/aws-eks-kubernetes/learn/lecture/18311670#overview)**
  2. Create a cert with ACM, with DNS Verification
  3. Paste the ARN of the certificate in [values.yaml](./helm_overview/charts/ingress-nginx/values.yaml)
     1. aws-load-balancer
  4. ```bash
     helm upgrade my-ingress-nginx ingress-nginx/ingress-nginx --version 4.0.9 --namespace kube-system -f notes/helm_overview/charts/ingress-nginx/values.yaml
     ```

### 4. Monitoring with Prometheus and Grafana
  1. [lecture](https://www.youtube.com/watch?v=QoDqxm7ybLc) ; [Prometheus Exporter](https://www.udemy.com/course/aws-eks-kubernetes/learn/lecture/18430516#overview)
  2. [chart](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) ; [stack doc](https://github.com/prometheus-operator/kube-prometheus)
  3. Install prometheus comunity helm repo
     1. `helm repo add prometheus-community c`
  4. Create namespace `monitoring`
     1. `kubectl create ns monitoring`
  5. Install stack
     1. `helm install --create-namespace --namespace monitoring prometheus prometheus-community/kube-prometheus-stack`
  6. swap ns `kubectl config set-context --current --namespace monitoring`
  7. `kubectl get customresourcedefinitions.apiextensions.k8s.io  | grep monitoring`

#### How do you access Prometheus web UI?
  1. get the port from
     1. `kubectl get pod prometheus-prometheus-kube-prometheus-prometheus-0 -o yaml`
  2. `kubectl port-forward prometheus-prometheus-kube-prometheus-prometheus-0 9090`

#### Where are and how to modify Prometheus Rules?
  1. good question.
  2. `kubectl get pod prometheus-prometheus-kube-prometheus-prometheus-0 -o jsonpath='{..args}'`

#### Alert Manager?
  1. `kubectl get pod alertmanager-prometheus-kube-prometheus-alertmanager-0 -o yaml`
  2. `kubectl port-forward alertmanager-prometheus-kube-prometheus-alertmanager-0 9093`

#### How do you access Grafana web UI?
  1. `kubectl -n monitoring get pods`
  2. `kubectl logs prometheus-grafana-5cddc775c4-f62pj | less`
     1. search for
        1. `user= `
        2. running port (should be 3000)
  3. get grafana admin password
     1. `kubectl get secrets prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo`
     2. or [values.yaml](https://github.com/prometheus-community/helm-charts/blob/16ce4578270f05d4adaa639e310283c781d96004/charts/kube-prometheus-stack/values.yaml#L645)
        1. [link](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml#L645)
     3. or
        1. `kubectl get secrets prometheus-grafana -o jsonpath='{..admin-user}{"\n"}{..admin-password}' | base64 --decode`
  4. `kubectl port-forward deployment/prometheus-grafana 3000`

### 5. Integrate Nginx Ingress Controller with Prometheus
  1. [deploy doc](https://kubernetes.github.io/ingress-nginx/deploy/) ; [nginx  log and monitor doc](https://docs.nginx.com/nginx-ingress-controller/logging-and-monitoring/prometheus/)
  2. helm chart [values.yaml](https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx?modal=values&path=controller.metrics)
     1. by default metrics are disabled
     2. enabling `controller.metrics.serviceMonitor` will create a new Kubenernetes Object called ServiceMonitor
  3. added `metrics` block inside [ingress-nginx/values.yaml](./helm_overview/charts/ingress-nginx/values.yaml)
     1. populate additionalLabels with
        1. `kubectl get --namespace monitoring  pod --show-labels`
  4. upgrade the release
     1. `helm upgrade my-ingress-nginx ingress-nginx/ingress-nginx --version 4.0.9 --namespace kube-system -f notes/helm_overview/charts/ingress-nginx/values.yaml`
  5. check the new resource created
     1. `kubectl get -n monitoring servicemonitors.monitoring.coreos.com`
  6. Now the Ingress Nginx Apllication is exposing Prometheus metrics
  7. Add Grafana Dasboard for the Ingress
     1. [nginx doc](https://kubernetes.github.io/ingress-nginx/user-guide/monitoring/#:~:text=After%20the%20login%20you%20can%20import%20the%20Grafana%20dashboard%20from%20official%20dashboards%2C%20by%20following%20steps%20given%20below)
     2. Add new Grafana Dasboard
        1. `helm upgrade prometheus prometheus-community/kube-prometheus-stack --create-namespace --namespace monitoring -f notes/helm_overview/charts/kube-prometheus-stack/values.yaml`
        2. [Grafana Dashboard](https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/grafana/dashboards/nginx.json)

### 6. Setup ArgoCD
  1. [ArgoCD doc](https://argo-cd.readthedocs.io/en/stable/getting_started/) ; [lecture](https://www.youtube.com/watch?v=MeU5_k9ssrs)
  2. Install ArgoCD
     1. ```bash
        kubectl create namespace argocd
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        ```
  3. Access ArgoCD Web UI
     1. port forwarding
        1. `kubectl port-forward svc/argocd-server -n argocd 8080:443`
     2. Expose it through the [Ingress-Nginx](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#kubernetesingress-nginx) Ingress Controller
     3. [Login](https://argo-cd.readthedocs.io/en/stable/getting_started/#4-login-using-the-cli)
        1. `admin`
        2. `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
  4. Configure ArgoCD
  5. Create an `application.yaml` on the root of the desired Project to be deployed in Kubernetes
     1. reference [application.yaml](../src/argoCD/application.yaml) ; [doc](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#applications)
        1. this `Application` component will be created in the same namespace as ArgoCD
     2. the first time the [application.yaml](./../src/argoCD/application.yaml) must be applied manually
     3. [guestbook example](https://github.com/argoproj/argo-cd/blob/master/docs/operator-manual/application.yaml)
     4. appfiles
        1. [fib-calc-application.yaml](./../src/argoCD/fib-calc-application.yaml)
        2. [guestbook-application.yaml](../src/argoCD/guestbook-application.yaml)
