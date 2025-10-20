import models.io.crossplane.kubernetes.v1alpha1 as kubernetesv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as platformawsv1alpha1
import resources
import conditions

observedResources_for_test_1 = [
    resources._accessEntry,
    resources._queue,
    resources._role,
    resources._instanceProfile,
]

observedResources_for_test_2 = observedResources_for_test_1 + [ 
    platformawsv1alpha1.XPodIdentity {
        **resources._xPodIdentity
        status: {
            conditions: conditions._readyConditions
            podIdentity : {
                clusterName: "configuration-aws-eks-karpenter-9wfx9"
                roleArn: "arn:aws:iam::123456789012:role/test-role"
            }
        }
    }
]

_assertResources_for_test_1 = [
    resources._xKarpenter,
    resources._nodeClass,
    resources._xPodIdentity
]

_assertResources_for_test_2 = _assertResources_for_test_1 + [
    resources._helmResources
]

_test1 = metav1alpha1.CompositionTest {
    metadata.name: "xkarpenter"
    spec = {
        assertResources: _assertResources_for_test_1
        observedResources = observedResources_for_test_1
        compositionPath = "apis/xkarpenters/composition.yaml"
        xrPath = "examples/karpenter-xr.yaml"
        xrdPath = "apis/xkarpenters/definition.yaml"
        timeoutSeconds = 60
        validate = False
    }
}

_test2 = metav1alpha1.CompositionTest {
    metadata.name: "xkarpenter-with-observed"
    spec = {
        assertResources: _assertResources_for_test_2
        observedResources = observedResources_for_test_2
        compositionPath = "apis/xkarpenters/composition.yaml"
        xrPath = "examples/karpenter-xr.yaml"
        xrdPath = "apis/xkarpenters/definition.yaml"
        timeoutSeconds = 60
        validate = False
    }
}

items = [_test1, _test2]
