resource "null_resource" "monitoring_provisioner" {
  count = var.common_variables["provisioner"] == "salt" && var.monitoring_enabled ? 1 : 0

  triggers = {
    monitoring_id = aws_instance.monitoring.0.id
  }

  connection {
    host        = element(local.provisioning_addresses, count.index)
    type        = "ssh"
    user        = var.common_variables["authorized_user"]
    private_key = var.common_variables["private_key"]

    bastion_host        = var.bastion_host
    bastion_user        = var.common_variables["authorized_user"]
    bastion_private_key = var.common_variables["bastion_private_key"]
  }

  provisioner "file" {
    content = <<EOF
role: monitoring_srv
${var.common_variables["grains_output"]}
${var.common_variables["monitoring_grains_output"]}
region: ${var.aws_region}
name_prefix: ${local.hostname}
hostname: ${local.hostname}
network_domain: ${var.network_domain}
timezone: ${var.timezone}
host_ip: ${var.monitoring_srv_ip}
public_ip: ${element(local.provisioning_addresses, count.index)}
EOF

    destination = "/tmp/grains"
  }
}

module "monitoring_provision" {
  source              = "../../../generic_modules/salt_provisioner"
  node_count          = var.common_variables["provisioner"] == "salt" && var.monitoring_enabled ? 1 : 0
  instance_ids        = null_resource.monitoring_provisioner.*.id
  user                = var.common_variables["authorized_user"]
  private_key         = var.common_variables["private_key"]
  public_ips          = local.provisioning_addresses
  bastion_host        = var.bastion_host
  bastion_private_key = var.common_variables["bastion_private_key"]
  background          = var.common_variables["background"]
}
