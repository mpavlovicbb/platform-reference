output "network_id" {
  description = "Contract: network identifier for CAPH HetznerCluster.spec"
  value       = hcloud_network.this.id
}

output "subnet_ids" {
  description = "Contract: node subnet identifiers"
  value       = [hcloud_network_subnet.nodes.id]
}

output "object_store" {
  description = "Contract: object storage locator (S3-compatible endpoint; buckets managed out-of-band, see README)"
  value       = null
}

output "ssh_key_ref" {
  description = "Contract: SSH key name for CAPH machine templates"
  value       = hcloud_ssh_key.admin.name
}

output "firewall_id" {
  description = "Firewall to attach in HCloudMachineTemplate"
  value       = hcloud_firewall.nodes.id
}

output "placement_group_id" {
  description = "Spread placement group for control-plane machines"
  value       = hcloud_placement_group.control_plane.id
}
