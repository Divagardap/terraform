resource "null_resource" "execute_script" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "bash calc.sh > output.txt"
  }
}

data "local_file" "script_output" {
  depends_on = [null_resource.execute_script]

  filename = "./output.txt"
}

output "cidr_output" {
  value = data.local_file.script_output.content
}

