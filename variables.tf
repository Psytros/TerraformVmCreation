variable "location" {
  default = "switzerland north"
}

variable "resourceGroupName" {
  default = "TestMyTerraformGroup"
}

variable "vnetFirstName" {
  default = "vNetTerraformA"
}

variable "vnetFirstAddressPrefix" {
  default = "10.230.0.0/16"
}

variable "vnetFirstSubnetDefaultName" {
  default = "Default"
}

variable "vnetFirstSubnetDefaultAddressPrefix" {
  default = "10.230.0.0/24"
}

variable "vnetSecondName" {
  default = "vNetTerraformB"
}

variable "vnetSecondAddressPrefix" {
  default = "10.231.0.0/16"
}
variable "vnetSecondSubnetDefaultName" {
  default = "Default"
}

variable "vnetSecondSubnetDefaultAddressPrefix" {
  default = "10.231.0.0/24"
}

variable "vmAName" {
  default = "VmTerraform01"
}

variable "vmASize" {
  default = "Standard_B2ms"
}

variable "vmAImage" {
  default = "Standard_B2ms"
}

variable "vmAPrivateIp" {
  default = "10.230.0.4"
}

variable "vmAUserName" {
  default = "demousr"
}

variable "vmAPassword" {
  default = "Password123!"
}

variable "vmADataDiskSize" {
  default = 16
}

