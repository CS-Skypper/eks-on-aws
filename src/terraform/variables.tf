variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = [{
    userarn = "arn:aws:iam::467913957333:user/auditor-1",
    username = "auditor-1", # kubernetes user
    groups = ["audit-team"]
  }]
}
