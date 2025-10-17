import models.io.crossplane.kubernetes.v1alpha1 as kubernetesv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as platformawsv1alpha1

observedResources = [
    {
        apiVersion = "eks.aws.upbound.io/v1beta1"
        kind = "AccessEntry"
        metadata = {
            annotations = {
                "crossplane.io/composition-resource-name" = "accessEntry"
            }
            name = "configuration-aws-eks-karpenter-qlqgf"
        }
        status = {
            atProvider = {
                clusterName = "configuration-aws-eks-karpenter-w8989"
            }
        }
    }
    {
        apiVersion = "sqs.aws.upbound.io/v1beta1"
        kind = "Queue"
        metadata = {
            annotations = {
                "crossplane.io/composition-resource-name" = "sqsQueue"
            }
            name = "configuration-aws-eks-karpenter-95njg"
        }
        status = {
            atProvider = {
                arn = "arn:aws:sqs:us-west-2:609897127049:configuration-aws-eks-karpenter-karpenter-queue"
                name = "configuration-aws-eks-karpenter-karpenter-queue"
            }
        }
    }
    {
        apiVersion = "iam.aws.upbound.io/v1beta1"
        kind = "Role"
        metadata = {
            annotations = {
                "crossplane.io/composition-resource-name" = "instanceNodeRole"
            }
            name = "configuration-aws-eks-karpenter-2985f"
        }
        status = {
            atProvider = {
                arn = "arn:aws:iam::609897127049:role/configuration-aws-eks-karpenter-2985f"
            }
        }
    }
    {
        apiVersion = "iam.aws.upbound.io/v1beta1"
        kind = "InstanceProfile"
        metadata = {
            annotations = {
                "crossplane.io/composition-resource-name" = "instanceProfile"
            }
            name = "configuration-aws-eks-karpenter-jtb87"
        }
        status = {
            atProvider = {
                arn = "arn:aws:iam::609897127049:instance-profile/configuration-aws-eks-karpenter-jtb87"
            }
        }
    }
]

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "xkarpenter-with-observed"
        spec= {
            assertResources: [
                platformawsv1alpha1.XKarpenter {
                    metadata = {
                        name = "configuration-aws-eks-karpenter"
                    }
                    spec = {
                        parameters = {
                            id = "configuration-aws-eks-karpenter"
                            region = "us-west-2"
                            providerConfigName = "default"
                            clusterNameSelector = {
                                matchLabels = {
                                    "crossplane.io/composite" = "configuration-aws-eks-karpenter"
                                }
                            }
                        }
                    }
                }
                platformawsv1alpha1.XPodIdentity {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "podIdentity"
                        }
                        generateName = "configuration-aws-eks-karpenter-"
                    }
                    spec = {
                        parameters = {
                            providerConfigName = "default"
                            clusterName = "configuration-aws-eks-karpenter-w8989"
                            region = "us-west-2"
                            serviceAccount = {
                                name = "karpenter"
                                namespace = "karpenter"
                            }
                        }
                    }
                }
                kubernetesv1alpha1.Object {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "karpenterNodeClass"
                        }
                        generateName = "configuration-aws-eks-karpenter-"
                    }
                    spec = {
                        deletionPolicy = "Orphan"
                        forProvider = {
                            manifest = {
                                apiVersion = "karpenter.k8s.aws/v1"
                                kind = "EC2NodeClass"
                                metadata = {
                                    name = "default"
                                }
                                spec = {
                                    amiFamily = "AL2"
                                    amiSelectorTerms = [
                                        {
                                            alias = "al2@latest"
                                        }
                                    ]
                                    tags = {
                                        KarpenterNodePoolName = "default"
                                        NodeType = "default"
                                        intent = "apps"
                                        "karpenter.sh/discovery" = "configuration-aws-eks-karpenter-w8989"
                                    }
                                    subnetSelectorTerms = [
                                        {
                                            tags = {
                                                "networks.aws.platform.upbound.io/network-id" = "configuration-aws-eks-karpenter"
                                            }
                                        }
                                    ]
                                    securityGroupSelectorTerms = [
                                        {
                                            tags = {
                                                "eks.aws.platform.upbound.io/discovery" = "configuration-aws-eks-karpenter"
                                                "aws:eks:cluster-name" = "configuration-aws-eks-karpenter-w8989"
                                            }
                                        }
                                    ]
                                    instanceProfile = "configuration-aws-eks-karpenter-jtb87"
                                }
                            }
                        }
                        managementPolicy = "Default"
                        providerConfigRef = {
                            name = "configuration-aws-eks-karpenter"
                        }
                        watch = False
                    }
                }
                # Bug: if we specify a type here, test will fail with
                # * spec.managementPolicies: Required value: field not found in the input object
                {
                    apiVersion = "helm.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "karpenterChart"
                            "crossplane.io/external-name" = "karpenter"
                        }
                        generateName = "configuration-aws-eks-karpenter-"
                    }
                    spec = {
                        deletionPolicy = "Orphan"
                        forProvider = {
                            wait = True
                            chart = {
                                name = "karpenter"
                                repository = "oci://public.ecr.aws/karpenter"
                                version = "1.8.1"
                            }
                            namespace = "karpenter"
                            values = {
                                settings = {
                                    clusterName = "configuration-aws-eks-karpenter-w8989"
                                    interruptionQueueName = "configuration-aws-eks-karpenter-karpenter-queue"
                                }
                            }
                        }
                        providerConfigRef = {
                            name = "configuration-aws-eks-karpenter"
                        }
                    }
                }
            ]
            observedResources = observedResources
            compositionPath = "apis/xkarpenters/composition.yaml"
            xrPath = "examples/karpenter-xr.yaml"
            xrdPath = "apis/xkarpenters/definition.yaml"
            timeoutSeconds = 60
            validate = False
        }
    }
]
items= _items
