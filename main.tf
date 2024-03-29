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
  default = "gblow-qserv"   # name of keypair created
}

variable "availability-zone" {
  type    = string
  default = "nova"
}

variable "network" {
  type    = string
  default = "qserv" # default network to be used
}

variable "security_groups" {
  type    = list(string)
  default = ["default"]  # Name of default security group
}

variable "utility_count" {
  type    = number
  default = 2
}

variable "worker_count" {
  type    = number
  default = 10
}

# Data sources
## Get Image ID
data "openstack_images_image_v2" "image" {
  name        = "ubuntu-jammy" # Name of image to be used
  most_recent = true
}

## Get flavor id
data "openstack_compute_flavor_v2" "jump-flavor" {
  name = "qserv-jump-v3" # flavor to be used for jump
}
data "openstack_compute_flavor_v2" "czar-flavor" {
  name = "qserv-czar-v3" # flavor to be used for czar
}
data "openstack_compute_flavor_v2" "utility-flavor" {
  name = "qserv-utility-v3" # flavor to be used for utility nodes
}
data "openstack_compute_flavor_v2" "worker-flavor" {
  name = "qserv-worker-v4" # flavor to be used for worker nodes
}

resource "openstack_networking_floatingip_v2" "jump" {
 pool = "external" 
}

# Create worker volumes

resource "openstack_blockstorage_volume_v3" "czar-vol" {
  name = "czar-vol"
  size = 5000
  volume_type="ceph-ssd"
}

resource "openstack_blockstorage_volume_v3" "utility-vol" {
  name = "utility-vol${(count.index+1)}"
  size = 5000
  volume_type="ceph-ssd"
  count= var.utility_count
}

resource "openstack_blockstorage_volume_v3" "worker-vol" {
  name = "worker-vol${(count.index+1)}"
  size = 10000
  volume_type="ceph-ssd"
  count= var.worker_count
}

# Create jump host
resource "openstack_compute_instance_v2" "jump" {
  name            = "sv-qserv-oct23-jump"  #Instance name
  image_id        = data.openstack_images_image_v2.image.id
  flavor_id       = data.openstack_compute_flavor_v2.jump-flavor.id
  key_pair        = var.keypair
  availability_zone_hints = var.availability-zone
  security_groups = ["qserv-jump-sg","qserv-kube-sg","qserv-mysql"]

  network {
    name = var.network
  }
}
# Create czar
resource "openstack_compute_instance_v2" "czar" {
  name            = "sv-qserv-oct23-czar"  #Instance name
  image_id        = data.openstack_images_image_v2.image.id
  flavor_id       = data.openstack_compute_flavor_v2.czar-flavor.id
  key_pair        = var.keypair
  availability_zone_hints = var.availability-zone
  security_groups = ["qserv-kube-sg"]
  
  network {
    name = var.network
  }
}

resource "openstack_compute_instance_v2" "utility" {
  name            = "sv-qserv-oct23-utility-${(count.index+1)}"
  image_id        = data.openstack_images_image_v2.image.id
  flavor_id       = data.openstack_compute_flavor_v2.utility-flavor.id
  key_pair        = var.keypair
  availability_zone_hints = var.availability-zone
  security_groups = ["qserv-kube-sg"]
  count           = var.utility_count
  
  network {
    name = var.network
  }
}

resource "openstack_compute_instance_v2" "worker" {
  name            = "sv-qserv-oct23-worker-${(count.index+1)}"
  image_id        = data.openstack_images_image_v2.image.id
  flavor_id       = data.openstack_compute_flavor_v2.worker-flavor.id
  key_pair        = var.keypair
  availability_zone_hints = var.availability-zone
  security_groups = ["qserv-kube-sg"]
  count           = var.worker_count

  network {
    name = var.network
  }
}

resource "openstack_compute_volume_attach_v2" "czar_vol_attach" {
  instance_id = openstack_compute_instance_v2.czar.id
  volume_id   = openstack_blockstorage_volume_v3.czar-vol.id
}

resource "openstack_compute_volume_attach_v2" "utility_vol_attach" {
  count       = var.utility_count
  instance_id = openstack_compute_instance_v2.utility[count.index].id
  volume_id   = openstack_blockstorage_volume_v3.utility-vol[count.index].id
  device = "/dev/vdb"
}

resource "openstack_compute_volume_attach_v2" "worker_vol_attach" {
  count       = var.worker_count
  instance_id = openstack_compute_instance_v2.worker[count.index].id
  volume_id   = openstack_blockstorage_volume_v3.worker-vol[count.index].id
  device = "/dev/vdb"
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

resource "local_file" "ansible_hosts" {
  content = templatefile("./ansible_hosts.tftpl",
  {
    jump = openstack_compute_instance_v2.jump.name,
    czar = openstack_compute_instance_v2.czar.name,
    workers = openstack_compute_instance_v2.worker.*.name,
    utility_nodes = openstack_compute_instance_v2.utility.*.name
  })
  filename = "./ansible/ansible_hosts"
}

resource "local_file" "ssh_config" {
  content = templatefile("./ssh_config.tftpl", 
  {
    jump = openstack_compute_instance_v2.jump.name, 
    jump_ip = openstack_networking_floatingip_v2.jump.address, 
    key_name = var.keypair, 
    nodes = concat(openstack_compute_instance_v2.czar.*.name,openstack_compute_instance_v2.worker.*.name,openstack_compute_instance_v2.utility.*.name)
    node_ips = concat(openstack_compute_instance_v2.czar.*.access_ip_v4,openstack_compute_instance_v2.worker.*.access_ip_v4,openstack_compute_instance_v2.utility.*.access_ip_v4)

  })
  filename = "qserv_tf_config"
}
