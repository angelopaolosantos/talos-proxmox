<a id="readme-top"></a>

[![LinkedIn][linkedin-shield]][linkedin-url]

# HA Kubernetes in Proxmox

## About the Project

<div align="center">
  <a href="https://github.com/othneildrew/Best-README-Template">
    <img src="images.png" alt="Logo">
  </a>
</div>

This project lets you run a Highly Available Kubernetes Cluster on a local Proxmox Server. I've added as much features as I know to test and learn several kubernetes configurations and applications. You may adjust the starting infastructure to your liking via terraform and configure via ansible. 

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Prerequisites

* On your local dev machine install:
  * Terraform
  * Ansible
  * Transcrypt
  * Helm
  * helm-diff plugin
* Proxmox Server
* Postgresql Server (optional, used as Terraform backend)

Install [Transcrypt](https://github.com/elasticdog/transcrypt) then run command `transcript` on the terminal. 
Follow prompts to set your secret key. 
Transcrypt will encrypt and decrypt files listed in .gitattributes to git.  

Install the [Terraform Collection][terraform-collection] using ansible galaxy.
```
ansible-galaxy collection install cloud.terraform
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Step 1 - Provisioning the kubernetes cluster infastructure

Create a terraform.tfvars file with the access credentials of your proxmox server. Enter values for 
* proxmox_endpoint
* proxmox_username
* proxmox_password

I'm using postgres as a terraform backend. This is optional. You may use your preferred backend. 
Create a config.pg.tfbackend file with access credentials to a postresql server. Enter values for
* conn_str
* schema_name

You can make changes to the variable.tf file to adjust ip addresses to the proxmox's network and infastructure. 

Default infastructure consists of:
* 3 controlplanes
* 2 worker nodes
* 1 load balancer
* 1 nfs (Network File System) server

#### Run Terraform
```
terraform init --backend-config=config.pg.tfbackend 
terraform plan
terraform apply
```
<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Step 2 - Configuring the infastructure

#### Run Ansible Playbook
```
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i ./ansible/inventory.yaml ./ansible/playbook.yaml
```
Terraform ran in step 1 generates a tf_ansible_vars_file.yaml that ansible uses in running tasks.

### Cleanup
Delete all created infastructure.
`terraform destroy`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Kubernetes Applications Installed:
* keycloak
* argocd
* linkerd
* metallb
* metrics server
* nfs provisioner
* nginx ingress
* prometheus
* sealed secrets

#### to add
* kube-vip
* cert-manager

<p align="right">(<a href="#readme-top">back to top</a>)</p>

##### Useful commands to know:
Print Terraform Inventory
```
ansible-inventory -i ./ansible/inventory.yaml --graph --vars
```

Run specific tasks of ansible playbook
```
ansible-playbook -i ./ansible/inventory.yaml ./ansible/playbook.yaml --tags "metallb,nfs"
```

Run specific playbook
```
ansible-playbook -i ./ansible/inventory.yaml ./ansible/install-istio.yaml --ask-become-pass
```

SSH into container
```
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i .ssh/my-private-key.pem ubuntu@192.168.254.101
```

Download terraform state from backend
```
terraform state pull > terraform.tfstate
```

View terraform state
```
terraform show -json
```

Create kubectl alias
```
alias k="kubectl --kubeconfig ./kubeconfig"
```

Create k9s alias
```
alias k9x="k9s --kubeconfig ./kubeconfig"
```

Create helm alias
```
alias h="helm --kubeconfig ./kubeconfig"
```

Argo CD initial password
```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Expose [Argo CD](https://argo-cd.readthedocs.io/en/stable/getting_started/)
```
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

Expose services using port-forward
```
kubectl port-forward service/prometheus-grafana 3000:80 -n prometheus
```

[Keycloak](https://keycloak.org/server/reverseproxy) and oidc-login

```
kubectl oidc-login setup \
  --oidc-issuer-url=https://keycloak.deviantlab.duckdns.org/auth/realms/k8s-realm \
  --oidc-client-id=k8s-client \
  --oidc-client-secret=hPAvh3sdWqFZoqYAktHeTaoJWN404tzP
```

Troubleshooting Terraform
```
terraform refresh
terraform state rm <resource_name>
terraform apply -target=<resource_name>
terraform destroy -target=<resource_name>
terraform apply -replace=<resource_name>
terraform force-unlock <lock_id>
TF_LOG=DEBUG terraform apply
```
<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/angelopaolosantos
[product-screenshot]: images.png
[terraform-collection]: https://galaxy.ansible.com/ui/repo/published/cloud/terraform/

Install talosctl on local machine

Generate Machine Configurations with QEMU guest agent support
In Proxmox, go to your VM –> Options and ensure that QEMU Guest Agent is Enabled
Generate config files. --force to overwrite existings files
```
talosctl gen config talos-proxmox-cluster https://$CONTROL_PLANE_IP:6443 --output-dir _out --install-image=factory.talos.dev/nocloud-installer-secureboot/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.10.5 --install-disk=/dev/sda --config-patch @tpm-disk-encryption.yaml --config-patch @cni_disable_patch.yaml --force
```
cni_disable_patch.yaml will disable default cni installed by talos


Create Control Plane Node
```
talosctl apply-config --insecure --nodes $CONTROL_PLANE_IP --file _out/controlplane.yaml
```

Create Worker Node
```
talosctl apply-config --insecure --nodes $WORKER_IP --file _out/worker.yaml
```

Configure talosctl on the first control plane node (controlplane-vm-1)
```
export TALOSCONFIG="_out/talosconfig"
talosctl config endpoint $CONTROL_PLANE_IP
talosctl config node $CONTROL_PLANE_IP
```

Bootstrap Etcd
```
talosctl bootstrap
```

Retrieve the kubecofig
```
talosctl kubeconfig .
```

Create kubectl alias
```
alias k="kubectl --kubeconfig ./kubeconfig"
```

Create k9s alias
```
alias k9x="k9s --kubeconfig ./kubeconfig"
```

Create helm alias
```
alias h="helm --kubeconfig ./kubeconfig"
```

OIDC Settings

add to controlplane.yaml

```
cluster:
  apiServer:
    extraArgs:
      oidc-client-id: "talos"
      oidc-issuer-url: "https://your.oidc.provider/openid"
      oidc-username-claim: "email" # or preferred_username, etc.
      oidc-groups-claim: "groups"
```

https://www.talos.dev/v1.10/talos-guides/install/bare-metal-platforms/secureboot/
https://cert-manager.io/docs/tutorials/acme/nginx-ingress/
