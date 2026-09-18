mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Maintenance/maintenanceConfigurations/mc-test"
      name = "mc-test"
    }
  }
}

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "modtm" {}
mock_provider "random" {}

variables {
  enable_telemetry    = false
  extension_properties = {
    InGuestPatchMode = "User"
  }
  install_patches = {
    reboot_setting = "IfRequired"
  }
  location            = "eastus"
  name                = "mc-test"
  resource_group_name = "rg-test"
  scope               = "InGuestPatch"
  window = {
    recur_every     = "2Day"
    start_date_time = "5555-10-01 00:00"
    time_zone       = "Greenwich Standard Time"
  }
}

run "accepts_valid_in_guest_patch_mode" {
  command = apply

  assert {
    condition     = output.name == "mc-test"
    error_message = "The module should accept a valid InGuestPatchMode value."
  }
}

run "rejects_missing_in_guest_patch_mode" {
  command = plan

  variables {
    extension_properties = {}
  }

  expect_failures = [
    var.extension_properties
  ]
}

run "rejects_invalid_in_guest_patch_mode" {
  command = plan

  variables {
    extension_properties = {
      InGuestPatchMode = "Invalid"
    }
  }

  expect_failures = [
    var.extension_properties
  ]
}
