output "substrate" {
  description = "Contract outputs consumed by the Cluster API manifests"
  value = {
    network_id         = module.substrate.network_id
    subnet_ids         = module.substrate.subnet_ids
    ssh_key_ref        = module.substrate.ssh_key_ref
    firewall_id        = module.substrate.firewall_id
    placement_group_id = module.substrate.placement_group_id
  }
}
