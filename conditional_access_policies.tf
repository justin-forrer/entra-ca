locals {
  policies = {
    ca001_block_legacy_auth = {
      display_name     = "CA001 - Block Legacy Authentication"
      client_app_types = ["exchangeActiveSync", "other"]
      included_users   = ["All"]
      grant = {
        built_in_controls = ["block"]
      }
      state = "enabled"
    }

    ca002_mfa_admins = {
      display_name = "CA002 - Require MFA for Administrators"
      included_roles = [
        "62e90394-69f5-4237-9190-012177145e10", # Global Administrator
        "e8611ab8-c189-46e8-94e1-60213ab1f814", #Privileged Role Administrator
        "194ae4cb-b126-40b2-bd5b-6091b380977d", #Security Administrator
        "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9", #Conditional Access Administrator      
      ]
      grant = {
        built_in_controls = ["mfa"]
      }
      state = "enabled"
    }

    ca003_mfa_all_users = {
      display_name   = "CA003 - Require MFA for All Users"
      included_users = ["All"]
      grant = {
        built_in_controls = ["mfa"]
      }
      state = "enabled"
    }

    ca004_block_device_code_flow = {
      display_name                         = "CA004 - Block Device Code Flow"
      included_users                       = ["All"]
      authentication_flow_transfer_methods = ["deviceCodeFlow"]
      grant = {
        built_in_controls = ["block"]
      }
      state = "enabled"
    }

    ca005_mfa_risky_signins = {
      display_name        = "CA005 - Require MFA for Risky Sign-Ins"
      included_users      = ["All"]
      sign_in_risk_levels = ["high", "medium"]
      grant = {
        built_in_controls = ["mfa"]
      }
      session = {
        sign_in_frequency_interval            = "everyTime"
        sign_in_frequency_authentication_type = "primaryAndSecondaryAuthentication"
      }
      state = "enabled"
    }
  }
}