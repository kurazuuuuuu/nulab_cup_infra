resource "aws_instance" "ami_maintainer" {
  ami                    = var.base_ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.main.id]
  iam_instance_profile   = aws_iam_instance_profile.main.name

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    if command -v apt-get >/dev/null 2>&1; then
      apt-get update
      DEBIAN_FRONTEND=noninteractive apt-get install -y git-lfs
    fi

    if ! systemctl is-active --quiet amazon-ssm-agent; then
      systemctl enable --now amazon-ssm-agent || \
        systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service || true
    fi
  EOT

  tags = {
    Name = "${var.name_prefix}-instance"
  }
}
