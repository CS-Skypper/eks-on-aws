## k3s in container
[K3d - How to run Kubernetes cluster locally using Rancher k3s](https://youtu.be/mCesuGk-Fks)
[Local Dev with KinD](https://www.youtube.com/watch?v=FGCRh_k9JoI)

### install k3d binary
  ```bash
  wget -q -O - https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
  ```

  - Specify the version of Kubernetes
```
k3d cluster create my-cluster --image rancher/k3s:v1.20.4-k3s1
```

### k3d commands
  **might have to unset KUBECONFIG sometimes**
  - `k3d cluster create demoNoTraefik --k3s-arg "--disable=traefik@server:*" --servers 3 --agents 3`
    - to not use traefik as ingress controller
  - `k3d kubeconfig merge demoNoTraefik --output ~/.kube/config`
    - merge configs, upon cluster deletion it removes the config
  - `k3d completion zsh`
  - `k3d cluster start my-cluster`
  - `k3d cluster stop my-cluster`
  - `k3d kubeconfig get my-cluster > my-cluster_kubeconfig.yaml`
