data "aws_ssm_parameter" "ubuntu_2204_ami_id" {
  name = var.ubuntu_ami_ssm_parameter_name
}

resource "aws_instance" "unity_ami_builder" {
  ami                    = data.aws_ssm_parameter.ubuntu_2204_ami_id.value
  instance_type          = "t3.large"
  subnet_id              = aws_subnet.unity_ami_builder.id
  vpc_security_group_ids = [aws_security_group.unity_ami_builder.id]
  iam_instance_profile   = aws_iam_instance_profile.unity_ami_builder.name

  instance_market_options {
    market_type = "spot"

    spot_options {
      max_price = var.spot_max_price
    }
  }

  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      tigervnc-standalone-server \
      xfce4 \
      xfce4-goodies \
      dbus-x11 \
      xterm

    if ! command -v amazon-ssm-agent >/dev/null 2>&1; then
      snap install amazon-ssm-agent --classic || true
    fi

    systemctl enable --now amazon-ssm-agent || \
      systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service || true

    install -d -m 0755 -o ubuntu -g ubuntu /home/ubuntu/.vnc
    cat > /home/ubuntu/.vnc/xstartup << 'XEOF'
    #!/bin/sh
    unset SESSION_MANAGER
    unset DBUS_SESSION_BUS_ADDRESS
    exec startxfce4
    XEOF
    chmod +x /home/ubuntu/.vnc/xstartup
    chown ubuntu:ubuntu /home/ubuntu/.vnc/xstartup
  EOT

  tags = {
    Name = "unity-ami-builder"
  }
}
