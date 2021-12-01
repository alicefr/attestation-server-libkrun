# Demo

Scripts and setup to deploy the demo.
This assume that you are running on Openshift. The setup can be adjusted also to be k8s compatible by installing the missing CRDs and controller in your kubernetes cluster.

## Prerequisites
In order to run the demo you need to:
1. install and deploy an [OCP cluster using CRC](https://crc.dev/crc/)
2. the tkn [binary](https://docs.openshift.com/container-platform/4.9/cli_reference/tkn_cli/installing-tkn.html#installing-tkn) 
3. [install the pipline operator from the operator hub](https://docs.openshift.com/container-platform/4.9/cicd/pipelines/installing-pipelines.html)

If you already have an OCP cluster you need to adjust the KUBECONFIG path to point the correct one.

The demo creates a tekton task that pulls a container image, it transforms it in an ecrypted image and pushes it in the internal registry.
