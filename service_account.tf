resource "google_service_account" "service_account" {
  account_id   = var.service_account.name
  project      = var.project
  display_name = var.service_account.description
}

resource "google_project_iam_member" "memberships" {
  count   = length(local.all_roles)
  project = var.project
  role    = local.all_roles[count.index]
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

locals {
  service_account = merge(var.service_account, {
    "email"            = google_service_account.service_account.email
    "additional_roles" = local.all_roles
  })
}
