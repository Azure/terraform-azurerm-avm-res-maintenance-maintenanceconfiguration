mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}

variables {
  enable_telemetry = false
  location         = "eastus"
  name             = "mc-test"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
}

run "maps_install_patches_to_arm_body" {
  command = apply

  variables {
    scope = "InGuestPatch"
    install_patches = {
      linux = {
        classifications_to_include    = ["Critical", "Security"]
        package_name_masks_to_exclude = ["exclude-package"]
        package_name_masks_to_include = ["include-package"]
      }
      reboot_setting = "IfRequired"
      windows = {
        classifications_to_include   = ["Critical", "Security"]
        exclude_kbs_requiring_reboot = true
        kb_numbers_to_exclude        = ["KB123456"]
        kb_numbers_to_include        = ["KB789101"]
      }
    }
  }

  assert {
    condition     = jsonencode(azapi_resource.this.body.properties.installPatches.linuxParameters.classificationsToInclude) == jsonencode(["Critical", "Security"])
    error_message = "Linux classifications_to_include should map to installPatches.linuxParameters.classificationsToInclude."
  }

  assert {
    condition     = jsonencode(azapi_resource.this.body.properties.installPatches.linuxParameters.packageNameMasksToExclude) == jsonencode(["exclude-package"])
    error_message = "Linux package_name_masks_to_exclude should map to installPatches.linuxParameters.packageNameMasksToExclude."
  }

  assert {
    condition     = jsonencode(azapi_resource.this.body.properties.installPatches.linuxParameters.packageNameMasksToInclude) == jsonencode(["include-package"])
    error_message = "Linux install patch inputs should map to the ARM-cased installPatches.linuxParameters body."
  }

  assert {
    condition     = azapi_resource.this.body.properties.installPatches.rebootSetting == "IfRequired"
    error_message = "The reboot_setting input should map to installPatches.rebootSetting."
  }

  assert {
    condition     = jsonencode(azapi_resource.this.body.properties.installPatches.windowsParameters.classificationsToInclude) == jsonencode(["Critical", "Security"])
    error_message = "Windows classifications_to_include should map to installPatches.windowsParameters.classificationsToInclude."
  }

  assert {
    condition     = azapi_resource.this.body.properties.installPatches.windowsParameters.excludeKbsRequiringReboot
    error_message = "Windows exclude_kbs_requiring_reboot should map to installPatches.windowsParameters.excludeKbsRequiringReboot."
  }

  assert {
    condition     = jsonencode(azapi_resource.this.body.properties.installPatches.windowsParameters.kbNumbersToExclude) == jsonencode(["KB123456"])
    error_message = "Windows kb_numbers_to_exclude should map to installPatches.windowsParameters.kbNumbersToExclude."
  }

  assert {
    condition     = jsonencode(azapi_resource.this.body.properties.installPatches.windowsParameters.kbNumbersToInclude) == jsonencode(["KB789101"])
    error_message = "Windows kb_numbers_to_include should map to installPatches.windowsParameters.kbNumbersToInclude."
  }
}

run "omits_install_patches_outside_in_guest_patch" {
  command = apply

  variables {
    scope = "Host"
  }

  assert {
    condition     = azapi_resource.this.body.properties.installPatches == null
    error_message = "installPatches should be omitted unless scope is InGuestPatch."
  }
}
