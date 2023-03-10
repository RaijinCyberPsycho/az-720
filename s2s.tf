terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "us" {
  name     = "us"
  location = "East US"
}

resource "azurerm_network_security_group" "example" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.us.location
  resource_group_name = azurerm_resource_group.us.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "us" {
  name                = "us"
  location            = azurerm_resource_group.us.location
  resource_group_name = azurerm_resource_group.us.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "us_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.us.name
  virtual_network_name = azurerm_virtual_network.us.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_public_ip" "us" {
  name                = "us"
  location            = azurerm_resource_group.us.location
  resource_group_name = azurerm_resource_group.us.name
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "us" {
  name                = "us-gateway"
  location            = azurerm_resource_group.us.location
  resource_group_name = azurerm_resource_group.us.name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "Basic"

  ip_configuration {
    public_ip_address_id          = azurerm_public_ip.us.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.us_gateway.id
  }
}

resource "azurerm_resource_group" "europe" {
  name     = "europe"
  location = "West Europe"
}

resource "azurerm_virtual_network" "europe" {
  name                = "europe"
  location            = azurerm_resource_group.europe.location
  resource_group_name = azurerm_resource_group.europe.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "europe_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.europe.name
  virtual_network_name = azurerm_virtual_network.europe.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_public_ip" "europe" {
  name                = "europe"
  location            = azurerm_resource_group.europe.location
  resource_group_name = azurerm_resource_group.europe.name
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "europe" {
  name                = "europe-gateway"
  location            = azurerm_resource_group.europe.location
  resource_group_name = azurerm_resource_group.europe.name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "Basic"

  ip_configuration {
    public_ip_address_id          = azurerm_public_ip.europe.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.europe_gateway.id
  }
}

resource "azurerm_virtual_network_gateway_connection" "us_to_europe" {
  name                = "us-to-europe"
  location            = azurerm_resource_group.us.location
  resource_group_name = azurerm_resource_group.us.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.us.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.europe.id

  shared_key = "SuperSecurePassword"
}

resource "azurerm_virtual_network_gateway_connection" "europe_to_us" {
  name                = "europe-to-us"
  location            = azurerm_resource_group.europe.location
  resource_group_name = azurerm_resource_group.europe.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.europe.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.us.id

  shared_key = "SuperSecurePass"
}