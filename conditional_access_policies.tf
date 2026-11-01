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

    ca006_phishing_resistant_admins = {
      display_name = "CA006 - Require Phishing-Resistant MFA for Administrators"
      included_roles = [
        "62e90394-69f5-4237-9190-012177145e10", # Global Administrator
        "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3", # Application Administrator
        "c4e39bd9-1100-46d3-8c65-fb160da0071f", # Authentication Administrator
        "b0f54661-2d74-4c50-afa3-1ec803f12efe", # Billing Administrator
        "158c047a-c907-4556-b7ef-446551a6b5f7", # Cloud Application Administrator
        "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9", # Conditional Access Administrator
        "29232cdf-9323-42fd-ade2-1d097af3e4de", # Exchange Administrator
        "729827e3-9c14-49f7-bb1b-9608f156bbb8", # Helpdesk Administrator
        "966707d0-3269-4727-9be2-8c3a10f19b9d", # Password Administrator
        "7be44c8a-adaf-4e2a-84d6-ab2649e08a13", # Privileged Authentication Administrator
        "e8611ab8-c189-46e8-94e1-60213ab1f814", # Privileged Role Administrator
        "194ae4cb-b126-40b2-bd5b-6091b380977d", # Security Administrator
        "f28a1f50-f6e7-4571-818b-6a12f2af6b6c", # SharePoint Administrator
        "fe930be7-5e62-47db-91af-98c3a49a38b1", # User Administrator
      ]
      grant = {
        # Built-in Phishing-resistant MFA strength
        authentication_strength_policy_id = "/policies/authenticationStrengthPolicies/00000000-0000-0000-0000-000000000004"
      }
      state = "enabled"
    }
  }
}