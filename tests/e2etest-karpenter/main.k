import models.io.upbound.awsm.v1beta1 as awsv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as platformawsv1alpha1

_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2e-test-karpenter"
        spec= {
            crossplane.autoUpgrade.channel: "None"
            crossplane.version = "2.0.2-up.5"
            defaultConditions: ["Ready"]
            manifests: [
                platformawsv1alpha1.Karpenter{
                    metadata = {
                        name = "configuration-aws-eks-karpenter"
                        namespace = "default"
                    }
                    spec = {
                        parameters = {
                            clusterNameSelector = {
                                matchLabels = {
                                    "crossplane.io/composite" = "configuration-aws-eks-karpenter"
                                }
                            }
                            id = "configuration-aws-eks-karpenter"
                            region = "us-west-2"
                        }
                    }
                }
            ]
            extraResources: [
                awsv1beta1.ProviderConfig{
                    metadata = {
                        name = "default"
                        namespace = "default"
                    }
                    spec = {
                        credentials = {
                            source = "Upbound"
                            upbound = {
                                webIdentity = {
                                    roleARN = "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
                                }
                            }
                        }
                    }
                },
                platformawsv1alpha1.Network{
                    metadata = {
                        name = "configuration-aws-eks-karpenter"
                        namespace = "default"
                    }
                    spec = {
                        parameters = {
                            id = "configuration-aws-eks-karpenter"
                            region = "us-west-2"
                        }
                    }
                },
                platformawsv1alpha1.EKS{
                    metadata = {
                        name = "configuration-aws-eks-karpenter"
                        namespace = "default"
                        labels = {
                            "xeks.aws.platform.upbound.io/cluster-id" = "configuration-aws-eks-karpenter"
                        }
                    }
                    spec = {
                        parameters = {
                            id = "configuration-aws-eks-karpenter"
                            region = "us-west-2"
                            version = "1.33"
                            accessConfig = {
                                authenticationMode = "API_AND_CONFIG_MAP"
                                bootstrapClusterCreatorAdminPermissions = True
                            }
                            nodes = {
                                count = 3
                                instanceType = "t3.small"
                            }
                        }
                    }
                }
            ]
            skipDelete: False
            timeoutSeconds: 4500
        }
    }
]
items= _items
