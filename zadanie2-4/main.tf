# Использование локального модуля VPC
module "vpc" {
  source = "./modules/vpc"

  network_name   = var.vpc_name
  subnet_name    = "${var.vpc_name}-module-${var.default_zone}"
  zone           = var.default_zone
  v4_cidr_blocks = var.default_cidr
}

# Шаблон для cloud-init marketing
data "template_file" "cloudinit_marketing" {
  template = file("./cloud-init.yml")
  vars = {
    ssh_public_key = var.vms_ssh_root_key
    project_name   = "marketing"
  }
}

# Шаблон для cloud-init analytics
data "template_file" "cloudinit_analytics" {
  template = file("./cloud-init.yml")
  vars = {
    ssh_public_key = var.vms_ssh_root_key
    project_name   = "analytics"
  }
}

# Модуль для ВМ marketing
module "marketing-vm" {
  source         = "git::https://github.com/udjin10/yandex_compute_instance.git?ref=main"
  env_name       = "marketing"
  network_id     = module.vpc.network_id
  subnet_zones   = [var.default_zone]
  subnet_ids     = [module.vpc.subnet_id]
  instance_name  = "marketing-vm"
  instance_count = 1
  image_family   = "ubuntu-2004-lts"
  public_ip      = true

  labels = {
    owner   = "student"
    project = "marketing"
  }

  metadata = {
    user-data          = data.template_file.cloudinit_marketing.rendered
    serial-port-enable = 1
  }
}

# Модуль для ВМ analytics
module "analytics-vm" {
  source         = "git::https://github.com/udjin10/yandex_compute_instance.git?ref=main"
  env_name       = "analytics"
  network_id     = module.vpc.network_id
  subnet_zones   = [var.default_zone]
  subnet_ids     = [module.vpc.subnet_id]
  instance_name  = "analytics-vm"
  instance_count = 1
  image_family   = "ubuntu-2004-lts"
  public_ip      = true

  labels = {
    owner   = "student"
    project = "analytics"
  }

  metadata = {
    user-data          = data.template_file.cloudinit_analytics.rendered
    serial-port-enable = 1
  }
}
