# The one input that is not in Git: proxmox.auto.tfvars, ignored, holds it as
#   proxmox_api_token = "root@pam!terraform=<secret>"
# Everything else is in locals.tf.
variable "proxmox_api_token" {
  description = "Proxmox API token, as <user>!<token id>=<secret>."
  type        = string
  sensitive   = true
}
