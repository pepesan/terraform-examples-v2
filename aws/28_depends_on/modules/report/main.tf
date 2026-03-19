variable "report_name" {
  type = string
}

resource "terraform_data" "this" {
  input = {
    name = var.report_name
  }
}

output "report_output" {
  value = terraform_data.this.output
}