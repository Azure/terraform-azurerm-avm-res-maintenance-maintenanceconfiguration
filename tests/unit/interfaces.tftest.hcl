mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Maintenance/maintenanceConfigurations/mc-test"
    }
  }

  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [{
          id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
          role_name = "Contributor"
        }]
      }
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "random" {
  mock_resource "random_uuid" {
    defaults = {
      result = "11111111-1111-1111-1111-111111111111"
    }
  }
}

mock_provider "time" {}

variables {
  enable_telemetry = false
  location         = "eastus"
  name             = "mc-test"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
  scope            = "Host"
}

run "defaults_have_no_interfaces_or_lock_timer" {
  command = apply

  assert {
    condition     = length(azapi_resource.lock) == 0 && length(azapi_resource.role_assignments) == 0 && length(time_sleep.wait_for_resource_destroy) == 0
    error_message = "No interface resources or lock-removal timer should be created by default."
  }

  assert {
    condition     = azapi_resource.this.timeouts == null
    error_message = "Null timeouts must leave provider defaults intact."
  }

  assert {
    condition     = output.resource_id == azapi_resource.this.id && output.name == azapi_resource.this.name
    error_message = "The existing discrete outputs must retain their meanings."
  }
  assert {
    condition     = length(azapi_resource.telemetry) == 0 && length(terraform_data.telemetry) == 0
    error_message = "Disabling telemetry must omit the managed deployment and correlation state."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "combines_lock_and_normalized_role_assignments" {
  command = apply

  variables {
    lock = {
      kind = "CanNotDelete"
    }
    role_assignments = {
      lowercase_name = {
        role_definition_id_or_name       = "contributor"
        principal_id                     = "22222222-2222-2222-2222-222222222222"
        skip_service_principal_aad_check = true
      }
      tenant_definition = {
        name                       = "33333333-3333-3333-3333-333333333333"
        role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
        principal_id               = "44444444-4444-4444-4444-444444444444"
        principal_type             = "Group"
      }
      qualified_definition = {
        role_definition_id_or_name       = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
        principal_id                     = "55555555-5555-5555-5555-555555555555"
        principal_type                   = "User"
        skip_service_principal_aad_check = true
      }
    }
    retry = {
      error_message_regex  = ["ScopeLocked"]
      interval_seconds     = 5
      max_interval_seconds = 30
    }
    timeouts = {
      create = "40m"
      read   = "10m"
      update = "45m"
      delete = "50m"
    }
  }

  assert {
    condition     = azapi_resource.lock[0].name == "lock-CanNotDelete" && azapi_resource.lock[0].body.properties.notes == "Cannot delete the resource or its child resources."
    error_message = "The AzureRM-generated lock name and notes must survive migration."
  }

  assert {
    condition     = time_sleep.wait_for_resource_destroy[0].destroy_duration == "30s" && time_sleep.wait_for_resource_destroy[0].triggers.resource_id == azapi_resource.this.id
    error_message = "The lock-removal pause must follow the covered resource identity."
  }

  assert {
    condition     = data.azapi_resource_list.role_definitions[0].parent_id == var.parent_id && azapi_resource.role_assignments["lowercase_name"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
    error_message = "Role names must resolve case-insensitively at the known parent scope."
  }

  assert {
    condition     = azapi_resource.role_assignments["tenant_definition"].body.properties.roleDefinitionId == azapi_resource.role_assignments["qualified_definition"].body.properties.roleDefinitionId
    error_message = "Tenant-level and subscription-qualified definition IDs must normalize equally."
  }

  assert {
    condition     = azapi_resource.role_assignments["lowercase_name"].body.properties.principalType == "ServicePrincipal" && azapi_resource.role_assignments["qualified_definition"].body.properties.principalType == "User"
    error_message = "The AAD-check flag must supply ServicePrincipal without overriding an explicit principal type."
  }

  assert {
    condition     = azapi_resource.role_assignments["tenant_definition"].name == "33333333-3333-3333-3333-333333333333"
    error_message = "New assignments must accept an explicitly configured GUID."
  }

  assert {
    condition = alltrue([
      for resource in concat([azapi_resource.this, azapi_resource.lock[0]], values(azapi_resource.role_assignments)) :
      resource.retry.interval_seconds == 5 && resource.timeouts.create == "40m" && resource.timeouts.delete == "50m"
    ])
    error_message = "Retry and flat timeouts must be wired to the primary resource and both interface types."
  }

  assert {
    condition     = azapi_resource.role_assignments["qualified_definition"].replace_triggers_external_values.principal_id == "55555555-5555-5555-5555-555555555555" && azapi_resource.lock[0].replace_triggers_external_values.kind == "CanNotDelete"
    error_message = "Immutable interface inputs must be tracked for replacement."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "custom_lock_details_and_types" {
  command = apply

  variables {
    lock = {
      kind  = "ReadOnly"
      name  = "custom-lock"
      notes = "Custom lock notes"
    }
    resource_types = {
      authorization_locks                    = "Microsoft.Authorization/locks@2016-09-01"
      authorization_role_assignments         = "Microsoft.Authorization/roleAssignments@2020-04-01-preview"
      maintenance_maintenance_configurations = "Microsoft.Maintenance/maintenanceConfigurations@2022-07-01-preview"
    }
    role_assignments = {
      reader = {
        role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
        principal_id               = "22222222-2222-2222-2222-222222222222"
      }
    }
  }

  assert {
    condition     = azapi_resource.lock[0].name == "custom-lock" && azapi_resource.lock[0].body.properties.notes == "Custom lock notes"
    error_message = "Explicit lock details must reach the interface body."
  }

  assert {
    condition     = azapi_resource.this.type == var.resource_types.maintenance_maintenance_configurations && azapi_resource.lock[0].type == var.resource_types.authorization_locks && azapi_resource.role_assignments["reader"].type == var.resource_types.authorization_role_assignments
    error_message = "Every owned resource must use its consumer-configurable API version."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "read_only_lock_preserves_default_notes" {
  command = apply

  variables {
    lock = {
      kind = "ReadOnly"
    }
  }

  assert {
    condition     = azapi_resource.lock[0].body.properties.notes == "Cannot delete or modify the resource or its child resources."
    error_message = "ReadOnly lock notes must match the released module."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "rejects_unknown_role_name" {
  command = plan

  variables {
    role_assignments = {
      invalid = {
        role_definition_id_or_name = "Not an available role"
        principal_id               = "22222222-2222-2222-2222-222222222222"
      }
    }
  }

  expect_failures = [azapi_resource.role_assignments["invalid"]]
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "rejects_invalid_parent_scope" {
  command = plan

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
  }

  expect_failures = [var.parent_id]
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "rejects_invalid_delegated_identity" {
  command = plan

  variables {
    role_assignments = {
      invalid = {
        role_definition_id_or_name             = "Contributor"
        principal_id                           = "22222222-2222-2222-2222-222222222222"
        delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
      }
    }
  }

  expect_failures = [var.role_assignments]
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "enabled_telemetry_uses_the_requested_location" {
  command = apply

  variables {
    enable_telemetry = true
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 1 && azapi_resource.telemetry[0].location == var.location
    error_message = "Enabled managed telemetry must use the consumer's Azure region."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}
