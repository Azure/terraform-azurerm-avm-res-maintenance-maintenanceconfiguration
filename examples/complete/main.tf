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
  features {}
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

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location                 = azurerm_resource_group.this.location
  name                     = var.name
  scope                    = "InGuestPatch"
  resource_group_name      = azurerm_resource_group.this.name
  in_guest_user_patch_mode = "User"
  visibility               = "Custom"
  enable_telemetry         = var.enable_telemetry

  tags = {
    environment = "avm"
  }

  extension_properties = {
    example = "complete"
  }

  window = {
    time_zone            = "Greenwich Standard Time"
    recur_every          = "2Day"
    start_date_time      = "5555-10-01 00:00"
    expiration_date_time = "6666-10-01 00:00"
    duration             = "01:30"
  }

  install_patches = {
    linux = {
      classifications_to_include    = ["Critical", "Security"]
      package_name_masks_to_exclude = ["package1"]
      package_name_masks_to_include = ["package2"]
    }
    reboot_setting = "IfRequired"
    windows = {
      classifications_to_include   = ["Critical", "Security"]
      exclude_kbs_requiring_reboot = true
      kb_numbers_to_exclude        = ["KB123456"]
      kb_numbers_to_include        = ["KB789101"]
    }
  }

  role_assignments = {
    role1 = {
      principal_id               = azurerm_user_assigned_identity.this.principal_id
      role_definition_id_or_name = "Contributor"
    }
  }
}
