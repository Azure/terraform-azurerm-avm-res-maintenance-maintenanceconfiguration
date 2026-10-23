resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.maintenance_maintenance_configurations
  body = {
    properties = {
      extensionProperties = var.extension_properties
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
        startDateTime      = var.window.start_date_time
        timeZone           = var.window.time_zone
      } : null
      visibility = var.visibility
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.maintenance_maintenance_configurations) > 0 ? var.ignore_body_changes.maintenance_maintenance_configurations : null
  response_export_values = []
  retry                  = var.retry
  tags                   = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

data "azapi_resource_list" "role_definitions" {
  count = length(var.role_assignments) > 0 ? 1 : 0

  parent_id = var.parent_id
  type      = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  response_export_values = {
    results = "value[].{id: id, role_name: properties.roleName}"
  }
}

module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.9.0"

  location                                  = var.location
  enable_telemetry                          = var.enable_telemetry
  lock                                      = local.lock
  role_assignment_definition_lookup_enabled = false
  role_assignments                          = local.role_assignments
}

resource "azapi_resource" "role_assignments" {
  for_each = var.role_assignments

  name                 = module.avm_interfaces.role_assignments_azapi[each.key].name
  parent_id            = azapi_resource.this.id
  type                 = var.resource_types.authorization_role_assignments
  body                 = module.avm_interfaces.role_assignments_azapi[each.key].body
  ignore_body_changes  = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  ignore_casing        = true
  ignore_null_property = true
  replace_triggers_external_values = {
    name                                   = each.value.name
    condition                              = each.value.condition
    condition_version                      = each.value.condition_version
    delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
    description                            = each.value.description
    principal_id                           = lower(each.value.principal_id)
    principal_type                         = local.role_assignments[each.key].principal_type
    role_definition_id_or_name             = lower(each.value.role_definition_id_or_name)
  }
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    # Preserve the GUID adopted from AzureRM instead of replacing a locked assignment.
    ignore_changes = [name]

    precondition {
      condition     = strcontains(lower(local.role_assignments[each.key].role_definition_id_or_name), local.role_definition_resource_substring)
      error_message = "The role definition `${each.value.role_definition_id_or_name}` was not found. Supply a role name available at the resource group or a role definition resource ID."
    }
  }
}

resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name                = coalesce(var.lock.name, "lock-${var.lock.kind}")
  parent_id           = azapi_resource.this.id
  type                = var.resource_types.authorization_locks
  body                = module.avm_interfaces.lock_azapi.body
  ignore_body_changes = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  replace_triggers_external_values = {
    kind  = var.lock.kind
    notes = local.lock.notes
  }
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [time_sleep.wait_for_resource_destroy]
}

resource "time_sleep" "wait_for_resource_destroy" {
  count = var.lock != null ? 1 : 0

  destroy_duration = "30s"
  triggers = {
    resource_id = azapi_resource.this.id
  }

  depends_on = [azapi_resource.this, azapi_resource.role_assignments]
}
