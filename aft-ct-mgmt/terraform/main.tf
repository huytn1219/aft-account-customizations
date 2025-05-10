resource "aws_controltower_landing_zone" "main" {
  manifest_json = file("${path.module}/LandingZoneManifest.json")
  version       = "3.3"
}

# Trigger OU re-registration process to update accounts
resource "null_resource" "run_script" {
  provisioner "local-exec" {
    command  = file("${path.module}/re-register-ous.sh")
  }
  depends_on = [aws_controltower_landing_zone.main]
}

import {
  to = aws_controltower_landing_zone.main
  id = data.aws_ssm_parameter.landing_zone_id.value
}
