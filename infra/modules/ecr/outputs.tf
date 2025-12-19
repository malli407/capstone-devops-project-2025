output "repository_urls" {
  description = "Map of repository names to URLs"
  value = {
    for repo in var.repositories :
    repo => aws_ecr_repository.this[repo].repository_url
  }
}

output "repository_arns" {
  description = "Map of repository names to ARNs"
  value = {
    for repo in var.repositories :
    repo => aws_ecr_repository.this[repo].arn
  }
}

output "repository_registry_ids" {
  description = "Map of repository names to registry IDs"
  value = {
    for repo in var.repositories :
    repo => aws_ecr_repository.this[repo].registry_id
  }
}

