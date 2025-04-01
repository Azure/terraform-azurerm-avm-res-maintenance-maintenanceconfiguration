terraform {
  required_version = "~> 1.5"
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.13, < 3"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "~> 0.1"
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
  version = "~> 0.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location            = azurerm_resource_group.this.location
  name                = var.name
  scope               = "InGuestPatch"
  resource_group_name = azurerm_resource_group.this.name

  window = {
    time_zone       = "Greenwich Standard Time"
    recur_every     = "2Day"
    start_date_time = "5555-10-01 00:00"
  }

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

  enable_telemetry = var.enable_telemetry
}
