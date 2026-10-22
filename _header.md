# terraform-azurerm-avm-res-maintenance-maintenanceconfiguration

This modules is used to create and manage a Maintenance Configuration which is a supporting service of [Azure Update Manager](https://learn.microsoft.com/en-us/azure/update-manager/).

For information on how to consume this module, consult the [examples](https://github.com/Azure/terraform-azurerm-avm-res-maintenance-maintenanceconfiguration/tree/main/examples) directory.

## Upgrading from v0.1.0

The maintenance configuration already used AzAPI in v0.1.0. This upgrade renames its
Terraform address and migrates the AzureRM lock and role assignments to AzAPI at
the same module and collection boundaries. Existing consumer module keys and role
assignment map keys must stay unchanged.

Use Terraform `>= 1.9, < 2.0` and AzAPI `~> 2.12`. Replace the module's
`resource_group_name` argument with the existing resource group's fully-qualified
`parent_id`, for example:

```hcl
parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example"
```

The `name` and `resource_id` outputs retain their existing meanings and types.
The new `timeouts` object has flat `create`, `read`, `update`, and `delete` fields
and defaults to provider timeouts. Non-empty `ignore_body_changes` lists require
Terraform 1.11 or later; the default empty lists do not.

### Automatic state conversion

The module owns these declarative moves. Do not copy them into the consumer or
run `terraform state mv` for the standard upgrade:

| Released address (relative to the consumer module) | New address | Mechanism |
| --- | --- | --- |
| `azapi_resource.maintenance_configuration` | `azapi_resource.this` | Same-provider move |
| `azurerm_management_lock.this[0]` | `azapi_resource.lock[0]` | Provider state conversion |
| `azurerm_role_assignment.this["key"]` | `azapi_resource.role_assignments["key"]` | Provider state conversion, preserving each key and existing assignment GUID |
| `modtm_telemetry.telemetry` and `random_uuid.telemetry` | No replacement state binding | Managed telemetry `removed` blocks with `destroy = false` |

There are no inline ARM children to import and no `avm_managed_migration_enabled`
flag for the standard upgrade. Leave unrelated configuration unchanged during
the migration.

1. Back up state securely outside version control and record the existing ARM
   resource IDs, role assignment GUIDs, lock name and notes. Keep the original
   AzureRM provider configuration (including `features {}`) available through the
   upgrade apply. Retain the old modtm and random providers for initialization
   while state still refers to the old telemetry resources.
2. Remove any `ReadOnly` lock before upgrading: it blocks the reconciliation PUT.
   Temporarily omit that lock from the module input as well, then restore it in a
   separate apply after the upgrade. A `CanNotDelete` lock may remain configured.
3. Change the module source/version and `parent_id`, retaining the same resource
   group, name, location, scope, role assignment keys and other settings.
4. Initialize and save a plan:

   ```powershell
   terraform init -upgrade
   terraform plan -out=migration.tfplan
   terraform show -json migration.tfplan > migration.plan.json
   ```

5. Inspect all moves, output changes and actions before applying. **Do not apply
   a plan that deletes or replaces the maintenance configuration, lock or role
   assignments.** In-place reconciliation is possible. New random UUID state
   inside the interface utility does not replace existing assignment GUIDs.
   A lock-removal timer is created only when a lock is configured.
6. Apply the inspected saved plan with `terraform apply migration.tfplan`. Check
   that the resource IDs, assignment GUIDs and lock details are unchanged, then
   run another plan to establish convergence. Remove obsolete provider
   configurations only after their state references are gone.

Current managed telemetry creates empty subscription-scoped Azure deployments
when enabled, including in the interface utility. The deployment identity needs
`Microsoft.Resources/deployments/read`, `write`, and `delete` at the active
subscription scope. Telemetry intentionally updates only its
`body.properties.template.outputs.apply_id.value` timestamp on each normal plan.
With `enable_telemetry = false`, require a completely empty follow-up plan; with
telemetry enabled, require no infrastructure drift beyond those exact deployment
timestamps. The opt-out is forwarded to the utility.

### Cross-tenant role assignment exception

AzureRM can store a cross-tenant assignment ID as `<ARM-ID>|<tenant-ID>`.
AzAPI's provider move does not strip that suffix, so this case is **not** covered
by the automatic move. Before planning the candidate, back up state, obtain the
existing assignment's ARM ID and GUID, and remove only its old binding:

```powershell
terraform state rm 'module.maintenance.azurerm_role_assignment.this["delegated"]'
```

In the consumer root, add an import targeting the corresponding new address:

```hcl
import {
  to = module.maintenance.azapi_resource.role_assignments["delegated"]
  id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Maintenance/maintenanceConfigurations/example/providers/Microsoft.Authorization/roleAssignments/11111111-1111-1111-1111-111111111111"
}
```

Use the actual consumer module path, including any module instance keys, and the
actual existing ARM ID **without** the tenant suffix. Preserve the original
assignment inputs and provider tenant context. Inspect and apply the saved import
plan, verify the GUID and delegated identity, then remove the root import block.
Never remove a binding without its matching import. This exceptional procedure
requires separate state-backed verification in the consumer's tenant context.

### Behavior and recovery

Lock names and default notes are preserved. Lock deletion waits 30 seconds before
deleting covered resources, including role assignments. Role definition names are
resolved case-insensitively at the existing resource group; tenant-level definition
IDs are subscription-qualified. `skip_service_principal_aad_check = true` supplies
`principalType = "ServicePrincipal"` unless an explicit principal type overrides it.
Changing immutable assignment inputs still requires replacement; perform such
changes separately from the upgrade. The `name` input controls new assignments;
an adopted assignment retains its GUID, and a later explicit name change triggers
replacement.

Do not assume reverting the module version rolls back converted provider state.
After an apply, recovery requires reconciling both state and Azure, using the
protected backup and verified live identities. A saved state alone does not undo
Azure mutations.
