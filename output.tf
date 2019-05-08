output "ip-adress" {
  value = "${aws_instance.web.public_ip}"
}