# Invariants for ArgoCD Application manifests, enforced in CI by conftest.
# Kyverno guards the cluster at admission; these guard the repo at review.
package main

is_application if {
	input.kind == "Application"
	input.apiVersion == "argoproj.io/v1alpha1"
}

# Helm chart sources must pin an exact version. Git sources tracking main is
# this repo's own delivery model; floating CHART versions is how upgrades
# happen to you instead of by you.
deny contains msg if {
	is_application
	input.spec.source.chart
	floating := {"main", "master", "HEAD", "latest", "*", ""}
	floating[input.spec.source.targetRevision]
	msg := sprintf("Application %s: helm chart %q must pin an exact version, not %q",
		[input.metadata.name, input.spec.source.chart, input.spec.source.targetRevision])
}

# Automated sync without selfHeal quietly stops reconciling drift.
deny contains msg if {
	is_application
	input.spec.syncPolicy.automated
	not input.spec.syncPolicy.automated.selfHeal
	msg := sprintf("Application %s: automated sync without selfHeal leaves drift standing",
		[input.metadata.name])
}
