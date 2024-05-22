resource "google_compute_instance" "tf-instance-1" {
    name         = "tf-instance-1"
    machine_type = "e2-micro"
    boot_disk       {
        initialize_params {
            image = "debian-11"
        }
    }
    network_interface {
        network = "default"
        access_config {
        }
    } 
    allow_stopping_for_update = true
}

resource "google_compute_instance" "tf-instance-2"{
    name         = "tf-instance-2"
    machine_type = "e2-micro"
    boot_disk       {
        initialize_params {
            image = "debian-11"
        }
    }
    network_interface {
        network = "default"
        access_config {
        }
    } 
    allow_stopping_for_update = true
}
