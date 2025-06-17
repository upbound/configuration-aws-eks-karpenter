# AWS EKS Karpenter Configuration

This repository contains an Upbound project for deploying and managing AWS EKS Karpenter node autoscaling. This configuration deploys fully managed [AWS EKS Karpenter](https://aws.amazon.com/blogs/aws/introducing-karpenter-an-open-source-high-performance-kubernetes-cluster-autoscaler/) instances.

## Overview

The core components of a custom API in an Upbound Project include:
- **CompositeResourceDefinition (XRD):** Defines the API's structure
- **Composition(s):** Configures the Functions Pipeline
- **Embedded Function(s):** Encapsulates the Composition logic

In this configuration, the EKS Karpenter API contains:
- **An [AWS EKS Karpenter](/apis/xkarpenters/definition.yaml) custom resource type**
- **Composition configuration:** Located in [/apis/xkarpenters/composition.yaml](/apis/xkarpenters/composition.yaml), it provisions Karpenter resources in the `upbound-system` namespace
- **Embedded function:** Implements Karpenter resource provisioning logic in [/functions/xkarpenter/](/functions/xkarpenter/)

## Testing

Test the configuration using:
- `up composition render apis/xkarpenters/composition.yaml examples/karpenter-xr.yaml` to render the composition
- `up test run tests/test-xkarpenter` to run composition tests
- `up test run tests/* --e2e` to run end-to-end tests

## Deployment

- Execute `up project run`
- Alternatively, install from the Upbound Marketplace:

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: configuration-aws-eks-karpenter
spec:
  package: xpkg.upbound.io/upbound/configuration-aws-eks-karpenter:v0.6.0
```

- Check `examples/` for example Composite Resources

## Next Steps

This repository serves as a foundational step. To enhance the configuration:
1. Create new API definitions in this repo
2. Edit existing API definitions to meet specific needs

Learn more about building APIs for managed control planes in [Upbound's documentation](https://docs.upbound.io/).

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