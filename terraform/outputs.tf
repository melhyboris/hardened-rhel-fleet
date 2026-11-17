output "ami" {
  description = "Image the fleet was built from."
  value       = "${data.aws_ami.os.name} (${data.aws_ami.os.id})"
}

output "servers" {
  description = "Server names and public addresses."
  value       = { for i in aws_instance.fleet : i.tags.Name => i.public_ip }
}
