resource "google_compute_network" "vpc1" {
  name                    = var.network
  project                 = var.project
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public_subnet" {
  name          = "${var.network}-public-subnet"
  ip_cidr_range = "10.8.1.0/24"
  network       = var.network
  region        = var.region
  depends_on    = [google_compute_network.vpc1]
}

resource "google_compute_subnetwork" "private_subnet" {
  name          = "${var.network}-private-subnet"
  ip_cidr_range = "10.8.2.0/24"
  network       = var.network
  region        = var.region
  depends_on    = [google_compute_network.vpc1]
}

resource "google_compute_firewall" "firewall" {
  name    = "${var.network}-ssh"
  network = var.network
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"] # Not So Secure. Limit the Source Range
  target_tags   = ["externalssh"]
  depends_on    = [google_compute_network.vpc1]
}

resource "google_compute_firewall" "nat-internal" {
  name    = "${var.network}-nat-internal"
  network = var.network
  allow {
    protocol = "all"
    #ports    = ["1-65535"]
  }
  source_ranges = [google_compute_subnetwork.private_subnet.ip_cidr_range]
  target_tags   = ["natinternal"]
  depends_on    = [google_compute_network.vpc1]
}

resource "google_compute_firewall" "webserverrule" {
  name    = "${var.network}-http"
  network = var.network
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"] # Not So Secure. Limit the Source Range
  target_tags   = ["webserver"]
  depends_on    = [google_compute_network.vpc1]
}

# We create a public IP address for our google compute instance to utilize
resource "google_compute_address" "static" {
  name       = "${var.network}-public-address"
  project    = var.project
  region     = var.region
  depends_on = [google_compute_firewall.firewall]
}

resource "google_compute_route" "default" {
  name        = "${var.network}-nat-route"
  dest_range  = "0.0.0.0/0"
  network     = var.network
  next_hop_instance = google_compute_instance.gw.name
  next_hop_instance_zone = "${var.region}-b"
  priority    = 800
  tags = ["no-ip"]
}

# # create a nat to allow private instances connect to internet
# resource "google_compute_router" "nat-router" {
#   name       = "${var.network}-nat-router"
#   network    = var.network
#   depends_on = [google_compute_network.vpc1]
# }
# resource "google_compute_router_nat" "nat-gateway" {
#   name   = "${var.network}-nat-gateway"
#   router = google_compute_router.nat-router.name

#   nat_ip_allocate_option             = "AUTO_ONLY"
#   source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
#   depends_on                         = [google_compute_router.nat-router, google_compute_address.static]
# }
