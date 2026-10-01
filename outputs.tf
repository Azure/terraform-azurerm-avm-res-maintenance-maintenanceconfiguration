output "name" {
  description = "The name of the Maintenance Configuration resource."
  value       = azapi_resource.this.name
}

output "resource_id" {
  description = "The ID of the Maintenance Configuration resource."
  value       = azapi_resource.this.id
}
