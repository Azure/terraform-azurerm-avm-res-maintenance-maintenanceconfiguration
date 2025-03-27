resource "azapi_resource" "maintenance_configuration" {
  type = "Microsoft.Maintenance/maintenanceConfigurations@2023-10-01-preview"
  body = {
    properties = {
      extensionProperties = var.scope == "InGuestPatch" ? merge(var.extension_properties, { InGuestPatchMode = var.in_guest_user_patch_mode }) : var.extension_properties
      installPatches = var.install_patches != null && var.scope == "InGuestPatch" ? {
        linuxParameters = var.install_patches.linux != null ? {
          classificationsToInclude  = var.install_patches.linux.classifications_to_include
          packageNameMasksToExclude = var.install_patches.linux.package_name_masks_to_exclude
          packageNameMasksToInclude = var.install_patches.linux.package_name_masks_to_include
        } : null
        rebootSetting = var.install_patches.reboot_setting
        windowsParameters = var.install_patches.windows != null ? {
          classificationsToInclude  = var.install_patches.windows.classifications_to_include
          excludeKbsRequiringReboot = var.install_patches.windows.exclude_kbs_requiring_reboot
          kbNumbersToExclude        = var.install_patches.windows.kb_numbers_to_exclude
          kbNumbersToInclude        = var.install_patches.windows.kb_numbers_to_include
        } : null
      } : null
      maintenanceScope = var.scope
      maintenanceWindow = var.window != null ? {
        duration           = var.window.duration
        expirationDateTime = var.window.expiration_date_time
        recurEvery         = var.window.recur_every
        StartDateTime      = var.window.start_date_time
        timeZone           = var.window.time_zone
      } : null
      visibility = var.visibility
    }
  }
  location  = var.location
  name      = var.name
  parent_id = "/subscriptions/${local.subscription_id}/resourceGroups/${var.resource_group_name}"
  tags      = var.tags
}

# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azapi_resource.maintenance_configuration.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.maintenance_configuration.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
