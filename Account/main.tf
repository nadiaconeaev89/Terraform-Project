data "google_billing_account" "acct" {
	display_name = "My Billing Account"
	open = true
}

resource "random_password" "password" {
	length = 14
	numeric = false
	special = false
	lower = true
	upper = false
}

resource "google_project" "terraformproject" {
	name = "terraformproject"
	project_id = random_password.password.result
	billing_account = data.google_billing_account.acct.id
}

resource "null_resource" "set-project" {
	 triggers = {
    always_run = "${timestamp()}"
  }
	
	provisioner "local-exec" {
	command = "gcloud config set project ${google_project.terraformproject.project_id}"
	}
}

resource "null_resource" "unset-project" {
	provisioner "local-exec" {
	when = destroy
	command = "gcloud config unset project"
	}
}




resource "null_resource" "enable-apis" {
  depends_on = [
    google_project.terraformproject,
    null_resource.set-project
  ]
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<-EOT
        gcloud services enable compute.googleapis.com
        gcloud services enable dns.googleapis.com
        gcloud services enable storage-api.googleapis.com
        gcloud services enable container.googleapis.com
        gcloud services enable file.googleapis.com
        gcloud services enable cloudbilling.googleapis.com
    EOT
  }
}
