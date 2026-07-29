# Invariants for raw workload manifests in this repo — the same rules Kyverno
# enforces at admission, caught earlier and cheaper at review time.
package main

pod_spec := input.spec.template.spec if {
	input.kind in {"Deployment", "StatefulSet", "DaemonSet"}
}

pod_spec := input.spec.template.spec if {
	input.kind == "Job"
}

all_containers contains c if {
	some c in pod_spec.containers
}

all_containers contains c if {
	some c in pod_spec.initContainers
}

deny contains msg if {
	some c in all_containers
	not c.resources.requests.cpu
	msg := sprintf("%s %s: container %q has no cpu request", [input.kind, input.metadata.name, c.name])
}

deny contains msg if {
	some c in all_containers
	not c.resources.requests.memory
	msg := sprintf("%s %s: container %q has no memory request", [input.kind, input.metadata.name, c.name])
}

deny contains msg if {
	some c in all_containers
	endswith(c.image, ":latest")
	msg := sprintf("%s %s: container %q uses :latest", [input.kind, input.metadata.name, c.name])
}
