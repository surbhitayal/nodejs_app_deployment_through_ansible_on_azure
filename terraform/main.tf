resource "azurerm_resource_group" "test" {
 name     = "acctestrg"
 location = "East US"
}

resource "azurerm_virtual_network" "test" {
 name                = "acctvn"
 address_space       = ["10.0.0.0/16"]
 location            = "${azurerm_resource_group.test.location}"
 resource_group_name = "${azurerm_resource_group.test.name}"
}

resource "azurerm_subnet" "test" {
 name                 = "acctsub"
 resource_group_name  = "${azurerm_resource_group.test.name}"
 virtual_network_name = "${azurerm_virtual_network.test.name}"
 address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "test" {
 name                         = "publicIP"
 location                     = "${azurerm_resource_group.test.location}"
 resource_group_name          = "${azurerm_resource_group.test.name}"
 public_ip_address_allocation = "static"
}

resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "${azurerm_resource_group.test.location}"
    resource_group_name = "${azurerm_resource_group.test.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "Terraform Demo"
    }
}

resource "azurerm_network_interface" "test" {
 name                = "acctni${count.index}"
 location            = "${azurerm_resource_group.test.location}"
 resource_group_name = "${azurerm_resource_group.test.name}"
 network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"
 ip_configuration {
   name                          = "testConfiguration"
   subnet_id                     = "${azurerm_subnet.test.id}"
   private_ip_address_allocation = "dynamic"
   public_ip_address_id          = "${azurerm_public_ip.test.id}"
}
}
resource "azurerm_managed_disk" "test" {
 name                 = "datadisk_existing_${count.index}"
 location             = "${azurerm_resource_group.test.location}"
 resource_group_name  = "${azurerm_resource_group.test.name}"
 storage_account_type = "Standard_LRS"
 create_option        = "Empty"
 disk_size_gb         = "1023"
}

resource "azurerm_availability_set" "avset" {
 name                         = "avset"
 location                     = "${azurerm_resource_group.test.location}"
 resource_group_name          = "${azurerm_resource_group.test.name}"
 platform_fault_domain_count  = 2
 platform_update_domain_count = 2
 managed                      = true
}

resource "azurerm_virtual_machine" "node" {
 name                  = "acctvm0"
 location              = "${azurerm_resource_group.test.location}"
 availability_set_id   = "${azurerm_availability_set.avset.id}"
 resource_group_name   = "${azurerm_resource_group.test.name}"
 network_interface_ids = ["${azurerm_network_interface.test.id}"]
 vm_size               = "Standard_DS1_v2"

 # Uncomment this line to delete the OS disk automatically when deleting the VM
 # delete_os_disk_on_termination = true

 # Uncomment this line to delete the data disks automatically when deleting the VM
 # delete_data_disks_on_termination = true

 storage_image_reference {
   publisher = "Canonical"
   offer     = "UbuntuServer"
   sku       = "16.04-LTS"
   version   = "latest"
 }

 storage_os_disk {
   name              = "myosdisk${count.index}"
   caching           = "ReadWrite"
   create_option     = "FromImage"
   managed_disk_type = "Standard_LRS"
 }

 # Optional data disks
 storage_data_disk {
   name              = "datadisk_new_${count.index}"
   managed_disk_type = "Standard_LRS"
   create_option     = "Empty"
   lun               = 0
   disk_size_gb      = "1023"
 }

 storage_data_disk {
   name            = "${element(azurerm_managed_disk.test.*.name, count.index)}"
   managed_disk_id = "${element(azurerm_managed_disk.test.*.id, count.index)}"
   create_option   = "Attach"
   lun             = 1
   disk_size_gb    = "${element(azurerm_managed_disk.test.*.disk_size_gb, count.index)}"
 }

 os_profile {
   computer_name  = "hostname"
   admin_username = "testadmin"
   admin_password = "Password1234!"
 }
 os_profile_linux_config {
         disable_password_authentication = false
        ssh_keys {
            path     = "/home/testadmin/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAx6BF2ZT0gEIDHGc0uGGeYCVPSLzN5jOCyBI3VCgvaYsupbeTusjYuFBK1g96of+FBn6FSC3QVY2p7gD/6yaXjeuWc0ZsHAohOMNydQl9eq+oWJNH4OoiJXEf6ndkjAsVBp9WyIoWGMpx6fD5EEIkCFVO3TprCEgyq26n8qGXb7xhw8/BRXhbj7oQDa3dyW9yb9NV0MS4a+gVSMu6uMC5L1mcAbaONmCNmL48m3eBbj2b/mHCkJxD0cKUXlo/Vouk7m3+TcQa6OAfq2UpCH6RN5HCwZffbdb66TJsvVlFrFtsCS1GcaRt8kA3tdQlA67iTUhCASWOmqy8CU/Nrg10cQ== rsa-key-20181213"
        }
    }
}



