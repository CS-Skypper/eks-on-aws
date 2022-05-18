## 1. Create an AWS user with high privileges
1. IAM
   1. Users / New User
      1. User name: terraform-operator
      2. Access type: Programmatic access
   2. Attach existing policy:
      1. Administrator Access
   3. take note of the Access key ID and the Secret Access Key ID
      1. used to configure aws cli


## 2. Install AWS cli & configure it to use locally the user
```bash
docker-compose run --rm aws configure --profile terraform-operator
```


## 3. Configure Terraform to use AWS user with the AWS provider
User: terraform-operator
Access key ID
   -  ```
      XXXXXXXXXXXXXXXXXXXX
      ```
   -  ```
      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      ```

## 4. VPC module
- [VPC module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
   - `terraform init` after referencing the module inside the [main.tf](./main.tf)
   - `terraform validate` -> syntax check
   - `terraform plan` -> to make a preview of our changes
   - `terraform apply` -> prompt to ask to apply the cfg
## 5. EKS module
- [EKS module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [example files](https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/)
  - [define a launch template within terraform](https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/examples/launch_templates/main.tf)
### 5.1 Verify that the worker nodes do joined the cluster
- By default the user who creates the cluster is authorized to access it
  - [AWS_PROFILE: terraform-operator](./docker-compose.yaml)
- Once the cluster is created Terraform will paste the kubeconfig access cert and a config-map-aws-auth_awesome.yaml and who ever assumes the **rolearn** becomes a cluster node. Terraform assigns the role arn to the instances that creates.
- 1. `kubectl get all --all-namespaces`
- 2. `kubectl get nodes`
   - by default the new "worker nodes" are not authorized to comunicate with the master nodes so we have to apply the config-map-aws-auth_awesome.yaml to the cluster
     - `kubectl apply -f config-map-aws-auth_awesome.yaml`

_[I love destroying infra resources whenever I don't need them. This is the most cost-effective architecture : Dealing with your infra as Cattle not as Pets.](https://www.udemy.com/course/aws-eks-kubernetes/learn/lecture/18431070#:~:text=I%20love%20destroying%20infra%20resources%20whenever%20I%C2%A0don%27t%20need%20them.%20This%20is%20the%20most%20cost-effective%20architecture%20%3A%C2%A0Dealing%20with%20your%20infra%20as%20Cattle%20not%20as%20Pets.)_

#### output
- [terraform apply](../../notes/output/terraform-apply.md)
- [terraform destroy](../../notes/output/terraform-destroy.md)


## EKS authentication and authorization - kubectl
With EKS kubeconfig does not include user credentials instead it includes the definition of the command line that should be invoked
`aws-iam-authenticator token -i clusterName`
then kubectl parse the auth token from the request.
So one can use the already present IAM users/role instead of creating new ones inside kubernetes

- `config-map-aws-auth_awesome.yaml`
  - contains a map of IAM identities to Kubernetes users
  - it must exist in every EKS cluster, in the kube-system namespace
  - [theory](https://www.udemy.com/course/aws-eks-kubernetes/learn/lecture/16863350#overview)
---
- EKS authentication is delegated to AWS IAM service
  - to authenticate an AWS user to k8s cluster the arn of the user must be added to the `config-map-aws-auth_awesome.yaml` and bind it to a kubernetes user name
    - how?
      - terraform eks module -> map_users
- EKS authorization is handles by Kubernetes RBAC


### [EKS Authentication](https://www.udemy.com/course/aws-eks-kubernetes/learn/lecture/16863362#overview)
  1. Create an IAM programmatic access user
     1. `auditor-1`
        1. `XXXXXXXXXXXXXXXXX`
        2. `XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`
  2. Configure aws cli with the keys
  3. Check Terraform [EKS Module doc](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest?tab=inputs)
     1. [map-user](./main.tf) - _Additional IAM users to add to the aws-auth configmap_
  4. You can override docker-compose .env values on the command line
     1. `EKS_AWS_PROFILE=auditor-1 docker-compose run --rm kubectl get nodes`
  5. You can check for reference the default [variables.tf](.terraform/modules/eks/variables.tf) template file of the **EKS module**. So I made the [variables.tf](./variables.tf)
     1. and referenced it inside the [main.tf](./main.tf)
  6. After applying the changes to the infrastructure with `terraform apply`, terraform will automatically update the [config-map-aws-auth_awesome.yaml](); so we would have to apply again the config map:
     1. `kubectl apply -f config-map-aws-auth_awesome.yaml`
  7. Now test with `EKS_AWS_PROFILE=auditor-1 docker-compose run --rm kubectl get nodes`
     1. The user is authenticated but not authorized to perform any kind of actions inside the Kubernetes Cluster

### [EKS Authorization](https://www.udemy.com/course/aws-eks-kubernetes/learn/lecture/16894416#overview)
   1. Create a Cluster role binding, check [Kubernetes docs](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#clusterrolebinding-example)
   2. `kubectl apply -f audit-team-view.yaml`
      1. [audit-team-view.yaml](audit-team-view.yaml)
   3. Update `groups` inside [variables.tf](variables.tf)
   4. `terraform-apply`
   5. That will modify, again, the [config-map-aws-auth_awesome.yaml](./config-map-aws-auth_awesome.yaml)
      1. so it need to be re deployed
         2. `kubectl apply -f audit-team-view.yaml`
