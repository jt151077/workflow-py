module "cf-randomgen" {
  depends_on = [
    google_project_service.gcp_services
  ]

  source     = "./randomgen"
  project_id = local.project_id
  region     = local.project_default_region
}
