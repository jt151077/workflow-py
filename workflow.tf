/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


resource "google_workflows_workflow" "calc-workflow" {
  depends_on = [
    google_project_service.gcp_services
  ]

  project         = local.project_id
  name            = "calc-workflow"
  region          = local.project_default_region
  service_account = google_service_account.workflows_sa.id


  source_contents = <<-EOF
    - randomgen_function:
        call: http.get
        args:
            url: ${module.cf-randomgen.function_uri}
            auth:
              type: OIDC
        result: randomgen_result
    - multiply_function:
        call: http.post
        args:
            url: https://multiplyrun-nc36gpwfva-ew.a.run.app
            auth:
              type: OIDC
            body:
                input: $${randomgen_result.body.random}
        result: floor_result
    - return_result:
        return: $${floor_result}
EOF
}