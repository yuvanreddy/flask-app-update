variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the node group"
  type        = list(string)
}

variable "instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 20
}

variable "desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "enable_cluster_autoscaler" {
  description = "Enable cluster autoscaler tags"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}