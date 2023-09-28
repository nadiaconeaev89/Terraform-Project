resource "random_id" "bucket_prefix" {
  byte_length = 14
}

resource "google_storage_bucket" "default" {
  name          = "${random_id.bucket_prefix.hex}-bucket-tfstate"
  force_destroy = true
  location      = "US"
  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
}
output  bucket_name {
    value = google_storage_bucket.default.name
}