# Import self-signed certificate into ACM
resource "aws_acm_certificate" "lab" {
  private_key       = file("${path.root}/data/certs/lab.key")
  certificate_body  = file("${path.root}/data/certs/lab.crt")
  certificate_chain = file("${path.root}/data/certs/lab-chain.crt")

  lifecycle {
    create_before_destroy = true
  }

  tags = { 
    Name        = "lab-self-signed-cert-${terraform.workspace}" 
    Environment = terraform.workspace
  }
}
