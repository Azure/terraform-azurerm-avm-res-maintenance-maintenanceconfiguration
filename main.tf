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
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_body_changes = length(var.ignore_body_changes.maintenance_maintenance_configurations) > 0 ? concat(
    ["properties.output"],
    var.ignore_body_changes.maintenance_maintenance_configurations
  ) : ["properties.output"]
  read_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = {
    id         = "id"
    name       = "name"
    properties = "properties"
    type       = "type"
  }
  retry          = var.retry
  tags           = var.tags
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = var.timeouts.maintenance_maintenance_configurations.create
    delete = var.timeouts.maintenance_maintenance_configurations.delete
    read   = var.timeouts.maintenance_maintenance_configurations.read
    update = var.timeouts.maintenance_maintenance_configurations.update
  }
}

module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.6.0"

  enable_telemetry                          = var.enable_telemetry
  lock                                      = var.lock
  role_assignment_definition_lookup_enabled = true
  role_assignment_definition_scope          = azapi_resource.this.id
  role_assignments                          = var.role_assignments
}

resource "azapi_resource" "role_assignments" {
  for_each = module.avm_interfaces.role_assignments_azapi

  name           = each.value.name
  parent_id      = azapi_resource.this.id
  type           = each.value.type
  body           = each.value.body
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = {
    id               = "id"
    name             = "name"
    principalId      = "properties.principalId"
    principalType    = "properties.principalType"
    roleDefinitionId = "properties.roleDefinitionId"
    scope            = "properties.scope"
    type             = "type"
  }
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name           = coalesce(var.lock.name, "lock-${var.lock.kind}")
  parent_id      = azapi_resource.this.id
  type           = module.avm_interfaces.lock_azapi.type
  body           = module.avm_interfaces.lock_azapi.body
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [time_sleep.wait_for_resource_destroy]
}

resource "time_sleep" "wait_for_resource_destroy" {
  destroy_duration = "20s"

  depends_on = [azapi_resource.this]
}
