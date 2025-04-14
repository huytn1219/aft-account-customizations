resource "aws_controltower_landing_zone" "main" {
  manifest_json = file("${path.cwd}/LandingZoneManifest.json")
  version       = "3.3"
}

import {
  to = aws_controltower_landing_zone.main
  id = data.aws_ssm_parameter.landing_zone_id.value
}
