resource "aws_controltower_landing_zone" "main" {
  manifest_json = file("./LandingZoneManifest.json")
  version       = "3.3"
}

import {
  to = aws_controltower_landing_zone.main
  id = "${var.environment.LANDING_ZONE_ID}"
}