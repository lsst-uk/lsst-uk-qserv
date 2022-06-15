# Configure the OpenStack Provider
terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

provider "openstack" {
  cloud  = "openstack" # cloud defined in cloud.yml file
  max_retries = 5
}

# Variables
variable "keypair" {
  type    = string
  default = "gb_somerville_test_key"   # name of keypair created
}

variable "network" {
  type    = string
  default = "qserv" # default network to be used
}

variable "security_groups" {
  type    = list(string)
  default = ["default"]  # Name of default security group
}

# Data sources
## Get Image ID
data "openstack_images_image_v2" "image" {
  name        = "ubuntu-focal" # Name of image to be used
  most_recent = true
}

## Get flavor id
data "openstack_compute_flavor_v2" "jump-flavor" {
  name = "qserv-jump" # flavor to be used for jump
}
data "openstack_compute_flavor_v2" "czar-flavor" {
  name = "qserv-jump" # flavor to be used for czar
}
data "openstack_compute_flavor_v2" "utility-flavor" {
  name = "qserv-jump" # flavor to be used for utility nodes
}
data "openstack_compute_flavor_v2" "worker-flavor" {
  name = "qserv-jump" # flavor to be used for worker nodes
}

resource "openstack_networking_floatingip_v2" "jump" {
 pool = "external" 
}

# Create jump host
resource "openstack_compute_instance_v2" "jump" {
  name            = "GB-QServ2-Jump"  #Instance name
  image_id        = data.openstack_images_image_v2.image.id
  flavor_id       = data.openstack_compute_flavor_v2.jump-flavor.id
  key_pair        = var.keypair
  security_groups = var.security_groups

  network {
    name = var.network
  }
}
# Create czar
resource "openstack_compute_instance_v2" "czar" {
  name            = "GB-QServ2-Czar"  #Instance name
  image_id        = data.openstack_images_image_v2.image.id
  flavor_id       = data.openstack_compute_flavor_v2.czar-flavor.id
  key_pair        = var.keypair
  security_groups = var.security_groups
  
  network {
    name = var.network
  }
}

resource "openstack_compute_instance_v2" "utility" {
  name            = "GB-QServ2-Utility ${(count.index+1)}"
  image_id        = data.openstack_images_image_v2.image.id
  flavor_id       = data.openstack_compute_flavor_v2.utility-flavor.id
  key_pair        = var.keypair
  security_groups = var.security_groups
  count           = 2
  
  network {
    name = var.network
  }
}

resource "openstack_compute_instance_v2" "worker" {
  name            = "GB-QServ2-Worker ${(count.index+1)}"
  image_id        = data.openstack_images_image_v2.image.id
  flavor_id       = data.openstack_compute_flavor_v2.worker-flavor.id
  key_pair        = var.keypair
  security_groups = var.security_groups
  count           = 2

  network {
    name = var.network
  }
}

resource "openstack_compute_floatingip_associate_v2" "jump" {
floating_ip = openstack_networking_floatingip_v2.jump.address
instance_id = openstack_compute_instance_v2.jump.id
}

# Output VM IP Address
output "czarserverip" {
 value = openstack_compute_instance_v2.czar.access_ip_v4
}
# Output Jump host IP Address
output "jumpserverip" {
 value = openstack_compute_instance_v2.jump.access_ip_v4
}
# Output Jump host floating IP Address
output "jumpserverfloatingip" {
 value = openstack_networking_floatingip_v2.jump.address
}

resource "local_file" "ssh_config" {
  content = templatefile("./ssh_config.tftpl", {jump = openstack_compute_instance_v2.jump.name, jump_ip = openstack_networking_floatingip_v2.jump.address, key_name = "keypair", czar = openstack_compute_instance_v2.czar.name, czar_ip = openstack_compute_instance_v2.czar.access_ip_v4})
  filename = "qserv_tf_config"
}


// sshconfig = templatefile("./ssh_config.tftpl", {jump = openstack_compute_instance_v2.jump.name, jump_ip = openstack_networking_floatingip_v2.jump.address, key_name = "keypair", czar = openstack_compute_instance_v2.czar.name, czar_ip = openstack_compute_instance_v2.czar.access_ip_v4})

// data "template_file" "ssh_config" {
//   template = file("ssh_config.tftpl")
//   vars = {
//     jump = openstack_compute_instance_v2.jump.name
//     jump_ip = openstack_networking_floatingip_v2.jump.address
//     key_name = "keypair"
//     czar = openstack_compute_instance_v2.czar.name
//     czar_ip = openstack_compute_instance_v2.czar.access_ip_v4
    
//     nodes = openstack_compute_instance_v2.utility.*.name
//   }
// }

// resource "local_file" "ssh_config" {
//   content = data.template_file.ssh_config.rendered
//   filename = "qserv_tf_config"
// }
