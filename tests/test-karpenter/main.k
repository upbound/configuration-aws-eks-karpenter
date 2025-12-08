import json

import models.io.crossplane.kubernetesm.v1alpha1 as kubernetesv1alpha1
import models.io.upbound.awsm.cloudwatchevents.v1beta1 as cloudwatcheventsv1beta1
import models.io.upbound.awsm.eks.v1beta1 as eksv1beta1
import models.io.upbound.awsm.iam.v1beta1 as iamv1beta1
import models.io.upbound.awsm.sqs.v1beta1 as sqsv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as platformv1alpha1

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-karpenter"
        spec= {
            assertResources: [
                platformv1alpha1.Karpenter {
                    metadata = {
                        name = "configuration-aws-eks-karpenter"
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
                eksv1beta1.AccessEntry {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "accessEntry"
                        }
                        generateName = "configuration-aws-eks-karpenter-"
                    }
                    spec = {
                        managementPolicies = ["*"]
                        forProvider = {
                            clusterNameSelector = {
                                matchLabels = {
                                    "crossplane.io/composite" = "configuration-aws-eks-karpenter"
                                }
                            }
                            kubernetesGroups = []
                            principalArnFromRoleSelector = {
                                matchControllerRef = True
                                matchLabels = {
                                    role = "karpenter"
                                }
                            }
                            region = "us-west-2"
                            $type = "EC2_LINUX"
                        }
                        managementPolicies = ["*"]
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                    }
                }
                iamv1beta1.RolePolicyAttachment {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "InstanceNodeRoleCNIPolicy"
                        }
                        generateName = "configuration-aws-eks-karpenter-"
                    }
                    spec = {
                        managementPolicies = ["*"]
                        forProvider = {
                            policyArn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
                            roleSelector = {
                                matchControllerRef = True
                                matchLabels = {
                                    role = "karpenter"
                                }
                            }
                        }
                        managementPolicies = ["*"]
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                    }
                }
                iamv1beta1.Role {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "instanceNodeRole"
                        }
                        generateName = "configuration-aws-eks-karpenter-"
                        labels = {
                            role = "karpenter"
                        }
                    }
                    spec = {
                        managementPolicies = ["*"]
                        forProvider = {
                            assumeRolePolicy = json.encode({
                              Version: "2012-10-17",
                              Statement: [
                                  {
                                      Effect: "Allow",
                                      Principal: {
                                          Service: [
                                              "ec2.amazonaws.com"
                                          ]
                                      },
                                      Action: [
                                          "sts:AssumeRole"
                                      ]
                                  }
                              ]
                            })
                        }
                        managementPolicies = ["*"]
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                    }
                }
                iamv1beta1.RolePolicyAttachment {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "instanceNodeRoleECRPolicy"
                        }
                        generateName = "configuration-aws-eks-karpenter-"
                    }
                    spec = {
                        managementPolicies = ["*"]
                        forProvider = {
                            policyArn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
                            roleSelector = {
                                matchControllerRef = True
                                matchLabels = {
                                    role = "karpenter"
                                }
                            }
                        }
                        managementPolicies = ["*"]
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                    }
                }
                iamv1beta1.RolePolicyAttachment {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "instanceNodeRoleEKSPolicy"
                        }
                        generateName = "configuration-aws-eks-karpenter-"
                    }
                    spec = {
                        managementPolicies = ["*"]
                        forProvider = {
                            policyArn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
                            roleSelector = {
                                matchControllerRef = True
                                matchLabels = {
                                    role = "karpenter"
                                }
                            }
                        }
                        managementPolicies = ["*"]
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                    }
                }
                iamv1beta1.RolePolicyAttachment {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "instanceNodeRoleSSMPolicy"
                        }
                        generateName = "configuration-aws-eks-karpenter-"
                    }
                    spec = {
                        managementPolicies = ["*"]
                        forProvider = {
                            policyArn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
                            roleSelector = {
                                matchControllerRef = True
                                matchLabels = {
                                    role = "karpenter"
                                }
                            }
                        }
                        managementPolicies = ["*"]
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                    }
                }
                iamv1beta1.InstanceProfile {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "instanceProfile"
                        }
                        generateName = "configuration-aws-eks-karpenter-"
                    }
                    spec = {
                        managementPolicies = ["*"]
                        forProvider = {
                            roleSelector = {
                                matchControllerRef = True
                                matchLabels = {
                                    role = "karpenter"
                                }
                            }
                        }
                        managementPolicies = ["*"]
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                    }
                }
                kubernetesv1alpha1.Object {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "karpenterNodePool"
                        }
                        generateName = "configuration-aws-eks-karpenter-"
                    }
                    spec = {
                        managementPolicies = ["Create", "Observe", "Update"]
                        forProvider = {
                            manifest = {
                                apiVersion = "karpenter.sh/v1"
                                kind = "NodePool"
                                metadata = {
                                    name = "default"
                                }
                                spec = {
                                    disruption = {
                                        consolidateAfter = "1m"
                                        consolidationPolicy = "WhenEmptyOrUnderutilized"
                                    }
                                    limits = {
                                        cpu = 1000
                                        memory = "500Gi"
                                    }
                                    template = {
                                        metadata = {
                                            labels = {
                                                intent = "apps"
                                            }
                                        }
                                        spec = {
                                            nodeClassRef = {
                                                group = "karpenter.k8s.aws"
                                                kind = "EC2NodeClass"
                                                name = "default"
                                            }
                                            requirements = [
                                                {
                                                    key = "karpenter.k8s.aws/instance-category"
                                                    operator = "In"
                                                    values = [
                                                        "c"
                                                        "m"
                                                        "r"
                                                        "i"
                                                        "d"
                                                    ]
                                                }
                                                {
                                                    key = "karpenter.k8s.aws/instance-cpu"
                                                    operator = "In"
                                                    values = [
                                                        "4"
                                                        "8"
                                                        "16"
                                                        "32"
                                                        "48"
                                                        "64"
                                                    ]
                                                }
                                                {
                                                    key = "karpenter.sh/capacity-type"
                                                    operator = "In"
                                                    values = [
                                                        "spot"
                                                        "on-demand"
                                                    ]
                                                }
                                                {
                                                    key = "kubernetes.io/arch"
                                                    operator = "In"
                                                    values = [
                                                        "amd64"
                                                        "arm64"
                                                    ]
                                                }
                                            ]
                                        }
                                    }
                                }
                            }
                        }
                        providerConfigRef = {
                            name = "configuration-aws-eks-karpenter"
                            kind = "ProviderConfig"
                        }
                        watch = False
                    }
                }
                cloudwatcheventsv1beta1.Rule {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "ruleHealthEvent"
                            "crossplane.io/external-name" = "configuration-aws-eks-karpenter-healthevent"
                        }
                        generateName = "configuration-aws-eks-karpenter-"
                        labels = {
                            $type = "HealthEvent"
                        }
                        name = "configuration-aws-eks-karpenter-healthevent"
                    }
                    spec = {
                        managementPolicies = ["*"]
                        forProvider = {
                            eventBusName = "default"
                            eventPattern = json.encode({
                              source: [
                                "aws.health"
                              ],
                              "detail-type": [
                                "AWS Health Event"
                              ]
                            })
                            region = "us-west-2"
                        }
                        managementPolicies = ["*"]
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                    }
                }
                cloudwatcheventsv1beta1.Rule {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "ruleInstanceRebalance"
                            "crossplane.io/external-name" = "configuration-aws-eks-karpenter-instancerebalance"
                        }
                        generateName = "configuration-aws-eks-karpenter-"
                        labels = {
                            $type = "InstanceRebalance"
                        }
                        name = "configuration-aws-eks-karpenter-instancerebalance"
                    }
                    spec = {
                        managementPolicies = ["*"]
                        forProvider = {
                            eventBusName = "default"
                            eventPattern = json.encode({
                              source: [
                                "aws.ec2"
                              ],
                              "detail-type": [
                                "EC2 Instance Rebalance Recommendation"
                              ]
                            })
                            region = "us-west-2"
                        }
                        managementPolicies = ["*"]
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                    }
                }
                cloudwatcheventsv1beta1.Rule {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "ruleInstanceStateChange"
                            "crossplane.io/external-name" = "configuration-aws-eks-karpenter-instancestatechange"
                        }
                        generateName = "configuration-aws-eks-karpenter-"
                        labels = {
                            $type = "InstanceStateChange"
                        }
                        name = "configuration-aws-eks-karpenter-instancestatechange"
                    }
                    spec = {
                        managementPolicies = ["*"]
                        forProvider = {
                            eventBusName = "default"
                            eventPattern = json.encode({
                              source: [
                                "aws.ec2"
                              ],
                              "detail-type": [
                                "EC2 Instance State-change Notification"
                              ]
                            })
                            region = "us-west-2"
                        }
                        managementPolicies = ["*"]
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                    }
                }
                cloudwatcheventsv1beta1.Rule {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "ruleSpotInterrupt"
                            "crossplane.io/external-name" = "configuration-aws-eks-karpenter-spotinterrupt"
                        }
                        generateName = "configuration-aws-eks-karpenter-"
                        labels = {
                            $type = "SpotInterrupt"
                        }
                        name = "configuration-aws-eks-karpenter-spotinterrupt"
                    }
                    spec = {
                        managementPolicies = ["*"]
                        forProvider = {
                            eventBusName = "default"
                            eventPattern = json.encode({
                              source: [
                                "aws.ec2"
                              ],
                              "detail-type": [
                                "EC2 Spot Instance Interruption Warning"
                              ]
                            })
                            region = "us-west-2"
                        }
                        managementPolicies = ["*"]
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                    }
                }
                sqsv1beta1.Queue {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "sqsQueue"
                        }
                        generateName = "configuration-aws-eks-karpenter-"
                    }
                    spec = {
                        managementPolicies = ["*"]
                        forProvider = {
                            messageRetentionSeconds = 300
                            name = "configuration-aws-eks-karpenter-karpenter-queue"
                            region = "us-west-2"
                        }
                        managementPolicies = ["*"]
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                    }
                }
            ]
            compositionPath: "apis/karpenters/composition.yaml"
            xrPath: "examples/karpenter-xr.yaml"
            xrdPath: "apis/karpenters/definition.yaml"
            timeoutSeconds: 60
            validate: False
        }
    }
]
items= _items
