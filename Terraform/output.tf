output "master_public_ip" {
  value = aws_instance.master.public_ip
}

output "worker_1_public_ip" {
  value = aws_instance.worker-1.public_ip
}

output "worker_2_public_ip" {
  value = aws_instance.worker-2.public_ip
}
