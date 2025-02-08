resource "google_compute_network" "vpc_network" {
  name                    = "project-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "project_subnet" {
  name          = "project-subnet"
  ip_cidr_range = var.ip_cidr_range
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

# Firewall fule for k8s-cluster
resource "google_compute_firewall" "k8s_firewall" {
  name    = "k8s-firewall"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "6443", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "k8s_controller" {
  count        = 1
  name         = "controller-${count.index}"
  machine_type = "e2-small"
  zone         = var.zone

  boot_disk {
    initialize_params {
    image      = "debian-cloud/debian-12-bookworm-v20250113"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.project_subnet.name
    access_config {
    }
  }

  metadata = {
    ssh-keys = var.ssh_creds
  }
}

resource "google_compute_instance" "k8s_workers" {
  count        = 3
  name         = "worker-${count.index}"
  machine_type = "e2-small"
  zone         = var.zone

  boot_disk {
    initialize_params {
    image      = "debian-cloud/debian-12-bookworm-v20250113"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.project_subnet.name
    access_config {
    }
  }

  metadata = {
    ssh-keys = var.ssh_creds
  }
}
resource "local_file" "ansible_inventory" {
  filename = "./kubespray/inventory/mycluster/inventory.ini"
  content = <<-EOT
    [all:vars]
    ansible_become=true

    [kube_control_plane]
    %{ for i, instance in google_compute_instance.k8s_controller ~}
    node${i+1} ansible_host=${instance.network_interface[0].access_config[0].nat_ip} ip=${instance.network_interface[0].network_ip} etcd_member_name=etcd${i+1}
    %{ endfor ~}

    [etcd:children]
    kube_control_plane

    [kube_node]
    %{ for i, instance in google_compute_instance.k8s_workers ~}
    node${i+4} ansible_host=${instance.network_interface[0].access_config[0].nat_ip} ip=${instance.network_interface[0].network_ip}
    %{ endfor ~}
  EOT
}


data "local_file" "current_k8s_cluster_yml" {
  filename = "./kubespray/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml"
}
resource "local_file" "update_ssl_keys" {
  filename = "./kubespray/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml"
  content = <<-EOT
    ${data.local_file.current_k8s_cluster_yml.content}
    
    supplementary_addresses_in_ssl_keys: [${join(", ", flatten([
      google_compute_instance.k8s_controller[*].network_interface[0].network_ip,
      google_compute_instance.k8s_workers[*].network_interface[0].network_ip
    ]))}]
  EOT
  depends_on = [local_file.ansible_inventory]
}