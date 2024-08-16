# AWS EKS Karpenter Configuration


This repository contains a [Crossplane configuration](https://docs.crossplane.io/latest/concepts/packages/#configuration-packages), tailored for users establishing their initial control plane with [Upbound](https://cloud.upbound.io). This configuration deploys fully managed [AWS EKS Karpenter](https://aws.amazon.com/blogs/aws/introducing-karpenter-an-open-source-high-performance-kubernetes-cluster-autoscaler/) instances.

## Overview

The core components of a custom API in [Crossplane](https://docs.crossplane.io/latest/getting-started/introduction/) include:

- **CompositeResourceDefinition (XRD):** Defines the API's structure.
- **Composition(s):** Implements the API by orchestrating a set of Crossplane managed resources.

In this specific configuration, the EKS Karpenter API contains:

- **an [AWS EKS Karpenter](/apis/definition.yaml) custom resource type.**
- **Composition of the Karpenter resources:** Configured in [/apis/composition.yaml](/apis/composition.yaml), it provisions Karpenter resources in the `upbound-system` namespace.

This repository contains an Composite Resource (XR) file.

## Deployment

```shell
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: configuration-aws-eks-karpenter
spec:
  package: xpkg.upbound.io/upbound/configuration-aws-eks-karpenter:v0.6.0
```

## Next steps

This repository serves as a foundational step. To enhance your control plane, consider:

1. create new API definitions in this same repo
2. editing the existing API definition to your needs


Upbound will automatically detect the commits you make in your repo and build the configuration package for you. To learn more about how to build APIs for your managed control planes in Upbound, read the guide on Upbound's docs.

# Using the make file
## render target
### Overview
`make render` target automates the rendering of Crossplane manifests using specified annotations within your YAML files.
The annotations guide the rendering process, specifying paths to composition, function, environment, and observe files.

### Annotations
The `make render` target relies on specific annotations in your YAML files to determine how to process each file.
The following annotations are supported:

**render.crossplane.io/composition-path**: Specifies the path to the composition file to be used in rendering.

**render.crossplane.io/function-path**: Specifies the path to the function file to be used in rendering.

**render.crossplane.io/environment-path** (optional): Specifies the path to the environment file. If not provided, the rendering will proceed without an environment.

**render.crossplane.io/observe-path** (optional): Specifies the path to the observe file. If not provided, the rendering will proceed without observation settings.

```yaml
apiVersion: aws.platform.upbound.io/v1alpha1
kind: XKarpenter
metadata:
  name: configuration-aws-eks-karpenter
  annotations:
    render.crossplane.io/composition-path: apis/pat/composition.yaml
    render.crossplane.io/function-path: examples/functions.yaml
spec:
  parameters:
    clusterNameSelector:
      matchLabels:
        crossplane.io/composite: configuration-aws-eks-karpenter
    id: configuration-aws-eks-karpenter
    region: us-west-2
```
