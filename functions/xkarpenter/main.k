import regex
import json

import models.io.upbound.platform.aws.v1alpha1 as platformv1alpha1
import models.io.upbound.aws.iam.v1beta1 as iamv1beta1

import models.io.upbound.aws.cloudwatchevents.v1beta1 as cloudwatcheventsv1beta1
import models.io.upbound.aws.sqs.v1beta1 as sqsv1beta1
import models.io.crossplane.kubernetes.v1alpha1 as kubernetesv1alpha1

oxr = platformv1alpha1.XKarpenter {**option("params").oxr}
# observed composed resources
_ocds = option("params").ocds
# desired composite resource
_dxr = option("params").dxr
# desired composed resources
dcds = option("params").dcds

_metadata = lambda name: str -> any {
    {
        annotations = {"krm.kcl.dev/composition-resource-name" = name}
    }
}
# Get values from XR
_id = oxr.spec.parameters.id
_region = oxr.spec.parameters.region
_providerConfigName = oxr.spec.parameters.providerConfigName or "default"
# Generate resource names
_sqsQueueName = "${_id}-karpenter"
_healthEventName = "${_id}-healthevent"
_instanceRebalanceName = "${_id}-instancerebalance"
_instanceStateChangeName = "${_id}-instancestatechange"
_spotInterruptName = "${_id}-spotinterrupt"

_statusClusterName = Undefined
if _ocds.accessEntry?.Resource?.status?.atProvider?.clusterName:
    _statusClusterName = _ocds.accessEntry.Resource.status.atProvider.clusterName

_statusSqsQueueArn = Undefined
if _ocds.sqsQueue?.Resource?.status?.atProvider?.arn:
    _statusSqsQueueArn = _ocds.sqsQueue.Resource.status.atProvider.arn

_statusAccountId = Undefined
if _ocds.instanceNodeRole?.Resource?.status?.atProvider?.arn:
    _statusAccountId = regex.replace(_ocds.instanceNodeRole.Resource.status.atProvider.arn, "arn:aws:iam::(\d+):.*", "$1")

_statusInstanceProfileArn = Undefined
if _ocds.instanceProfile?.Resource?.status?.atProvider?.arn:
    _statusInstanceProfileArn = _ocds.instanceProfile.Resource.status.atProvider.arn

_statusInstanceNodeRoleArn = Undefined
if _ocds.instanceNodeRole?.Resource?.status?.atProvider?.arn:
    _statusInstanceNodeRoleArn = _ocds.instanceNodeRole.Resource.status.atProvider.arn

_statusInstanceProfileName = Undefined
if _ocds.instanceProfile?.Resource?.status?.atProvider?.arn:
    _statusInstanceProfileName = regex.replace(_ocds.instanceProfile.Resource.status.atProvider.arn, "arn:aws:iam::\\d+:instance-profile/(.+)", "$1")

_defaults = {
    deletionPolicy = oxr.spec.parameters.deletionPolicy or "Delete"
    providerConfigRef.name = oxr.spec.parameters.providerConfigName or "default"
}

_items = [
    # Create IAM Role for Karpenter node instances
    iamv1beta1.Role {
        metadata = {
            **_metadata("instanceNodeRole")
            generateName = "${_id}-"
            labels = {
                role = "karpenter"
            }
        }
        spec = {
            **_defaults
            forProvider = {
                assumeRolePolicy = """{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Principal": {
              "Service": [
                  "ec2.amazonaws.com"
              ]
          },
          "Action": [
              "sts:AssumeRole"
          ]
      }
  ]
}"""
            }
            providerConfigRef = {
                name = _providerConfigName
            }
        }
    }
    # Attach EKS Policy
    iamv1beta1.RolePolicyAttachment {
        metadata = {
            **_metadata("instanceNodeRoleEKSPolicy")
        }
        spec = {
            **_defaults
            forProvider = {
                policyArn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
                roleSelector = {
                    matchControllerRef = True
                    matchLabels = {"role": "karpenter"}
                }
            }
        }
    }
    # Attach CNI Policy
    iamv1beta1.RolePolicyAttachment {
        metadata = {
            **_metadata("InstanceNodeRoleCNIPolicy")
        }
        spec = {
            **_defaults
            forProvider = {
                policyArn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
                roleSelector = {
                    matchControllerRef = True
                    matchLabels = {"role": "karpenter"}
                }
            }
            providerConfigRef = {
                name = _providerConfigName
            }
        }
    }
    # Attach ECR Policy
    iamv1beta1.RolePolicyAttachment {
        metadata = {
            **_metadata("instanceNodeRoleECRPolicy")
        }
        spec = {
            **_defaults
            forProvider = {
                policyArn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
                roleSelector = {
                    matchControllerRef = True
                    matchLabels = {"role": "karpenter"}
                }
            }
        }
    }
    # Attach SSM Policy
    iamv1beta1.RolePolicyAttachment {
        metadata = {
            **_metadata("instanceNodeRoleSSMPolicy")
        }
        spec = {
            **_defaults
            forProvider = {
                policyArn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
                roleSelector = {
                    matchControllerRef = True
                    matchLabels = {"role": "karpenter"}
                }
            }
        }
    }
    # Create Instance Profile
    iamv1beta1.InstanceProfile {
        metadata = {
            **_metadata("instanceProfile")
        }
        spec = {
            **_defaults
            forProvider = {
                roleSelector = {
                    matchControllerRef = True
                    matchLabels = {"role": "karpenter"}
                }
            }
            providerConfigRef = {
                name = _providerConfigName
            }
        }
    }
    # Create AccessEntry for Karpenter role
    # Note: If we use type here, clusterNameSelector will conflict and
    # we cannot forward the selector to the object
    {
        apiVersion = "eks.aws.upbound.io/v1beta1"
        kind = "AccessEntry"
        metadata = {
            **_metadata("accessEntry")
        }
        spec = {
            **_defaults
            forProvider = {
                region = _region
                type = "EC2_LINUX"
                if oxr.spec.parameters.clusterName:
                    clusterName = oxr.spec.parameters.clusterName
                if oxr.spec.parameters.clusterNameRef:
                    clusterNameRef = {
                        **oxr.spec.parameters.clusterNameRef
                    }
                if oxr.spec.parameters.clusterNameSelector:
                    clusterNameSelector = {
                        **oxr.spec.parameters.clusterNameSelector
                    }
                kubernetesGroups = []
                principalArnFromRoleSelector = {
                    matchControllerRef = True
                    matchLabels = {"role": "karpenter"}
                }
            }
            managementPolicies = ["*"]
            providerConfigRef = {
                name = _providerConfigName
            }
        }
    }
    if _statusClusterName and _statusSqsQueueArn and _statusInstanceNodeRoleArn and _statusAccountId:
        platformv1alpha1.XPodIdentity{
            metadata = {
                **_metadata("podIdentity")
            }
            spec = {
                parameters = {
                    providerConfigName = oxr.spec.parameters.providerConfigName
                    clusterName = _statusClusterName
                    region = oxr.spec.parameters.region
                    inlinePolicy = [
                        {
                            name = "default"
                            policy = json.encode({
                                "Version": "2012-10-17"
                                "Statement": [
                                    {
                                        "Sid": "AllowScopedEC2InstanceActions"
                                        "Effect": "Allow"
                                        "Resource": [
                                            "arn:aws:ec2:${oxr.spec.parameters.region}::image/*"
                                            "arn:aws:ec2:${oxr.spec.parameters.region}::snapshot/*"
                                            "arn:aws:ec2:${oxr.spec.parameters.region}:*:spot-instances-request/*"
                                            "arn:aws:ec2:${oxr.spec.parameters.region}:*:security-group/*"
                                            "arn:aws:ec2:${oxr.spec.parameters.region}:*:subnet/*"
                                        ]
                                        "Action": [
                                            "ec2:RunInstances"
                                            "ec2:CreateFleet"
                                        ]
                                    }
                                    {
                                        "Sid": "AllowScopedEC2LaunchTemplateAccessActions"
                                        "Effect": "Allow"
                                        "Resource": "arn:aws:ec2:${oxr.spec.parameters.region}:*:launch-template/*"
                                        "Action": [
                                            "ec2:RunInstances"
                                            "ec2:CreateFleet"
                                        ]
                                        "Condition": {
                                            "StringEquals": {
                                                "aws:ResourceTag/kubernetes.io/cluster/${_statusClusterName}": "owned"
                                            }
                                            "StringLike": {
                                                "aws:ResourceTag/karpenter.sh/nodepool": "*"
                                            }
                                        }
                                    }
                                    {
                                        "Sid": "AllowScopedEC2InstanceActionsWithTags"
                                        "Effect": "Allow"
                                        "Resource": [
                                            "arn:aws:ec2:${oxr.spec.parameters.region}:*:fleet/*"
                                            "arn:aws:ec2:${oxr.spec.parameters.region}:*:instance/*"
                                            "arn:aws:ec2:${oxr.spec.parameters.region}:*:volume/*"
                                            "arn:aws:ec2:${oxr.spec.parameters.region}:*:network-interface/*"
                                            "arn:aws:ec2:${oxr.spec.parameters.region}:*:launch-template/*"
                                            "arn:aws:ec2:${oxr.spec.parameters.region}:*:spot-instances-request/*"
                                        ]
                                        "Action": [
                                            "ec2:RunInstances"
                                            "ec2:CreateFleet"
                                            "ec2:CreateLaunchTemplate"
                                        ]
                                        "Condition": {
                                            "StringEquals": {
                                                "aws:RequestTag/kubernetes.io/cluster/${_statusClusterName}": "owned"
                                                "aws:RequestTag/eks:eks-cluster-name": _statusClusterName
                                            }
                                            "StringLike": {
                                                "aws:RequestTag/karpenter.sh/nodepool": "*"
                                            }
                                        }
                                    }
                                    {
                                        "Sid": "AllowScopedResourceCreationTagging"
                                        "Effect": "Allow"
                                        "Resource": [
                                            "arn:aws:ec2:${oxr.spec.parameters.region}:*:fleet/*"
                                            "arn:aws:ec2:${oxr.spec.parameters.region}:*:instance/*"
                                            "arn:aws:ec2:${oxr.spec.parameters.region}:*:volume/*"
                                            "arn:aws:ec2:${oxr.spec.parameters.region}:*:network-interface/*"
                                            "arn:aws:ec2:${oxr.spec.parameters.region}:*:launch-template/*"
                                            "arn:aws:ec2:${oxr.spec.parameters.region}:*:spot-instances-request/*"
                                        ]
                                        "Action": "ec2:CreateTags"
                                        "Condition": {
                                            "StringEquals": {
                                                "aws:RequestTag/kubernetes.io/cluster/${_statusClusterName}": "owned"
                                                "aws:RequestTag/eks:eks-cluster-name": _statusClusterName
                                                "ec2:CreateAction": [
                                                    "RunInstances"
                                                    "CreateFleet"
                                                    "CreateLaunchTemplate"
                                                ]
                                            }
                                            "StringLike": {
                                                "aws:RequestTag/karpenter.sh/nodepool": "*"
                                            }
                                        }
                                    }
                                    {
                                        "Sid": "AllowScopedResourceTagging"
                                        "Effect": "Allow"
                                        "Resource": "arn:aws:ec2:${oxr.spec.parameters.region}:*:instance/*"
                                        "Action": "ec2:CreateTags"
                                        "Condition": {
                                            "StringEquals": {
                                                "aws:ResourceTag/kubernetes.io/cluster/${_statusClusterName}": "owned"
                                            }
                                            "StringLike": {
                                                "aws:ResourceTag/karpenter.sh/nodepool": "*"
                                            }
                                            "StringEqualsIfExists": {
                                                "aws:RequestTag/eks:eks-cluster-name": _statusClusterName
                                            }
                                            "ForAllValues:StringEquals": {
                                                "aws:TagKeys": [
                                                    "eks:eks-cluster-name"
                                                    "karpenter.sh/nodeclaim"
                                                    "Name"
                                                ]
                                            }
                                        }
                                    }
                                    {
                                        "Sid": "AllowScopedDeletion"
                                        "Effect": "Allow"
                                        "Resource": [
                                            "arn:aws:ec2:${oxr.spec.parameters.region}:*:instance/*"
                                            "arn:aws:ec2:${oxr.spec.parameters.region}:*:launch-template/*"
                                        ]
                                        "Action": [
                                            "ec2:TerminateInstances"
                                            "ec2:DeleteLaunchTemplate"
                                        ]
                                        "Condition": {
                                            "StringEquals": {
                                                "aws:ResourceTag/kubernetes.io/cluster/${_statusClusterName}": "owned"
                                            }
                                            "StringLike": {
                                                "aws:ResourceTag/karpenter.sh/nodepool": "*"
                                            }
                                        }
                                    }
                                    {
                                        "Sid": "AllowRegionalReadActions"
                                        "Effect": "Allow"
                                        "Resource": "*"
                                        "Action": [
                                            "ec2:DescribeAvailabilityZones"
                                            "ec2:DescribeImages"
                                            "ec2:DescribeInstances"
                                            "ec2:DescribeInstanceTypeOfferings"
                                            "ec2:DescribeInstanceTypes"
                                            "ec2:DescribeLaunchTemplates"
                                            "ec2:DescribeSecurityGroups"
                                            "ec2:DescribeSpotPriceHistory"
                                            "ec2:DescribeSubnets"
                                        ]
                                        "Condition": {
                                            "StringEquals": {
                                                "aws:RequestedRegion": oxr.spec.parameters.region
                                            }
                                        }
                                    }
                                    {
                                        "Sid": "AllowSSMReadActions"
                                        "Effect": "Allow"
                                        "Resource": "arn:aws:ssm:${oxr.spec.parameters.region}::parameter/aws/service/*"
                                        "Action": "ssm:GetParameter"
                                    }
                                    {
                                        "Sid": "AllowPricingReadActions"
                                        "Effect": "Allow"
                                        "Resource": "*"
                                        "Action": "pricing:GetProducts"
                                    }
                                    {
                                        "Sid": "AllowInterruptionQueueActions"
                                        "Effect": "Allow"
                                        "Resource": _statusSqsQueueArn
                                        "Action": [
                                            "sqs:DeleteMessage"
                                            "sqs:GetQueueUrl"
                                            "sqs:ReceiveMessage"
                                        ]
                                    }
                                    {
                                        "Sid": "AllowPassingInstanceRole"
                                        "Effect": "Allow"
                                        "Resource": _statusInstanceNodeRoleArn
                                        "Action": "iam:PassRole"
                                        "Condition": {
                                            "StringEquals": {
                                                "iam:PassedToService": "ec2.amazonaws.com"
                                            }
                                        }
                                    }
                                    {
                                        "Sid": "AllowAPIServerEndpointDiscovery"
                                        "Effect": "Allow"
                                        "Resource": "arn:aws:eks:${oxr.spec.parameters.region}:${_statusAccountId}:cluster/${_statusClusterName}"
                                        "Action": "eks:DescribeCluster"
                                    }
                                ]
                            })
                            }
                        ]
                        serviceAccount = {
                            name = "karpenter"
                            namespace = "karpenter"
                        }
                    }
                }
            }

    # Create SQS Queue for Karpenter
    sqsv1beta1.Queue {
        metadata = {
            **_metadata("sqsQueue")
        }
        spec = {
            **_defaults
            forProvider = {
                region = _region
                name = _sqsQueueName
                messageRetentionSeconds = 300
            }
        }
    }
    # Create Cloudwatch Event Rules
    # Health Event Rule
    cloudwatcheventsv1beta1.Rule {
        metadata = {
            **_metadata("ruleHealthEvent")
            annotations: {
                "crossplane.io/external-name" = _healthEventName
            }
            generateName = "${_id}-"
            labels = {"crossplane.io/composite": _id, "type": "HealthEvent"}
            name = _healthEventName
        }
        spec = {
            forProvider = {
                region = _region
                eventBusName = "default"
                eventPattern = """{
  "source": [
    "aws.health"
  ],
  "detail-type": [
    "AWS Health Event"
  ]
}"""
            }
            providerConfigRef = {
                name = _providerConfigName
            }
        }
    }
    # Instance Rebalance Rule
    cloudwatcheventsv1beta1.Rule {
        metadata = {
            **_metadata("ruleInstanceRebalance")
            annotations: {
                "crossplane.io/external-name" = _instanceRebalanceName
            }
            generateName = "${_id}-"
            labels = {"crossplane.io/composite": _id, "type": "InstanceRebalance"}
            name = _instanceRebalanceName
        }
        spec = {
            forProvider = {
                region = _region
                eventBusName = "default"
                eventPattern = """{
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "EC2 Instance Rebalance Recommendation"
  ]
}"""
            }
            providerConfigRef = {
                name = _providerConfigName
            }
        }
    }
    # Instance State Change Rule
    cloudwatcheventsv1beta1.Rule {
        metadata = {
            **_metadata("ruleInstanceStateChange")
            annotations: {
                "crossplane.io/external-name" = _instanceStateChangeName
            }
            generateName = "${_id}-"
            labels = {"crossplane.io/composite": _id, "type": "InstanceStateChange"}
            name = _instanceStateChangeName
        }
        spec = {
            forProvider = {
                region = _region
                eventBusName = "default"
                eventPattern = """{
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "EC2 Instance State-change Notification"
  ]
}"""
            }
            providerConfigRef = {
                name = _providerConfigName
            }
        }
    }
    # Spot Interrupt Rule
    cloudwatcheventsv1beta1.Rule {
        metadata = {
            **_metadata("ruleSpotInterrupt")
            annotations: {
                "crossplane.io/external-name" = _spotInterruptName
            }
            generateName = "${_id}-"
            labels = {"crossplane.io/composite": _id, "type": "SpotInterrupt"}
            name = _spotInterruptName
        }
        spec = {
            forProvider = {
                region = _region
                eventBusName = "default"
                eventPattern = """{
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "EC2 Spot Instance Interruption Warning"
  ]
}"""
            }
            providerConfigRef = {
                name = _providerConfigName
            }
        }
    }
    # Create Karpenter Helm Chart Release
    if _statusClusterName and _ocds.sqsQueue?.Resource?.status?.atProvider?.name:
        {
            apiVersion = "helm.crossplane.io/v1beta1"
            kind = "Release"
            metadata = {
                **_metadata("karpenterChart")
                generateName = "${_id}-"
                annotations: {
                    "crossplane.io/external-name" = "karpenter"
                }
            }
            spec = {
                deletionPolicy = "Orphan"
                forProvider = {
                    wait = True
                    chart = {
                        name = "karpenter"
                        repository = "oci://public.ecr.aws/karpenter"
                        version = "1.0.0"
                    }
                    namespace = "karpenter"
                    values = {
                        settings = {
                            clusterName = _statusClusterName
                            interruptionQueueName = _ocds.sqsQueue?.Resource?.status?.atProvider?.name
                        }
                    }
                }
                providerConfigRef = {
                    name = _id
                }
            }
        }
    # Create EC2NodeClass for Karpenter
    if _statusClusterName and _statusInstanceProfileName:
        kubernetesv1alpha1.Object {
            metadata = {
                **_metadata("karpenterNodeClass")
                generateName = "${_id}-"
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
                                "karpenter.sh/discovery" = _statusClusterName
                            }
                            subnetSelectorTerms = [
                                {
                                    tags = {
                                        "networks.aws.platform.upbound.io/network-id" = _id
                                    }
                                }
                            ]
                            securityGroupSelectorTerms = [
                                {
                                    tags = {
                                        "eks.aws.platform.upbound.io/discovery" = _id
                                        "aws:eks:cluster-name" = _statusClusterName
                                    }
                                }
                            ]
                            instanceProfile = _statusInstanceProfileName
                        }
                    }
                }
                providerConfigRef = {
                    name = _id
                }
            }
        }
    # Create NodePool for Karpenter
    kubernetesv1alpha1.Object {
        metadata = {
            **_metadata("karpenterNodePool")
            generateName = "${_id}-"
        }
        spec = {
            deletionPolicy = "Orphan"
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
                name = _id
            }
        }
    }
]
items = _items
