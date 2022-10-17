# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
  
  cloud {
    organization = "COMPANY"
    workspaces {
      name = "WORKSPACE"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create resource group A
resource "azurerm_resource_group" "rg" {
  name     = var.resourceGroupName
  location = var.location
  
  tags = {
    Environment = "Infrastructure"
	  Type = "Network"
	}
}

# Create virtual network A
resource "azurerm_virtual_network" "vnetA" {
  name                = var.vnetFirstName
  address_space       = [var.vnetFirstAddressPrefix]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet vnet A
resource "azurerm_subnet" "vnetAsubnet" {
  address_prefixes      = [var.vnetFirstSubnetDefaultAddressPrefix]
  name                  = var.vnetFirstSubnetDefaultName
  resource_group_name   = azurerm_resource_group.rg.name
  virtual_network_name  = azurerm_virtual_network.vnetA.name
}

# Create virtual network B
resource "azurerm_virtual_network" "vnetB" {
  name                = var.vnetSecondName
  address_space       = [var.vnetSecondAddressPrefix]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet vnet B
resource "azurerm_subnet" "vnetBsubnet" {
  address_prefixes      = [var.vnetSecondSubnetDefaultAddressPrefix]
  name                  = var.vnetSecondSubnetDefaultName
  resource_group_name   = azurerm_resource_group.rg.name
  virtual_network_name  = azurerm_virtual_network.vnetB.name
}

# Create vnet peering between A and B
resource "azurerm_virtual_network_peering" "vnetAToB" {
  name                         = "${var.vnetFirstName}-${var.vnetSecondName}"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnetA.name
  remote_virtual_network_id    = azurerm_virtual_network.vnetB.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Create vnet peering between B and A
resource "azurerm_virtual_network_peering" "vnetBToA" {
  name                         = "${var.vnetSecondName}-${var.vnetFirstName}"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnetB.name
  remote_virtual_network_id    = azurerm_virtual_network.vnetA.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Create new pip for vm
resource "azurerm_public_ip" "VmAPip" {
  name                = "${var.vmAName}-Pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

# Create a nsg for vm
resource "azurerm_network_security_group" "VmANsg" {
  name                = "${var.vmAName}-Nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name = "AllowRdp"
    priority = 300
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    source_address_prefix = "*"
    destination_port_range = "3389"
    destination_address_prefix = "*"
  }
}

# Create network interface for vm
resource "azurerm_network_interface" "VmANic" {
  name                = "${var.vmAName}-Nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vnetAsubnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.vmAPrivateIp
    public_ip_address_id          = azurerm_public_ip.VmAPip.id
  }
}

# Attache nsg to nic
resource "azurerm_network_interface_security_group_association" "VmANsgAssign" {
  network_interface_id      = azurerm_network_interface.VmANic.id
  network_security_group_id = azurerm_network_security_group.VmANsg.id
}

# Create vm
resource "azurerm_windows_virtual_machine" "VmACompute" {
  name                  = var.vmAName
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [ azurerm_network_interface.VmANic.id ]
  size                  = var.vmASize
  admin_username        = var.vmAUserName
  admin_password        = var.vmAPassword

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

# Create data disk for vm
resource "azurerm_managed_disk" "VmADataDisk" {
  name                 = "${var.vmAName}-DataDisk"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.vmADataDiskSize
}

# Attach data disk to vm
resource "azurerm_virtual_machine_data_disk_attachment" "VmADataDiskAssign" {
  managed_disk_id    = azurerm_managed_disk.VmADataDisk.id
  virtual_machine_id = azurerm_windows_virtual_machine.VmACompute.id
  lun                = "10"
  caching            = "ReadWrite"
}