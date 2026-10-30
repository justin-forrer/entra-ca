locals {
  policies = {
    ca001_block_legacy_auth = {
      display_name     = "CA001 - Block Legacy Authentication"
      client_app_types = ["exchangeActiveSync", "other"]
      included_users   = ["All"]
      grant = {
        built_in_controls = ["block"]
      }
    }
  }
}