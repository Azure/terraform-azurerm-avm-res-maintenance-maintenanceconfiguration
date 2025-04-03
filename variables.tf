# required AVM interfaces
# remove only if not supported by the resource

variable "location" {
  type        = string
  description = "(Required) Azure region where the resource should be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "(Required) The name of the this resource."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]{0,110}[a-zA-Z0-9_]$", var.name))
    error_message = "The length must be between 1 and 112 characters. The first character must be a letter or number. The last character must be a letter, number, or underscore. The remaining characters must be letters, numbers, periods, underscores, or dashes."
  }
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "(Required) The resource group where the resources will be deployed."
}

variable "scope" {
  type        = string
  description = "(Required) The scope of the Maintenance Configuration. Possible values are Extension, Host, InGuestPatch, OSImage, SQLDB or SQLManagedInstance."

  validation {
    condition     = contains(["Extension", "Host", "InGuestPatch", "OSImage", "Resource", "SQLDB", "SQLManagedInstance"], var.scope)
    error_message = "The `scope` must be one of the following: 'Extension', 'Host', 'InGuestPatch', 'OSImage', `Resource`, 'SQLDB', or 'SQLManagedInstance'."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
(Optional) This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "extension_properties" {
  type        = map(string)
  default     = {}
  description = "(Optional) The extension properties of the Maintenance Configuration. Must be specified when scope is Extension."
  nullable    = false
}

variable "install_patches" {
  type = object({
    linux = optional(object({
      classifications_to_include    = optional(list(string), ["Critical", "Security"])
      package_name_masks_to_exclude = optional(list(string), [])
      package_name_masks_to_include = optional(list(string), [])
    }))
    reboot_setting = optional(string)
    windows = optional(object({
      classifications_to_include   = optional(list(string), ["Critical", "Security"])
      exclude_kbs_requiring_reboot = optional(bool)
      kb_numbers_to_exclude        = optional(list(string), [])
      kb_numbers_to_include        = optional(list(string), [])
    }))
  })
  default     = {}
  description = <<DESCRIPTION
(Optional) The install patches of the Maintenance Configuration. Must be specified when scope is InGuestPatch.

- `linux` - (Optional) The Linux parameters of the Maintenance Configuration. This property only applies when scope is set to InGuestPatch.
  - `classifications_to_include` - (Optional) The classifications to include. Defaults to Critical & Security 
  - `package_name_masks_to_exclude` - (Optional) The package name masks to exclude.
  - `package_name_masks_to_include` - (Optional) The package name masks to include.
- `reboot_setting` - (Optional) Possible reboot preference as defined by the user based on which it would be decided to reboot the machine or not after the patch operation is completed. Possible values are Always, IfRequired and Never. This property only applies when scope is set to InGuestPatch.
- `windows` - (Optional) The Windows parameters of the Maintenance Configuration. This property only applies when scope is set to InGuestPatch.
  - `classifications_to_include` - (Optional) List of Classification category of patches to be patched. Possible values are Critical, Security, UpdateRollup, FeaturePack, ServicePack, Definition, Tools and Updates. Defaults to Critical & Security 
  - `exclude_kbs_requiring_reboot` - (Optional) The exclude Kbs requiring reboot.
  - `kb_numbers_to_exclude` - (Optional) The KB numbers to exclude.
  - `kb_numbers_to_include` - (Optional) The KB numbers to include.
DESCRIPTION
  nullable    = false

  validation {
    condition     = var.scope != "InGuestPatch" || var.install_patches != null
    error_message = "The `install_patches` block must be specified when `scope` is 'InGuestPatch'."
  }
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
(Optional)  Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  (Optional) A map of role assignments to create on the <RESOURCE>. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.
  
  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
  DESCRIPTION
  nullable    = false
}

variable "subscription_id" {
  type        = string
  default     = null
  description = "(Optional) This specifies a subscription ID which is used to construct the parent ID for the maintenance configuration."
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "visibility" {
  type        = string
  default     = "Custom"
  description = "(Optional) The visibility of the Maintenance Configuration. The only allowable value is Custom. Defaults to Custom."
}

variable "window" {
  type = object({
    duration             = optional(string, "01:30")
    expiration_date_time = optional(string)
    recur_every          = string
    start_date_time      = string
    time_zone            = string
  })
  default     = null
  description = <<DESCRIPTION
(Optional) The maintenance window of the Maintenance Configuration.

- `duration` - (Optional) The duration of the maintenance window in HH:mm format. Defaults to 01:30
- `expiration_date_time` - (Optional) Effective expiration date of the maintenance window in YYYY-MM-DD hh:mm format.
- `recur_every` - (Required) The rate at which a maintenance window is expected to recur. The rate can be expressed as daily, weekly, or monthly schedules.
- `start_date_time` - (Required) Effective start date of the maintenance window in YYYY-MM-DD hh:mm format.
- `time_zone` - (Required) The time zone for the maintenance window. A list of timezones can be obtained by executing [System.TimeZoneInfo]::GetSystemTimeZones() in PowerShell.
DESCRIPTION
}
