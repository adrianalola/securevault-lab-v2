output "public_network_id" {
  value = docker_network.public.id
}

output "dmz_network_id" {
  value = docker_network.dmz.id
}

output "private_network_id" {
  value = docker_network.private.id
}
