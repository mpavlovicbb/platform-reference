output "network_id" {
  description = "Contract: VNet id for CAPZ AzureCluster.spec.networkSpec"
  value       = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  description = "Contract: node subnet identifiers"
  value       = [azurerm_subnet.nodes.id]
}

output "object_store" {
  description = "Contract: storage account for Loki and backups"
  value       = azurerm_storage_account.objects.id
}

output "ssh_key_ref" {
  description = "Contract: CAPZ injects SSH keys via machine templates"
  value       = null
}

output "resource_group" {
  description = "Resource group CAPZ deploys machines into"
  value       = azurerm_resource_group.this.name
}
