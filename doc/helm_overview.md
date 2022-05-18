### Why Helm?
  - treat, organize, parameterize, .YAML files as code


### Helm commands
  - `helm create hello-chart` -> creates a sample template chart
  - `helm install myapp hello-chart` -> deploys the `myapp` following the `hello-chart` helm chart

### next
  - create the `nshello` namespace
    - `kubectl create ns nshello`
  - deploy the helm chart
    - `helm install my-app hello-chart --namespace nshello`
    - the helm chart povide some notes on how to acces the web application, check the output of the command
      - ```bash
        export POD_NAME=$(kubectl get pods --namespace nshello -l "app.kubernetes.io/name=hello-chart.app.kubernetes.io/instance=myapp" -o jsonpath="{.items[0].metadata.name}")
        ```
  - list the helm chart
    - `helm list --namespace nshello`
  - reach thte web app
    - ```bash
      kubectl --namespace nshello port-forward $POD_NAME 8090:80 --address 0.0.0.0
      ```
    - [localhost:8090](localhost:8090)

### Upgrade a Helm release
What if we would want to use apache instead of nginx as web server?
  - update helm template files like:
    - [deployment.yaml](./hello-chart/templates/deployment.yaml)
      - ```yaml
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        ```
    - check dockerhub for values
      - [values.yaml](./hello-chart/values.yaml)
      - [Chart.yaml](./hello-chart/Chart.yaml)
  - upgrade the chart
    - `helm upgrade myapp hello-chart --namespace nshello`
  - check out the output of the command and apply export again the POD_NAME variable

**Important _obvious_ note**
  - values.yaml must be customized with the default values for the given context where will be running Kubernetes
    - in this case: AWS EKS
### Install metrics-server
  - metrics-server [values.yaml](./charts/metrics-server/values.yaml)
  - [helm chart](https://artifacthub.io/packages/helm/metrics-server/metrics-server)
  - [AWS Doc](https://docs.aws.amazon.com/eks/latest/userguide/metrics-server.html)

### Install Cluster-Autoscaler
  - Cluster-Autoscaler [values.yaml](./charts/cluster-autoscaler/values.yaml)
  - [helm chart](https://artifacthub.io/packages/helm/cluster-autoscaler/cluster-autoscaler)
  - [Note about Cluster-Autoscaler](https://www.udemy.com/course/aws-eks-kubernetes/learn/lecture/18432010#overview)

### Install Ingress Controller Ingress-Nginx
  - Ingress-Nginx [values.yaml](./charts/ingress-nginx/values.yaml)
  - [helm chart](https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx)
  - ```bash
    helm install my-ingress-nginx ingress-nginx/ingress-nginx --version 4.0.9 --namespace kube-system -f notes/helm_overview/charts/ingress-nginx/values.yaml
    ```
