resource "random_id" "unique-id" {
  byte_length = 4
}

locals {
  unique_hash             = substr(random_id.unique-id.hex, 0, 8)
  randomgen_function_name = "${local.unique_hash}_randomgen.zip"
  randomgen_function_path = "${path.module}/${local.randomgen_function_name}"
}

data "archive_file" "randomgen_bundle" {
  type        = "zip"
  output_path = local.randomgen_function_path

  source {
    content  = file("${path.module}/main.py")
    filename = "main.py"
  }

  source {
    content  = file("${path.module}/requirements.txt")
    filename = "requirements.txt"
  }
}

resource "google_storage_bucket" "randomgen_function_bucket" {
  project  = var.project_id
  name     = "randomgen_function_bucket"
  location = var.region
}

resource "google_storage_bucket_object" "randomgen_archive" {
  name       = "${data.archive_file.randomgen_bundle.output_sha}.zip"
  bucket     = google_storage_bucket.randomgen_function_bucket.name
  source     = local.randomgen_function_path
  depends_on = [data.archive_file.randomgen_bundle]
}


resource "google_cloudfunctions2_function" "randomgen_function" {
  project  = var.project_id
  name     = "randomgen"
  location = var.region

  build_config {
    runtime     = "python310"
    entry_point = "randomgen"
    source {
      storage_source {
        bucket = google_storage_bucket.randomgen_function_bucket.name
        object = google_storage_bucket_object.randomgen_archive.name
      }

    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
    ingress_settings   = "ALLOW_ALL"
  }
}

output "function_uri" {
  value = google_cloudfunctions2_function.randomgen_function.service_config[0].uri
}