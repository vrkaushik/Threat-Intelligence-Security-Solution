variable "project_id" {
  description = "Google Cloud Project ID"
  default = "stuxnet-staging"
}

variable "region" {
  description = "GCP region for resources"
  default     = "us-east1"
}

variable "zone" {
  description = "GCP zone for instances"
  default     = "us-east1-b"
}

# variable "initial_username" {
#   description = "First user at the time of creation"
# }


variable "private_key" {
  description = "The path of private key for the new user being created"
  type = string
  default = "~/.ssh/id_ed25519"
}

variable "public_key" {
  description = "The path of private key for the new user being created"
  type = string
  default = "~/.ssh/id_ed25519.pub"
}

variable "users_file" {
  description = "File path of the list of users and their corresponding public keys"
  default     = "users.txt"
}

variable "deps_script_path" {
  type = string
  default = "deps.sh"
}

variable "usergen_script_path" {
  type = string
  default = "usergen.sh"
}

variable "opencti_docker_compose_path" {
  type = string
  default = "opencti/docker-compose.yml"
}


variable "opencti_nginx_conf_path"  {
  type = string
  default = "opencti/nginx/conf.d/default.yml"
}