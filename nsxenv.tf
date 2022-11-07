terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
    }
  }
}

provider "nsxt" {
  version               = "~> 3.2"
  host                  = "nsxmgr-01a"
  username              = "admin"
  password              = "VMware1!VMware1!"
  allow_unverified_ssl  = true
  max_retries           = 10
  retry_min_delay       = 500
  retry_max_delay       = 5000
  retry_on_status_codes = [429]
}

resource "nsxt_policy_group" "prod_group" {
  display_name = "Prod_VMs"
  description  = "Group consisting of Prod VMs"
  criteria {
    condition {
      member_type = "VirtualMachine"
      operator    = "CONTAINS"
      key         = "Tag"
      value       = "prod"
    }
  }
}

resource "nsxt_policy_group" "dev_group" {
  display_name = "Dev_VMs"
  description  = "Group consisting of Dev VMs"
  criteria {
    condition {
      member_type = "VirtualMachine"
      operator    = "CONTAINS"
      key         = "Tag"
      value       = "dev"
    }
  }
}

resource "nsxt_policy_group" "LowSec_ip" {
  description  = "Group containing Infrastructure IPs"
  display_name = "LowSecIPSet"
  criteria {
    ipaddress_expression {
      ip_addresses = ["192.168.110.0/24"]
    }
  }
}

resource "nsxt_policy_group" "HighSec_ip" {
  description  = "Group containing Infrastructure IPs"
  display_name = "HighSecIPSet"
  criteria {
    ipaddress_expression {
      ip_addresses = ["172.16.120.0/24"]
    }
  }
}

resource "nsxt_policy_security_policy" "firewall_section" {
  display_name = "Enviromental Seg"
  description  = "Restrict traffic between Prod and Dev"
  category     = "Environment"
  locked       = "false"
  stateful     = "true"

  rule {
    display_name          = "Prod to Dev"
    description           = "Segment Prod to Dev"
    action                = "DROP"
    logged                = true
    ip_version            = "IPV4"
    source_groups         = [nsxt_policy_group.prod_group.path]
    destination_groups    = [nsxt_policy_group.dev_group.path]
    scope                 = [nsxt_policy_group.prod_group.path, nsxt_policy_group.dev_group.path] 
  }

  rule {
    display_name          = "Dev to Prod"
    description           = "Segment Dev to Prod"
    action                = "DROP"
    logged                = true
    ip_version            = "IPV4"
    destination_groups    = [nsxt_policy_group.prod_group.path]
    source_groups         = [nsxt_policy_group.dev_group.path]
    scope                 = [nsxt_policy_group.prod_group.path, nsxt_policy_group.dev_group.path]
  }

    rule {
    display_name          = "Low to High"
    description           = "Segment Internal Network"
    action                = "DROP"
    logged                = true
    ip_version            = "IPV4"
    destination_groups    = [nsxt_policy_group.HighSec_ip.path]
    source_groups         = [nsxt_policy_group.LowSec_ip.path]
  }
}