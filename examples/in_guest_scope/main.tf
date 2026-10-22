terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azapi" {}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.13.0"

  location         = var.location
  enable_telemetry = var.enable_telemetry
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/avm-utl-naming/azure"
  version = "0.2.0"
}

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  location         = module.regions.regions[random_integer.region_index.result].name
  name             = module.naming.resource_group.name_unique
  enable_telemetry = var.enable_telemetry
}

# This is the module call
module "test" {
  source = "../../"

  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location         = module.resource_group.location
  name             = var.name
  parent_id        = module.resource_group.resource_id
  scope            = "InGuestPatch"
  enable_telemetry = var.enable_telemetry
  extension_properties = {
    InGuestPatchMode = "User" # Can either 'Platform' or 'User'
  }
  install_patches = {
    linux = {
      classifications_to_include = ["Critical", "Security"]
    }
    reboot_setting = "IfRequired"
    windows = {
      classifications_to_include = ["Critical", "Security"]
    }
  }
  window = {
    time_zone       = "Greenwich Standard Time"
    recur_every     = "2Day"
    start_date_time = "5555-10-01 00:00"
  }
}
