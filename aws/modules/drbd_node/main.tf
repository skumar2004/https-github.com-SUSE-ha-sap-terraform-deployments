# drbd resources
locals {
  bastion_enabled        = var.common_variables["bastion_enabled"]
  provisioning_addresses = local.bastion_enabled ? aws_instance.drbd.*.private_ip : aws_instance.drbd.*.public_ip
  hostname               = var.common_variables["deployment_name_in_hostname"] ? format("%s-%s", var.common_variables["deployment_name"], var.name) : var.name
}

resource "aws_subnet" "drbd-subnet" {
  count             = var.drbd_count
  vpc_id            = var.vpc_id
  cidr_block        = element(var.subnet_address_range, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name      = "${var.common_variables["deployment_name"]}-drbd-subnet-${count.index + 1}"
    Workspace = var.common_variables["deployment_name"]
  }
}

resource "aws_route_table_association" "drbd-subnet-route-association" {
  count          = var.drbd_count
  subnet_id      = element(aws_subnet.drbd-subnet.*.id, count.index)
  route_table_id = var.route_table_id
}

resource "aws_route" "drbd-cluster-vip" {
  count                  = var.drbd_count > 0 ? 1 : 0
  route_table_id         = var.route_table_id
  destination_cidr_block = "${var.common_variables["drbd"]["cluster_vip"]}/32"
  network_interface_id   = aws_instance.drbd.0.primary_network_interface_id
}

module "sap_cluster_policies" {
  enabled           = var.drbd_count > 0 ? true : false
  source            = "../../modules/sap_cluster_policies"
  common_variables  = var.common_variables
  name              = var.name
  aws_region        = var.aws_region
  cluster_instances = aws_instance.drbd.*.id
  route_table_id    = var.route_table_id
}

module "get_os_image" {
  source   = "../../modules/get_os_image"
  os_image = var.os_image
  os_owner = var.os_owner
}

## drbd ec2 instance
resource "aws_instance" "drbd" {
  count                       = var.drbd_count
  ami                         = module.get_os_image.image_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  associate_public_ip_address = local.bastion_enabled ? false : true
  subnet_id                   = element(aws_subnet.drbd-subnet.*.id, count.index)
  private_ip                  = element(var.host_ips, count.index)
  vpc_security_group_ids      = [var.security_group_id]
  availability_zone           = element(var.availability_zones, count.index)
  source_dest_check           = false
  iam_instance_profile        = module.sap_cluster_policies.cluster_profile_name[0]

  root_block_device {
    volume_type = "gp2"
    volume_size = "10"
  }

  ebs_block_device {
    volume_type = var.drbd_data_disk_type
    volume_size = var.drbd_data_disk_size
    device_name = "/dev/sdb"
  }

  volume_tags = {
    Name = "${var.common_variables["deployment_name"]}-${var.name}${format("%02d", count.index + 1)}"
  }

  tags = {
    Name                                                 = "${var.common_variables["deployment_name"]}-${var.name}${format("%02d", count.index + 1)}"
    Workspace                                            = var.common_variables["deployment_name"]
    "${var.common_variables["deployment_name"]}-cluster" = "${var.name}${format("%02d", count.index + 1)}"
  }
}

module "drbd_on_destroy" {
  source              = "../../../generic_modules/on_destroy"
  node_count          = var.drbd_count
  instance_ids        = aws_instance.drbd.*.id
  user                = var.common_variables["authorized_user"]
  private_key         = var.common_variables["private_key"]
  bastion_host        = var.bastion_host
  bastion_private_key = var.common_variables["bastion_private_key"]
  public_ips          = local.provisioning_addresses
  dependencies        = var.on_destroy_dependencies
}
