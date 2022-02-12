# CDN backend bucket
resource "google_storage_bucket" "poc" {
  name                        = var.bucket_name
  location                    = var.bucket_location
  uniform_bucket_level_access = true
  // delete bucket and contents on destroy.
  force_destroy = true
  // Assign specialty files
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

# Make bucket public
resource "google_storage_bucket_iam_member" "poc" {
  bucket = google_storage_bucket.poc.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_storage_bucket_object" "index_html" {
  name   = "index.html"
  source = "./website/index.html"
  bucket = google_storage_bucket.poc.name
}

resource "google_storage_bucket_object" "four_zero_four_html" {
  name   = "404.html"
  source = "./website/404.html"
  bucket = google_storage_bucket.poc.name
}

resource "google_storage_bucket_object" "design_svg" {
  name         = "content/design.svg"
  source       = "./website/content/design_cdn.svg"
  content_type = "image/svg+xml"
  bucket       = google_storage_bucket.poc.name
}

resource "google_storage_bucket_object" "style_css" {
  name         = "css/style.css"
  source       = "./website/css/style.css"
  content_type = "text/css"
  bucket       = google_storage_bucket.poc.name
}
