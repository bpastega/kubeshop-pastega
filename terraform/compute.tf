data "azurerm_client_config" "current" {}

resource "azurerm_public_ip" "app" {
  name                = "pip-app-${local.prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  # FQDN gratuito: <label>.chilecentral.cloudapp.azure.com
  domain_name_label = "${local.prefix}-${substr(sha1(data.azurerm_client_config.current.subscription_id), 0, 6)}"
  tags              = local.tags
}

resource "azurerm_network_interface" "app" {
  name                = "nic-app-${local.prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.app_ip
    public_ip_address_id          = azurerm_public_ip.app.id
  }
  tags = local.tags
}

resource "azurerm_network_interface" "db" {
  name                = "nic-db-${local.prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = azurerm_subnet.db.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.db_ip # sem public_ip_address_id
  }
  tags = local.tags
}

locals {
  vms = {
    app = { size = var.app_vm_size, nic = azurerm_network_interface.app.id }
    db  = { size = var.db_vm_size, nic = azurerm_network_interface.db.id }
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each                        = local.vms
  name                            = "vm-${each.key}-${local.prefix}"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = each.value.size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [each.value.nic]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 30
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
  tags = merge(local.tags, { funcao = each.key })
  # sem lifecycle create_before_destroy: a cota de 4 vCPUs não comporta uma VM extra
}

# disco de dados do MongoDB: separado do disco do SO
resource "azurerm_managed_disk" "mongo" {
  name                 = "disk-mongo-${local.prefix}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.db_disk_size_gb
  tags                 = local.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "mongo" {
  managed_disk_id    = azurerm_managed_disk.mongo.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm["db"].id
  lun                = 0
  caching            = "ReadWrite"
}
