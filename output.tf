
output "alb_2" {
  value = aws_lb.apache_LB_2.dns_name
}

output "demo_instance_1_public_ip" {
  value = aws_instance.demo_instance-1.public_ip
}