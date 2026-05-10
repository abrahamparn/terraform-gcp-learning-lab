output "email" {
  description = "The service account email."
  value       = google_service_account.this.email
}

output "name" {
  description = "the fully qualified service account name"
  value       = google_service_account.this.name
}

output "member" {
  description = "The iam member for this service account."
  value       = "serviceAccount:${google_service_account.this.email}"
}

