terraform {
  required_version = "~> 1.5"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.13, < 3"
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
  version = "0.12.0"

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
  source  = "Azure/naming/azurerm"
  version = "0.4.4"
}

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  location         = module.regions.regions[random_integer.region_index.result].name
  name             = module.naming.resource_group.name_unique
  enable_telemetry = var.enable_telemetry
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
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
