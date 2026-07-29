output "substrate" {
  description = "Contract outputs consumed by the Cluster API manifests"
  value = {
    network_id        = module.substrate.network_id
    subnet_ids        = module.substrate.subnet_ids
    public_subnet_ids = module.substrate.public_subnet_ids
    object_store      = module.substrate.object_store
  }
}
