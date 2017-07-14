# Kubernetes plugin for drone.io [![Docker Repository on Quay](https://quay.io/repository/honestbee/drone-kubernetes/status "Docker Repository on Quay")](https://quay.io/repository/honestbee/drone-kubernetes)

This plugin allows to update a Kubernetes deployment.

## Usage  

This pipeline will update the `my-deployment` deployment with the image tagged `DRONE_COMMIT_SHA:0:8`

```yaml
    pipeline:
        deploy:
            image: quay.io/honestbee/drone-kubernetes
            deployment: my-deployment
            repo: myorg/myrepo
            container: my-container
            tag: 
                - mytag
                - latest
```

Deploying containers across several deployments, eg in a scheduler-worker setup. Make sure your container `name` in your manifest is the same for each pod.
    
```yaml
    pipeline:
        deploy:
            image: quay.io/honestbee/drone-kubernetes
            deployment: [server-deploy, worker-deploy]
            repo: myorg/myrepo
            container: my-container
            tag:                 
                - mytag
                - latest
```

Deploying multiple containers within the same deployment.

```yaml
    pipeline:
        deploy:
            image: quay.io/honestbee/drone-kubernetes
            deployment: my-deployment
            repo: myorg/myrepo
            container: [container1, container2]
            tag:                 
                - mytag
                - latest
```

**NOTE**: Combining multi container deployments across multiple deployments is not recommended

This more complex example demonstrates how to deploy to several environments based on the branch, in a `app` namespace 

```yaml
    pipeline:
        deploy-staging:
            image: quay.io/honestbee/drone-kubernetes
            kubernetes_server: ${KUBERNETES_SERVER_STAGING}
            kubernetes_cert: ${KUBERNETES_CERT_STAGING}
            kubernetes_token: ${KUBERNETES_TOKEN_STAGING}
            deployment: my-deployment
            repo: myorg/myrepo
            container: my-container
            namespace: app
            tag:                 
                - mytag
                - latest
            when:
                branch: [ staging ]

        deploy-prod:
            image: quay.io/honestbee/drone-kubernetes
            kubernetes_server: ${KUBERNETES_SERVER_PROD}
            kubernetes_token: ${KUBERNETES_TOKEN_PROD}
            # notice: no tls verification will be done, warning will is printed
            deployment: my-deployment
            repo: myorg/myrepo
            container: my-container
            namespace: app
            tag:                 
                - mytag
                - latest
            when:
                branch: [ master ]
```

## Required secrets

```bash
    drone secret add --image=honestbee/drone-kubernetes \
        your-user/your-repo KUBERNETES_SERVER https://mykubernetesapiserver

    drone secret add --image=honestbee/drone-kubernetes \
        your-user/your-repo KUBERNETES_CERT <base64 encoded CA.crt>

    drone secret add --image=honestbee/drone-kubernetes \
        your-user/your-repo KUBERNETES_TOKEN eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJrdWJ...
```

When using TLS Verification, ensure Server Certificate used by kubernetes API server 
is signed for SERVER url ( could be a reason for failures if using aliases of kubernetes cluster )

## How to get token
1. After deployment inspect you pod for name of (k8s) secret with **token** and **ca.crt**
```bash
kubectl describe po/[ your pod name ] | grep SecretName | grep token
```
(When you use **default service account**)

2. Get data from you (k8s) secret
```bash
kubectl get secret [ your default secret name ] -o yaml | egrep 'ca.crt:|token:'
```
3. Copy-paste contents of ca.crt into your drone's **KUBERNETES_CERT** secret
4. Decode base64 encoded token
```bash
echo [ your k8s base64 encoded token ] | base64 -d && echo''
```
5. Copy-paste decoded token into your drone's **KUBERNETES_TOKEN** secret

## To do 

Replace the current kubectl bash script with a go implementation.

### Special thanks

Inspired by [drone-helm](https://github.com/ipedrazas/drone-helm).
