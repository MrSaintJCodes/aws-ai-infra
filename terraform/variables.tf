variable "my_ip" {
  description = "Your local public IP for SSH access"
  type        = string
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
}

variable "db_password" {
  description = "RDS PostgreSQL master password"
  type        = string
  sensitive   = true
}

variable "ollama_host" {
  description = "Host for Ollama server"
  type        = string
  default     = "0.0.0.0"
}

variable "ollama_port" {
  description = "Port for Ollama server"
  type        = string
  default     = "11434"
}

variable "ollama_model" {
  description = "Ollama model to deploy (e.g. 'llama3b')"
  type        = string
  default     = "llama3.2"
}

variable "web_git_repo" {
  description = "Git repository URL for the web app"
  type        = string
  default     = "https://github.com/MrSaintJCodes/ai-chat.git"
}

variable "web_django_secret_key" {
  description = "Django secret key for the web app"
  type        = string
  sensitive   = true
  default     = "replace-with-a-secure-random-key"
}