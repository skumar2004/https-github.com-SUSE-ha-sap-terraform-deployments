resource "null_resource" "hana_node_provisioner" {
  count = var.common_variables["provisioner"] == "salt" ? var.hana_count : 0

  triggers = {
    cluster_instance_ids = join(",", aws_instance.hana.*.id)
  }

  connection {
    host        = element(local.provisioning_addresses, count.index)
    type        = "ssh"
    user        = "ec2-user"
    private_key = var.common_variables["private_key"]

    bastion_host        = var.bastion_host
    bastion_user        = var.common_variables["authorized_user"]
    bastion_private_key = var.common_variables["bastion_private_key"]
  }

  provisioner "file" {
    source      = var.aws_access_key_id == "" || var.aws_secret_access_key == "" ? var.aws_credentials : "/dev/null"
    destination = "/tmp/credentials"
  }

  provisioner "file" {
    content     = <<EOF
role: hana_node
${var.common_variables["grains_output"]}
${var.common_variables["hana_grains_output"]}
region: ${var.aws_region}
aws_cluster_profile: Cluster
aws_instance_tag: ${var.common_variables["deployment_name"]}-cluster
aws_credentials_file: /tmp/credentials
aws_access_key_id: ${var.aws_access_key_id}
aws_secret_access_key: ${var.aws_secret_access_key}
route_table: ${var.route_table_id}
name_prefix: ${local.hostname}
hostname: ${local.hostname}${format("%02d", count.index + 1)}
network_domain: ${var.network_domain}
host_ips: [${join(", ", formatlist("'%s'", var.host_ips))}]
sbd_lun_index: 0
iscsi_srv_ip: ${var.iscsi_srv_ip}
cluster_ssh_pub:  ${var.cluster_ssh_pub}
cluster_ssh_key: ${var.cluster_ssh_key}
node_count: ${var.hana_count + local.create_scale_out}
hana_data_disks_configuration: {${join(", ", formatlist("'%s': '%s'", keys(var.hana_data_disks_configuration), values(var.hana_data_disks_configuration), ), formatlist("'%s': '%s'", "devices", replace(join(",", aws_instance.hana[count.index].ebs_block_device.*.volume_id), "-", "")), )}}
efs_mount_ip:
  ${local.shared_storage_efs == 1 && !contains(split("#", lookup(var.hana_data_disks_configuration, "names", "")), "shared") ? "shared: [ ${join(", ", aws_efs_file_system.scale-out-efs-shared.*.dns_name)} ]" : ""}
majority_maker_node: ${local.create_scale_out == 1 ? "${local.hostname}mm" : ""}
majority_maker_ip: ${local.create_scale_out == 1 ? var.majority_maker_ip : ""}
EOF
    destination = "/tmp/grains"
  }
}

module "hana_provision" {
  source              = "../../../generic_modules/salt_provisioner"
  node_count          = var.common_variables["provisioner"] == "salt" ? var.hana_count : 0
  instance_ids        = null_resource.hana_node_provisioner.*.id
  user                = var.common_variables["authorized_user"]
  private_key         = var.common_variables["private_key"]
  public_ips          = local.provisioning_addresses
  bastion_host        = var.bastion_host
  bastion_private_key = var.common_variables["bastion_private_key"]
  background          = var.common_variables["background"]
}
