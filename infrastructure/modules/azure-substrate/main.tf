# Substrate only: resource group, network, NSG, and an object store for Loki
# and backups. VMs are Cluster API's job (CAPZ); cluster contents are GitOps.

locals {
  prefix = "${var.name}-${var.environment}"
  # Storage account names: 3-24 chars, lowercase alphanumeric only.
  storage_name = substr(replace("${var.name}${var.environment}objects", "-", ""), 0, 24)
}

resource "azurerm_resource_group" "this" {
  name     = local.prefix
  location = var.location
  tags = {
    environment = var.environment
    managed-by  = "terraform"
  }
}

resource "azurerm_virtual_network" "this" {
  name                = "${local.prefix}-vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  address_space       = [var.network_cidr]
  tags                = azurerm_resource_group.this.tags
}

resource "azurerm_subnet" "nodes" {
  name                 = "${local.prefix}-nodes"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.node_subnet_cidr]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_network_security_group" "nodes" {
  name                = "${local.prefix}-nodes-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = azurerm_resource_group.this.tags

  security_rule {
    name                       = "kubernetes-api-from-admin"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefixes    = var.allowed_admin_cidrs
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nodes" {
  subnet_id                 = azurerm_subnet.nodes.id
  network_security_group_id = azurerm_network_security_group.nodes.id
}

resource "azurerm_storage_account" "objects" {
  name                            = local.storage_name
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  account_tier                    = "Standard"
  account_replication_type        = "ZRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  tags                            = azurerm_resource_group.this.tags

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [azurerm_subnet.nodes.id]
  }
}

resource "azurerm_storage_container" "loki" {
  name                  = "loki"
  storage_account_id    = azurerm_storage_account.objects.id
  container_access_type = "private"
}
