# Demo with nginx and authentication

This is a demo setup that builds a container image based on the official NGINX container image and adds a dummy user credentials (user: `demo-user` and password: `demo-password`).

You can deploy it using:
```bash
$ oc apply -f nginx-deploy.yaml
```
