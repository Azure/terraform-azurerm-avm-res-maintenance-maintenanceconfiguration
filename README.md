<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-res-maintenance-maintenanceconfiguration

This modules is used to create and manage a Maintenance Configuration which is a supporting service of [Azure Update Manager](https://learn.microsoft.com/en-us/azure/update-manager/).

For information on how to consume this module, consult the [examples](https://github.com/Azure/terraform-azurerm-avm-res-maintenance-maintenanceconfiguration/tree/main/examples) directory.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (>= 1.13, < 3)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azapi_resource.maintenance_configuration](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_client_config.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_location"></a> [location](#input\_location)

Description: (Required) Azure region where the resource should be deployed.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: (Required) The name of the this resource.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: (Required) The resource group where the resources will be deployed.

Type: `string`

### <a name="input_scope"></a> [scope](#input\_scope)

Description: (Required) The scope of the Maintenance Configuration. Possible values are Extension, Host, InGuestPatch, OSImage, SQLDB or SQLManagedInstance.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: (Optional) This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_extension_properties"></a> [extension\_properties](#input\_extension\_properties)

Description: (Optional) The extension properties of the Maintenance Configuration. Must be specified when scope is Extension.

Type: `map(any)`

Default: `{}`

### <a name="input_install_patches"></a> [install\_patches](#input\_install\_patches)

Description: (Optional) The install patches of the Maintenance Configuration. Must be specified when scope is InGuestPatch.

- `linux` - (Optional) The Linux parameters of the Maintenance Configuration. This property only applies when scope is set to InGuestPatch.
  - `classifications_to_include` - (Optional) The classifications to include.
  - `package_name_masks_to_exclude` - (Optional) The package name masks to exclude.
  - `package_name_masks_to_include` - (Optional) The package name masks to include.
- `reboot_setting` - (Optional) Possible reboot preference as defined by the user based on which it would be decided to reboot the machine or not after the patch operation is completed. Possible values are Always, IfRequired and Never. This property only applies when scope is set to InGuestPatch.
- `windows` - (Optional) The Windows parameters of the Maintenance Configuration. This property only applies when scope is set to InGuestPatch.
  - `classifications_to_include` - (Optional) List of Classification category of patches to be patched. Possible values are Critical, Security, UpdateRollup, FeaturePack, ServicePack, Definition, Tools and Updates.
  - `exclude_kbs_requiring_reboot` - (Optional) The exclude Kbs requiring reboot.
  - `kb_numbers_to_exclude` - (Optional) The KB numbers to exclude.
  - `kb_numbers_to_include` - (Optional) The KB numbers to include.

Type:

```hcl
object({
    linux = optional(object({
      classifications_to_include    = optional(list(string), [])
      package_name_masks_to_exclude = optional(list(string), [])
      package_name_masks_to_include = optional(list(string), [])
    }))
    reboot_setting = optional(string)
    windows = optional(object({
      classifications_to_include   = optional(list(string), [])
      exclude_kbs_requiring_reboot = optional(bool)
      kb_numbers_to_exclude        = optional(list(string), [])
      kb_numbers_to_include        = optional(list(string), [])
    }))
  })
```

Default: `null`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: (Optional)  Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description:   (Optional) A map of role assignments to create on the <RESOURCE>. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id)

Description: (Optional) This specifies a subscription ID which is used to construct the parent ID for the maintenance configuration.

Type: `string`

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags of the resource.

Type: `map(string)`

Default: `null`

### <a name="input_visibility"></a> [visibility](#input\_visibility)

Description: (Optional) The visibility of the Maintenance Configuration. The only allowable value is Custom. Defaults to Custom.

Type: `string`

Default: `"Custom"`

### <a name="input_window"></a> [window](#input\_window)

Description: (Optional) The maintenance window of the Maintenance Configuration.

- `duration` - (Optional) The duration of the maintenance window in HH:mm format.
- `expiration_date_time` - (Optional) Effective expiration date of the maintenance window in YYYY-MM-DD hh:mm format.
- `recur_every` - (Required) The rate at which a maintenance window is expected to recur. The rate can be expressed as daily, weekly, or monthly schedules.
- `start_date_time` - (Required) Effective start date of the maintenance window in YYYY-MM-DD hh:mm format.
- `time_zone` - (Required) The time zone for the maintenance window. A list of timezones can be obtained by executing [System.TimeZoneInfo]::GetSystemTimeZones() in PowerShell.

Type:

```hcl
object({
    duration             = optional(string, "01:30")
    expiration_date_time = optional(string)
    recur_every          = string
    start_date_time      = string
    time_zone            = string
  })
```

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_name"></a> [name](#output\_name)

Description: The name of the Maintenance Configuration resource.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The ID of the Maintenance Configuration resource.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->