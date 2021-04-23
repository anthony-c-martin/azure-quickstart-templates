@minLength(2)
@maxLength(6)
@description('This tag will be used as a prefix for the hostname of the SAS servers and Azure resources')
param SASApplicationName string = 'sasapp'

@description('Allow inbound SSH traffic to the Ansible Controller-Bastion Host from this CIDR block or IP address range. Must be a valid IP or CIDR range of the form x.x.x.x or x.x.x.x/x')
param adminIngressLocation string

@description('Virtual Network CIDR, ex. 10.10.0.0/16')
param vnetAddressCIDR string = '10.10.0.0/16'

@description('Virtual Network Public Subnet CIDR, ex. 10.10.1.0/24 which should allign with VNET CIDR')
param ansibleBastionPublicSubnetCIDR string = '10.10.1.0/24'

@description('Virtual Network Private Subnet CIDR, ex. 10.10.2.0/24 which should allign with VNET CIDR')
param SASPrivateSubnetCIDR string = '10.10.2.0/24'

@description('This is the SKU for the Ansible VM. The default SKU value represents the minimum recommended size for system stability in most SAS software license sets. The selected SKU must support premium disks. For details: https://azure.microsoft.com/en-in/pricing/details/virtual-machines/red-hat/')
param ansibleVMSize string = 'Standard_D4s_v3'

@description('This is the SKU for the Windows Server VM. The default SKU value represents the minimum recommended size for system stability in most SAS software license sets. The selected SKU must support premium disks')
param windowsRdpVMSize string = 'Standard_D8S_v3'

@description('This is the SKU for the Meta VM.The default SKU value represents the minimum recommended size for system stability in most SAS software license sets. The selected SKU must support premium disks. For details: https://azure.microsoft.com/en-in/pricing/details/virtual-machines/red-hat/')
param SASMetaVMSize string = 'Standard_D4s_v3'

@description('This is the SKU for the Compute VM.The default SKU value represents the minimum recommended size for system stability in most SAS software license sets. The selected SKU must support premium disks. For details: https://azure.microsoft.com/en-in/pricing/details/virtual-machines/red-hat/')
param SASComputeVMSize string = 'Standard_E8s_v3'

@description('This is the SKU for the Mid VM. The default SKU value represents the minimum recommended size for system stability in most SAS software license sets. The selected SKU must support premium disks. For details: https://azure.microsoft.com/en-in/pricing/details/virtual-machines/red-hat/')
param SASMidVMSize string = 'Standard_E8s_v3'

@minValue(100)
@maxValue(32767)
@description('The SAS data volume size for SAS 94')
param SASDataStorage int = 100

@description('Username for the Virtual Machine.')
param primaryUserName string

@minLength(12)
@maxLength(255)
@description('Password for RDP login & SAS admin account in SAS servers')
@secure()
param SASExternalPassword string

@minLength(8)
@maxLength(255)
@description('Password for SAS Internal Accounts(Metadata & WIP)')
@secure()
param SASInternalPassword string

@description('Virtual Network Private Subnet CIDR, ex. 10.10.3.0/24 which should allign with VNET CIDR')
param viyaPrivateSubnetCIDR string = '10.10.3.0/24'

@description('This is the SKU for the MicroServices VM. The default SKU value represents the minimum recommended size for system stability in most SAS software license sets. The selected SKU must support premium disks. For details: https://azure.microsoft.com/en-in/pricing/details/virtual-machines/red-hat/')
param viyaMicroservicesVMSize string = 'Standard_E16s_v3'

@description('This is the SKU for the SPRE VM. The default SKU value represents the minimum recommended size for system stability in most SAS software license sets. The selected SKU must support premium disks. For details: https://azure.microsoft.com/en-in/pricing/details/virtual-machines/red-hat/')
param viyaSpreVMSize string = 'Standard_E8s_v3'

@description('This is the SKU for the CASController VM. The default SKU value represents the minimum recommended size for system stability in most SAS software license sets. The selected SKU must support premium disk. For details: https://azure.microsoft.com/en-in/pricing/details/virtual-machines/red-hat/')
param viyaCASControllerVMSize string = 'Standard_E8s_v3'

@description('This is the SKU for the CAS Worker VM. The default SKU value represents the minimum recommended size for system stability in most SAS software license sets. The selected SKU must support premium disks. For details: https://azure.microsoft.com/en-in/pricing/details/virtual-machines/red-hat/')
param viyaCASWorkerVMSize string = 'Standard_E8s_v3'

@minValue(1)
@maxValue(100)
@description('The number of CAS Worker Nodes to create.')
param numberOfViyaCASNodes int = 1

@minValue(100)
@maxValue(32767)
@description('The SAS data volume size for SAS Viya.')
param SASViyaDataStorage int = 100

@description('Storage AccountName where SAS Depot is located')
param storageAccountName string

@description('Storage Account Key')
@secure()
param storageAccountKey string

@description('File Share Name where SASDepot is located')
param fileShareName string

@description('Folder Name in Azure File share where SAS94 depot is located')
param SASDepotFolder string = 'sasdepot'

@description('Folder Name in Azure File share where SAS Viya Repo is located')
param viyaRepoFolder string = 'viyarepo'

@description('Name of SAS Application Server License file.You will find this file inside the SAS Software Depot. It should be inside the folder sid_file.')
param SASServerLicenseFile string

@description('Key Vault Owner Object ID,Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault.Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets. e.g.In Azure Cloud PowerShell type PS> Get-AzADUser -UserPrincipalName user@domain.com | grep Id')
param keyVaultOwnerID string

@description('The full ssh public key that will be added to the servers.')
param SSHPublicKey string

@description('Azure Resources location, where all the SAS 94 and Viya resources should be created. e.g. servers, disks, IP\'s etc.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/sas9.4-viya/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

var access_policy_template = uri(artifactsLocation, 'nestedtemplates/access_policy.json${artifactsLocationSasToken}')
var ansible_nw_interface_var = '${SASApplicationName}_${ansible_vm_name_var}_nic'
var ansible_nw_sg_var = '${SASApplicationName}_${ansible_vm_name_var}_nsg'
var ansible_pub_nw_interface_var = '${SASApplicationName}_${ansible_vm_name_var}_pub_nic'
var ansible_vm_name_var = 'ansible'
var cascontroller_nw_interface_var = '${SASApplicationName}_${cascontroller_vm_name_var}_nic'
var cascontroller_nw_sg_var = '${SASApplicationName}_${cascontroller_vm_name_var}_nsg'
var cascontroller_vm_name_var = 'cascontroller'
var casworker_nw_sg_var = '${SASApplicationName}_${casworker_vm_name_var}_nsg'
var casworker_vm_name_var = 'casworker'
var certificatesPermissions = [
  'import'
  'get'
  'list'
]
var compute_nw_interface_var = '${SASApplicationName}_${compute_vm_name_var}_nic'
var compute_nw_sg_var = '${SASApplicationName}_${compute_vm_name_var}_nsg'
var compute_vm_name_var = 'compute'
var custom_data_cas = '#cloud-config\n mounts:\n   - [ ephemeral0, /cascache]'
var custom_data_sas = '#cloud-config\n mounts:\n   - [ ephemeral0, /saswork]'
var diagnostic_storagegroup_name_var = toLower('${SASApplicationName}diag${resourceGroupUniqueString}')
var domain_name = 'internal.cloudapp.net'
var key_vault_name_var = '${SASApplicationName}KeyVault'
var key_vault_secretname_pubkey = 'ansible-pubkey'
var key_vault_secretname_pvtkey = 'ansible-pvtkey'
var key_vault_secretname_sasext = 'sasextpw'
var key_vault_secretname_sasinst = 'sasintpw'
var key_vault_secretname_stgacc = 'stgacckey'
var keysPermissions = [
  'get'
  'list'
  'import'
]
var linux_extension_template = uri(artifactsLocation, 'nestedtemplates/vm_linux_extension.json${artifactsLocationSasToken}')
var meta_nw_interface_var = '${SASApplicationName}_${meta_vm_name_var}_nic'
var meta_nw_sg_var = '${SASApplicationName}_${meta_vm_name_var}_nsg'
var meta_vm_name_var = 'meta'
var microservices_nw_interface_var = '${SASApplicationName}_${microservices_vm_name_var}_nic'
var microservices_nw_sg_var = '${SASApplicationName}_${microservices_vm_name_var}_nsg'
var microservices_vm_name_var = 'microservices'
var mid_nw_interface_var = '${SASApplicationName}_${mid_vm_name_var}_nic'
var mid_nw_sg_var = '${SASApplicationName}_${mid_vm_name_var}_nsg'
var mid_vm_name_var = 'mid'
var ppg_name_var = '${SASApplicationName}_ppg_${resourceGroupUniqueString}'
var storage_account_uri = '${storageAccountName}.file.${environment().suffixes.storage}'
var pub_sub_nw_sg_var = '${SASApplicationName}_subnet_pub1_nsg'
var pvt_sub_nw_sg_var = '${SASApplicationName}_subnet_pvt1_nsg'
var rbacPrincipalID = keyVaultOwnerID
var rdp_nw_interface_var = '${SASApplicationName}_${rdp_vm_name_var}_nic'
var rdp_nw_sg_var = '${SASApplicationName}_${rdp_vm_name_var}_nsg'
var rdp_os_version = '2019-Datacenter'
var rdp_vm_name_var = 'rdp'
var reader_role = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
var resourceGroupUniqueString = uniqueString(resourceGroup().id)
var role_assignment_template = uri(artifactsLocation, 'nestedtemplates/role_assignments.json${artifactsLocationSasToken}')
var sas_opt_sas_disk_size = 128
var sas_osdisk_size = 128
var sas_viya_backup_size = 100
var sas94vm_tags = {
  Application: SASApplicationName
  Component: 'SAS94NonGrid'
}
var sasviyavm_tags = {
  Application: SASApplicationName
  Component: 'SASViya'
}
var secretsPermissions = [
  'get'
  'list'
  'set'
]
var skuName = 'standard'
var spre_nw_interface_var = '${SASApplicationName}_${spre_vm_name_var}_nic'
var spre_nw_sg_var = '${SASApplicationName}_${spre_vm_name_var}_nsg'
var spre_vm_name_var = 'spre'
var tenantId = subscription().tenantId
var vnet_name_var = '${SASApplicationName}_vnet'
var vnet_pub_subnt = '${SASApplicationName}_vnet_pub1_subnet'
var vnet_pvt_subnt = '${SASApplicationName}_vnet_pvt1_subnet'
var vnet_viya_pvt_subnt = '${SASApplicationName}_vnet_pvt2_subnet'
var windows_extension_template = uri(artifactsLocation, 'nestedtemplates/vm_windows_extension.json${artifactsLocationSasToken}')

resource ppg_name 'Microsoft.Compute/proximityPlacementGroups@2019-12-01' = {
  name: ppg_name_var
  location: location
}

resource vnet_name 'Microsoft.Network/virtualNetworks@2019-06-01' = {
  name: vnet_name_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressCIDR
      ]
    }
    subnets: [
      {
        name: vnet_pvt_subnt
        properties: {
          addressPrefix: SASPrivateSubnetCIDR
          networkSecurityGroup: {
            id: pvt_sub_nw_sg.id
          }
        }
      }
      {
        name: vnet_viya_pvt_subnt
        properties: {
          addressPrefix: viyaPrivateSubnetCIDR
          networkSecurityGroup: {
            id: pvt_sub_nw_sg.id
          }
        }
      }
      {
        name: vnet_pub_subnt
        properties: {
          addressPrefix: ansibleBastionPublicSubnetCIDR
          networkSecurityGroup: {
            id: pub_sub_nw_sg.id
          }
        }
      }
    ]
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource pub_sub_nw_sg 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: pub_sub_nw_sg_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-ssh'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: adminIngressLocation
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
    defaultSecurityRules: [
      {
        name: 'AllowVnetInBound'
        properties: {
          description: 'Allow inbound traffic from all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80,443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          description: 'Deny all inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowVnetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowInternetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 65001
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny all outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource pvt_sub_nw_sg 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: pvt_sub_nw_sg_var
  location: location
  properties: {
    defaultSecurityRules: [
      {
        name: 'AllowVnetInBound'
        properties: {
          description: 'Allow inbound traffic from all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80,443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          description: 'Deny all inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowVnetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowInternetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 65001
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny all outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource key_vault_name 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: key_vault_name_var
  location: location
  properties: {
    enabledForDeployment: true
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: false
    tenantId: tenantId
    accessPolicies: [
      {
        objectId: keyVaultOwnerID
        tenantId: tenantId
        permissions: {
          keys: keysPermissions
          secrets: secretsPermissions
        }
      }
    ]
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource key_vault_name_key_vault_secretname_sasinst 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: key_vault_name
  name: '${key_vault_secretname_sasinst}'
  location: location
  properties: {
    value: SASInternalPassword
  }
}

resource key_vault_name_key_vault_secretname_sasext 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: key_vault_name
  name: '${key_vault_secretname_sasext}'
  location: location
  properties: {
    value: SASExternalPassword
  }
}

resource key_vault_name_key_vault_secretname_stgacc 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: key_vault_name
  name: '${key_vault_secretname_stgacc}'
  location: location
  properties: {
    value: storageAccountKey
  }
}

resource diagnostic_storagegroup_name 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: diagnostic_storagegroup_name_var
  location: location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: false
    encryption: {
      services: {
        file: {
          enabled: true
        }
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

resource ansible_nw_sg 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: ansible_nw_sg_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-ssh'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: adminIngressLocation
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
    defaultSecurityRules: [
      {
        name: 'AllowVnetInBound'
        properties: {
          description: 'Allow inbound traffic from all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80,443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          description: 'Deny all inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowVnetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowInternetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 65001
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny all outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource meta_nw_sg 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: meta_nw_sg_var
  location: location
  properties: {
    defaultSecurityRules: [
      {
        name: 'AllowVnetInBound'
        properties: {
          description: 'Allow inbound traffic from all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          description: 'Deny all inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowVnetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowInternetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to the Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 65001
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny all outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource mid_nw_sg 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: mid_nw_sg_var
  location: location
  properties: {
    defaultSecurityRules: [
      {
        name: 'AllowVnetInBound'
        properties: {
          description: 'Allow inbound traffic from all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          description: 'Deny all inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowVnetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowInternetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to the Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 65001
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny all outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource compute_nw_sg 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: compute_nw_sg_var
  location: location
  properties: {
    defaultSecurityRules: [
      {
        name: 'AllowVnetInBound'
        properties: {
          description: 'Allow inbound traffic from all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          description: 'Deny all inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowVnetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowInternetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to the Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 65001
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny all outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource rdp_nw_sg 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: rdp_nw_sg_var
  location: location
  properties: {
    defaultSecurityRules: [
      {
        name: 'AllowVnetInBound'
        properties: {
          description: 'Allow inbound traffic from all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          description: 'Deny all inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowVnetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowInternetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to the Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 65001
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny all outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource microservices_nw_sg 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: microservices_nw_sg_var
  location: location
  properties: {
    defaultSecurityRules: [
      {
        name: 'AllowVnetInBound'
        properties: {
          description: 'Allow inbound traffic from all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          description: 'Deny all inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowVnetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowInternetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to the Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 65001
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny all outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource spre_nw_sg 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: spre_nw_sg_var
  location: location
  properties: {
    defaultSecurityRules: [
      {
        name: 'AllowVnetInBound'
        properties: {
          description: 'Allow inbound traffic from all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          description: 'Deny all inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowVnetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowInternetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to the Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 65001
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny all outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource cascontroller_nw_sg 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: cascontroller_nw_sg_var
  location: location
  properties: {
    defaultSecurityRules: [
      {
        name: 'AllowVnetInBound'
        properties: {
          description: 'Allow inbound traffic from all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          description: 'Deny all inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowVnetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowInternetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to the Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 65001
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny all outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource casworker_nw_sg 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: casworker_nw_sg_var
  location: location
  properties: {
    defaultSecurityRules: [
      {
        name: 'AllowVnetInBound'
        properties: {
          description: 'Allow inbound traffic from all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          description: 'Deny all inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowVnetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowInternetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to the Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 65001
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny all outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource ansible_pub_nw_interface 'Microsoft.Network/publicIPAddresses@2019-09-01' = {
  name: ansible_pub_nw_interface_var
  location: location
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource ansible_nw_interface 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: ansible_nw_interface_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: ansible_pub_nw_interface.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet_name_var, vnet_pub_subnt)
          }
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    networkSecurityGroup: {
      id: ansible_nw_sg.id
    }
  }
  dependsOn: [
    vnet_name
  ]
}

resource ansible_vm_name 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: ansible_vm_name_var
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: ansibleVMSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '7.7'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: '${ansible_vm_name_var}-osdisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 64
      }
      dataDisks: [
        {
          name: '${ansible_vm_name_var}-playbook'
          diskSizeGB: 50
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    osProfile: {
      computerName: ansible_vm_name_var
      adminUsername: primaryUserName
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${primaryUserName}/.ssh/authorized_keys'
              keyData: SSHPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: ansible_nw_interface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(diagnostic_storagegroup_name_var).primaryEndpoints.blob
      }
    }
    proximityPlacementGroup: {
      id: ppg_name.id
    }
  }
  dependsOn: [
    diagnostic_storagegroup_name
    key_vault_name
  ]
}

module AnsibleRoleAssignment '?' /*TODO: replace with correct path to [variables('role_assignment_template')]*/ = {
  name: 'AnsibleRoleAssignment'
  params: {
    roleAssignmentName: guid(ansible_vm_name.id, reader_role, rbacPrincipalID)
    roleDefinitionID: reader_role
    principalId: reference(ansible_vm_name.id, '2019-07-01', 'Full').identity.principalId
  }
  dependsOn: [
    AnsibleAccessPolicy
  ]
}

module AnsibleAccessPolicy '?' /*TODO: replace with correct path to [variables('access_policy_template')]*/ = {
  name: 'AnsibleAccessPolicy'
  params: {
    keyVaultName: key_vault_name_var
    tenantId: tenantId
    objectId: reference(ansible_vm_name.id, '2019-12-01', 'Full').identity.principalId
    secretsPermissions: secretsPermissions
    keysPermissions: keysPermissions
    certificatesPermissions: certificatesPermissions
  }
  dependsOn: [
    key_vault_name
  ]
}

module Phase1_AnsibleHostSetup '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase1-AnsibleHostSetup'
  params: {
    location: location
    vmName: ansible_vm_name_var
    commandToExecute: 'mkdir -p /var/log/sas/install && set -o pipefail; ./ansible_setup.sh ${storageAccountName} ${fileShareName} ${viyaRepoFolder} ${SASApplicationName} ${domain_name} ${ansible_vm_name_var} ${microservices_vm_name_var} ${cascontroller_vm_name_var} ${spre_vm_name_var} ${casworker_vm_name_var} ${key_vault_secretname_sasinst} ${key_vault_secretname_sasext} ${key_vault_name_var} ${key_vault_secretname_pvtkey} ${key_vault_secretname_pubkey} ${numberOfViyaCASNodes} ${mid_vm_name_var} ${artifactsLocation} ${compute_vm_name_var} ${meta_vm_name_var} ${key_vault_secretname_stgacc} ${storage_account_uri} 2>&1 | tee /var/log/sas/install/runPhase1_HostSetup.log'
    filepath: 'scripts/ansible_setup.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    ansible_vm_name
    AnsibleAccessPolicy
  ]
}

module Phase2_AnsibleSSLCopy '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase2-AnsibleSSLCopy'
  params: {
    location: location
    vmName: ansible_vm_name_var
    commandToExecute: 'set -o pipefail;./ansible_ssl.sh 2>&1 | tee /var/log/sas/install/runPhase2AnsibleSSLCopy.log;'
    filepath: 'scripts/ansible_ssl.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    ansible_vm_name
    Phase2_MetaInstall
    Phase2_MidInstall
    Phase2_ComputeInstall
    Phase4_ViyaInstallpart2
  ]
}

module Phase3_ViyaInstallpart1 '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase3-ViyaInstallpart1'
  params: {
    location: location
    vmName: ansible_vm_name_var
    commandToExecute: 'set -o pipefail;./viyainstall.sh 1 2>&1 | tee /var/log/sas/install/runPhase3_viyainstallpart1.log'
    filepath: 'scripts/viyainstall.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    Phase1_AnsibleHostSetup
    Phase2_MicroServicesViyaARK
    Phase2_SpreViyaARK
    Phase2_CASControllerViyaARK
    Phase2_casworker_vm_name_ViyaARK
  ]
}

module Phase4_ViyaInstallpart2 '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase4-ViyaInstallpart2'
  params: {
    location: location
    vmName: ansible_vm_name_var
    commandToExecute: 'set -o pipefail;./viyainstall.sh 2 2>&1 | tee /var/log/sas/install/runPhase4_viyainstallpart2.log'
    filepath: 'scripts/viyainstall.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    Phase3_ViyaInstallpart1
  ]
}

module Phase5_ViyaInstallpart3 '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase5-ViyaInstallpart3'
  params: {
    location: location
    vmName: ansible_vm_name_var
    commandToExecute: 'set -o pipefail;./viyainstall.sh 3 2>&1 | tee /var/log/sas/install/runPhase5_viyainstallpart3.log'
    filepath: 'scripts/viyainstall.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    Phase2_AnsibleSSLCopy
  ]
}

module Phase6_ViyaPostInstall '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase6-ViyaPostInstall'
  params: {
    location: location
    vmName: ansible_vm_name_var
    commandToExecute: 'set -o pipefail;./viyainstall.sh 4 2>&1 | tee /var/log/sas/install/runPhase6_viyapostinstall.log'
    filepath: 'scripts/viyainstall.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    Phase5_ViyaInstallpart3
  ]
}

resource rdp_nw_interface 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: rdp_nw_interface_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet_name_var, vnet_pvt_subnt)
          }
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    networkSecurityGroup: {
      id: rdp_nw_sg.id
    }
  }
  dependsOn: [
    vnet_name
  ]
}

resource rdp_vm_name 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: rdp_vm_name_var
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: windowsRdpVMSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: rdp_os_version
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    osProfile: {
      computerName: rdp_vm_name_var
      adminUsername: primaryUserName
      adminPassword: SASExternalPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: rdp_nw_interface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(diagnostic_storagegroup_name_var).primaryEndpoints.blob
      }
    }
    proximityPlacementGroup: {
      id: ppg_name.id
    }
  }
  dependsOn: [
    diagnostic_storagegroup_name
  ]
}

module RDPContentFileDownload '?' /*TODO: replace with correct path to [variables('windows_extension_template')]*/ = {
  name: 'RDPContentFileDownload'
  params: {
    location: location
    vmName: rdp_vm_name_var
    commandToExecute: 'powershell.exe Expand-Archive -LiteralPath client_install.zip -Destination C:\\WindowsAzure\\client_install'
    filepath: 'client_install.zip'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    rdp_vm_name
  ]
}

module Phase1_SASClientInstall '?' /*TODO: replace with correct path to [variables('windows_extension_template')]*/ = {
  name: 'Phase1-SASClientInstall'
  params: {
    location: location
    vmName: rdp_vm_name_var
    commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File sas_client_install.ps1 -stg_acc_name ${storageAccountName} -stg_key ${storageAccountKey} -file_share_name ${fileShareName} -depot_folder_name ${SASDepotFolder} -clients_sid ${SASServerLicenseFile} -app_name ${SASApplicationName} -mid_name ${mid_vm_name_var} -domain_name ${domain_name} -artifact_loc ${artifactsLocation} -storageuri ${storage_account_uri}'
    filepath: 'sas_client_install.ps1'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    RDPContentFileDownload
  ]
}

resource meta_nw_interface 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: meta_nw_interface_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet_name_var, vnet_pvt_subnt)
          }
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    networkSecurityGroup: {
      id: meta_nw_sg.id
    }
  }
  dependsOn: [
    vnet_name
  ]
}

resource meta_vm_name 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: meta_vm_name_var
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: sas94vm_tags
  properties: {
    hardwareProfile: {
      vmSize: SASMetaVMSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '7.7'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: '${meta_vm_name_var}-osdisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: sas_osdisk_size
      }
      dataDisks: [
        {
          name: '${meta_vm_name_var}-opt-sas'
          diskSizeGB: sas_opt_sas_disk_size
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    osProfile: {
      computerName: meta_vm_name_var
      adminUsername: primaryUserName
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${primaryUserName}/.ssh/authorized_keys'
              keyData: SSHPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: meta_nw_interface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(diagnostic_storagegroup_name_var).primaryEndpoints.blob
      }
    }
    proximityPlacementGroup: {
      id: ppg_name.id
    }
  }
  dependsOn: [
    diagnostic_storagegroup_name
  ]
}

module MetaRoleAssignment '?' /*TODO: replace with correct path to [variables('role_assignment_template')]*/ = {
  name: 'MetaRoleAssignment'
  params: {
    roleAssignmentName: guid(meta_vm_name.id, reader_role, rbacPrincipalID)
    roleDefinitionID: reader_role
    principalId: reference(meta_vm_name.id, '2019-07-01', 'Full').identity.principalId
  }
}

module MetaAccessPolicy '?' /*TODO: replace with correct path to [variables('access_policy_template')]*/ = {
  name: 'MetaAccessPolicy'
  params: {
    keyVaultName: key_vault_name_var
    tenantId: tenantId
    objectId: reference(meta_vm_name.id, '2019-12-01', 'Full').identity.principalId
    secretsPermissions: secretsPermissions
    keysPermissions: keysPermissions
    certificatesPermissions: certificatesPermissions
  }
  dependsOn: [
    key_vault_name
    AnsibleAccessPolicy
  ]
}

module Phase1_MetaHostSetup '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase1-MetaHostSetup'
  params: {
    location: location
    vmName: meta_vm_name_var
    commandToExecute: 'mkdir -p /var/log/sas/install && set -o pipefail; ./sasapp_prereq.sh ${SASApplicationName} ${SASDepotFolder} ${fileShareName} ${storageAccountName} ${domain_name} ${location} ${key_vault_secretname_sasinst} ${key_vault_secretname_sasext} ${key_vault_name_var} ${key_vault_secretname_pvtkey} ${key_vault_secretname_pubkey} ${mid_vm_name_var} ${meta_vm_name_var} ${compute_vm_name_var} ${SASServerLicenseFile} meta ${artifactsLocation} ${key_vault_secretname_stgacc} ${storage_account_uri} 2>&1 | tee /var/log/sas/install/runPhase1_HostSetup.log'
    filepath: 'scripts/sasapp_prereq.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    meta_vm_name
    MetaAccessPolicy
  ]
}

module MetaContentFileDownload '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'MetaContentFileDownload'
  params: {
    location: location
    vmName: meta_vm_name_var
    commandToExecute: 'cp response-properties.tar.gz /tmp'
    filepath: 'properties/response-properties.tar.gz'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    meta_vm_name
    Phase1_MetaHostSetup
  ]
}

module Phase2_MetaInstall '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase2-MetaInstall'
  params: {
    location: location
    vmName: meta_vm_name_var
    commandToExecute: 'set -o pipefail;./meta_install.sh 2>&1 | tee /var/log/sas/install/meta_install.log'
    filepath: 'scripts/meta_install.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    meta_vm_name
    MetaContentFileDownload
    Phase1_AnsibleHostSetup
  ]
}

module Phase3_MetaConfig '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase3-MetaConfig'
  params: {
    location: location
    vmName: meta_vm_name_var
    commandToExecute: 'set -o pipefail;./meta_config.sh 2>&1 | tee /var/log/sas/install/meta_config.log'
    filepath: 'scripts/meta_config.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    meta_vm_name
    Phase2_MetaInstall
    Phase2_AnsibleSSLCopy
  ]
}

resource compute_nw_interface 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: compute_nw_interface_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet_name_var, vnet_pvt_subnt)
          }
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    networkSecurityGroup: {
      id: compute_nw_sg.id
    }
  }
  dependsOn: [
    vnet_name
  ]
}

resource compute_vm_name 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: compute_vm_name_var
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: sas94vm_tags
  properties: {
    hardwareProfile: {
      vmSize: SASComputeVMSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '7.7'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: '${compute_vm_name_var}-osdisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: sas_osdisk_size
      }
      dataDisks: [
        {
          name: '${compute_vm_name_var}-opt-sas'
          diskSizeGB: sas_opt_sas_disk_size
          lun: 0
          createOption: 'Empty'
        }
        {
          name: '${compute_vm_name_var}-sasdata'
          diskSizeGB: SASDataStorage
          lun: 1
          createOption: 'Empty'
        }
      ]
    }
    osProfile: {
      computerName: compute_vm_name_var
      adminUsername: primaryUserName
      customData: base64(custom_data_sas)
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${primaryUserName}/.ssh/authorized_keys'
              keyData: SSHPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: compute_nw_interface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(diagnostic_storagegroup_name_var).primaryEndpoints.blob
      }
    }
    proximityPlacementGroup: {
      id: ppg_name.id
    }
  }
  dependsOn: [
    diagnostic_storagegroup_name
  ]
}

module ComputeRoleAssignment '?' /*TODO: replace with correct path to [variables('role_assignment_template')]*/ = {
  name: 'ComputeRoleAssignment'
  params: {
    roleAssignmentName: guid(compute_vm_name.id, reader_role, rbacPrincipalID)
    roleDefinitionID: reader_role
    principalId: reference(compute_vm_name.id, '2019-07-01', 'Full').identity.principalId
  }
}

module ComputeAccessPolicy '?' /*TODO: replace with correct path to [variables('access_policy_template')]*/ = {
  name: 'ComputeAccessPolicy'
  params: {
    keyVaultName: key_vault_name_var
    tenantId: tenantId
    objectId: reference(compute_vm_name.id, '2019-12-01', 'Full').identity.principalId
    secretsPermissions: secretsPermissions
    keysPermissions: keysPermissions
    certificatesPermissions: certificatesPermissions
  }
  dependsOn: [
    MetaAccessPolicy
    key_vault_name
  ]
}

module Phase1_ComputeHostSetup '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase1-ComputeHostSetup'
  params: {
    location: location
    vmName: compute_vm_name_var
    commandToExecute: 'mkdir -p /var/log/sas/install && set -o pipefail; ./sasapp_prereq.sh ${SASApplicationName} ${SASDepotFolder} ${fileShareName} ${storageAccountName} ${domain_name} ${location} ${key_vault_secretname_sasinst} ${key_vault_secretname_sasext} ${key_vault_name_var} ${key_vault_secretname_pvtkey} ${key_vault_secretname_pubkey} ${mid_vm_name_var} ${meta_vm_name_var} ${compute_vm_name_var} ${SASServerLicenseFile} compute ${artifactsLocation} ${key_vault_secretname_stgacc} ${storage_account_uri} 2>&1 | tee /var/log/sas/install/runPhase1_HostSetup.log'
    filepath: 'scripts/sasapp_prereq.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    compute_vm_name
    ComputeAccessPolicy
  ]
}

module ComputeContentFileDownload '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'ComputeContentFileDownload'
  params: {
    location: location
    vmName: compute_vm_name_var
    commandToExecute: 'cp response-properties.tar.gz /tmp'
    filepath: 'properties/response-properties.tar.gz'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    compute_vm_name
    Phase1_ComputeHostSetup
  ]
}

module Phase2_ComputeInstall '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase2-ComputeInstall'
  params: {
    location: location
    vmName: compute_vm_name_var
    commandToExecute: 'set -o pipefail;./compute_install.sh 2>&1 | tee /var/log/sas/install/compute_install.log'
    filepath: 'scripts/compute_install.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    compute_vm_name
    ComputeContentFileDownload
    Phase1_AnsibleHostSetup
  ]
}

module Phase3_ComputeConfig '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase3-ComputeConfig'
  params: {
    location: location
    vmName: compute_vm_name_var
    commandToExecute: 'set -o pipefail;./compute_config.sh 2>&1 | tee /var/log/sas/install/compute_config.log'
    filepath: 'scripts/compute_config.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    Phase2_ComputeInstall
    Phase3_MetaConfig
  ]
}

resource mid_nw_interface 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: mid_nw_interface_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet_name_var, vnet_pvt_subnt)
          }
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    networkSecurityGroup: {
      id: mid_nw_sg.id
    }
  }
  dependsOn: [
    vnet_name
  ]
}

resource mid_vm_name 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: mid_vm_name_var
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: sas94vm_tags
  properties: {
    hardwareProfile: {
      vmSize: SASMidVMSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '7.7'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: '${mid_vm_name_var}-osdisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: sas_osdisk_size
      }
      dataDisks: [
        {
          name: '${mid_vm_name_var}-opt-sas'
          diskSizeGB: sas_opt_sas_disk_size
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    osProfile: {
      computerName: mid_vm_name_var
      adminUsername: primaryUserName
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${primaryUserName}/.ssh/authorized_keys'
              keyData: SSHPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: mid_nw_interface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(diagnostic_storagegroup_name_var).primaryEndpoints.blob
      }
    }
    proximityPlacementGroup: {
      id: ppg_name.id
    }
  }
  dependsOn: [
    diagnostic_storagegroup_name
  ]
}

module MidRoleAssignment '?' /*TODO: replace with correct path to [variables('role_assignment_template')]*/ = {
  name: 'MidRoleAssignment'
  params: {
    roleAssignmentName: guid(mid_vm_name.id, reader_role, rbacPrincipalID)
    roleDefinitionID: reader_role
    principalId: reference(mid_vm_name.id, '2019-07-01', 'Full').identity.principalId
  }
}

module MidAccessPolicy '?' /*TODO: replace with correct path to [variables('access_policy_template')]*/ = {
  name: 'MidAccessPolicy'
  params: {
    keyVaultName: key_vault_name_var
    tenantId: tenantId
    objectId: reference(mid_vm_name.id, '2019-12-01', 'Full').identity.principalId
    secretsPermissions: secretsPermissions
    keysPermissions: keysPermissions
    certificatesPermissions: certificatesPermissions
  }
  dependsOn: [
    ComputeAccessPolicy
    key_vault_name
  ]
}

module Phase1_MidHostSetup '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase1-MidHostSetup'
  params: {
    location: location
    vmName: mid_vm_name_var
    commandToExecute: 'mkdir -p /var/log/sas/install && set -o pipefail; ./sasapp_prereq.sh ${SASApplicationName} ${SASDepotFolder} ${fileShareName} ${storageAccountName} ${domain_name} ${location} ${key_vault_secretname_sasinst} ${key_vault_secretname_sasext} ${key_vault_name_var} ${key_vault_secretname_pvtkey} ${key_vault_secretname_pubkey} ${mid_vm_name_var} ${meta_vm_name_var} ${compute_vm_name_var} ${SASServerLicenseFile} mid ${artifactsLocation} ${key_vault_secretname_stgacc} ${storage_account_uri} 2>&1 | tee /var/log/sas/install/runPhase1_HostSetup.log'
    filepath: 'scripts/sasapp_prereq.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    mid_vm_name
    MidAccessPolicy
  ]
}

module MidContentFileDownload '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'MidContentFileDownload'
  params: {
    location: location
    vmName: mid_vm_name_var
    commandToExecute: 'cp response-properties.tar.gz /tmp'
    filepath: 'properties/response-properties.tar.gz'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    mid_vm_name
    Phase1_MidHostSetup
  ]
}

module Phase2_MidInstall '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase2-MidInstall'
  params: {
    location: location
    vmName: mid_vm_name_var
    commandToExecute: 'set -o pipefail;./mid_install.sh 2>&1 | tee /var/log/sas/install/mid-install.log'
    filepath: 'scripts/mid_install.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    mid_vm_name
    MidContentFileDownload
    Phase1_AnsibleHostSetup
  ]
}

module Phase3_MidConfig '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase3-MidConfig'
  params: {
    location: location
    vmName: mid_vm_name_var
    commandToExecute: 'set -o pipefail;./mid_config.sh 2>&1 | tee /var/log/sas/install/mid_config.log'
    filepath: 'scripts/mid_config.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    mid_vm_name
    Phase2_MidInstall
    Phase3_ComputeConfig
  ]
}

resource microservices_nw_interface 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: microservices_nw_interface_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet_name_var, vnet_viya_pvt_subnt)
          }
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    networkSecurityGroup: {
      id: microservices_nw_sg.id
    }
  }
  dependsOn: [
    vnet_name
  ]
}

resource microservices_vm_name 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: microservices_vm_name_var
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: sasviyavm_tags
  properties: {
    hardwareProfile: {
      vmSize: viyaMicroservicesVMSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '7.7'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: '${microservices_vm_name_var}-osdisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: sas_osdisk_size
      }
      dataDisks: [
        {
          name: '${microservices_vm_name_var}-opt-sas'
          diskSizeGB: sas_opt_sas_disk_size
          lun: 0
          createOption: 'Empty'
        }
        {
          name: '${microservices_vm_name_var}-sasbackup'
          diskSizeGB: sas_viya_backup_size
          lun: 1
          createOption: 'Empty'
        }
      ]
    }
    osProfile: {
      computerName: microservices_vm_name_var
      adminUsername: primaryUserName
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${primaryUserName}/.ssh/authorized_keys'
              keyData: SSHPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: microservices_nw_interface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(diagnostic_storagegroup_name_var).primaryEndpoints.blob
      }
    }
    proximityPlacementGroup: {
      id: ppg_name.id
    }
  }
  dependsOn: [
    diagnostic_storagegroup_name
  ]
}

module MicroServicesRoleAssignment '?' /*TODO: replace with correct path to [variables('role_assignment_template')]*/ = {
  name: 'MicroServicesRoleAssignment'
  params: {
    roleAssignmentName: guid(microservices_vm_name.id, reader_role, rbacPrincipalID)
    roleDefinitionID: reader_role
    principalId: reference(microservices_vm_name.id, '2019-07-01', 'Full').identity.principalId
  }
}

module MicroServicesAccessPolicy '?' /*TODO: replace with correct path to [variables('access_policy_template')]*/ = {
  name: 'MicroServicesAccessPolicy'
  params: {
    keyVaultName: key_vault_name_var
    tenantId: tenantId
    objectId: reference(microservices_vm_name.id, '2019-12-01', 'Full').identity.principalId
    secretsPermissions: secretsPermissions
    keysPermissions: keysPermissions
    certificatesPermissions: certificatesPermissions
  }
  dependsOn: [
    key_vault_name
    MidAccessPolicy
  ]
}

module Phase1_MicroServicesHostSetup '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase1-MicroServicesHostSetup'
  params: {
    location: location
    vmName: microservices_vm_name_var
    commandToExecute: 'mkdir -p /var/log/sas/install && set -o pipefail; ./viya_prereq.sh ${storageAccountName} ${fileShareName} ${viyaRepoFolder} ${SASApplicationName} ${domain_name} ${ansible_vm_name_var} ${microservices_vm_name_var} ${cascontroller_vm_name_var} ${spre_vm_name_var} ${casworker_vm_name_var} ${key_vault_secretname_sasinst} ${key_vault_secretname_sasext} ${key_vault_name_var} ${key_vault_secretname_pvtkey} ${key_vault_secretname_pubkey} ${numberOfViyaCASNodes} ${artifactsLocation} ${key_vault_secretname_stgacc} ${storage_account_uri} 2>&1 | tee /var/log/sas/install/runPhase1_HostSetup.log'
    filepath: 'scripts/viya_prereq.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    microservices_vm_name
    MicroServicesAccessPolicy
  ]
}

module MicroServicesContentFileDownload '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'MicroServicesContentFileDownload'
  params: {
    location: location
    vmName: microservices_vm_name_var
    commandToExecute: 'cp viya-ark.tar.gz /tmp'
    filepath: 'properties/viya-ark.tar.gz'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    microservices_vm_name
    Phase1_MicroServicesHostSetup
  ]
}

module Phase2_MicroServicesViyaARK '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase2-MicroServicesViyaARK'
  params: {
    location: location
    vmName: microservices_vm_name_var
    commandToExecute: 'set -o pipefail;./viya_ark.sh 2>&1 | tee /var/log/sas/install/runPhase2_viyaark.log'
    filepath: 'scripts/viya_ark.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    MicroServicesContentFileDownload
    Phase1_AnsibleHostSetup
  ]
}

resource spre_nw_interface 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: spre_nw_interface_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet_name_var, vnet_viya_pvt_subnt)
          }
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    networkSecurityGroup: {
      id: spre_nw_sg.id
    }
  }
  dependsOn: [
    vnet_name
  ]
}

resource spre_vm_name 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: spre_vm_name_var
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: sasviyavm_tags
  properties: {
    hardwareProfile: {
      vmSize: viyaSpreVMSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '7.7'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: '${spre_vm_name_var}-osdisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: sas_osdisk_size
      }
      dataDisks: [
        {
          name: '${spre_vm_name_var}-opt-sas'
          diskSizeGB: sas_opt_sas_disk_size
          lun: 0
          createOption: 'Empty'
        }
        {
          name: '${spre_vm_name_var}-sasbackup'
          diskSizeGB: sas_viya_backup_size
          lun: 1
          createOption: 'Empty'
        }
      ]
    }
    osProfile: {
      computerName: spre_vm_name_var
      adminUsername: primaryUserName
      customData: base64(custom_data_sas)
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${primaryUserName}/.ssh/authorized_keys'
              keyData: SSHPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: spre_nw_interface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(diagnostic_storagegroup_name_var).primaryEndpoints.blob
      }
    }
    proximityPlacementGroup: {
      id: ppg_name.id
    }
  }
  dependsOn: [
    diagnostic_storagegroup_name
  ]
}

module SpreRoleAssignment '?' /*TODO: replace with correct path to [variables('role_assignment_template')]*/ = {
  name: 'SpreRoleAssignment'
  params: {
    roleAssignmentName: guid(spre_vm_name.id, reader_role, rbacPrincipalID)
    roleDefinitionID: reader_role
    principalId: reference(spre_vm_name.id, '2019-07-01', 'Full').identity.principalId
  }
}

module SpreAccessPolicy '?' /*TODO: replace with correct path to [variables('access_policy_template')]*/ = {
  name: 'SpreAccessPolicy'
  params: {
    keyVaultName: key_vault_name_var
    tenantId: tenantId
    objectId: reference(spre_vm_name.id, '2019-12-01', 'Full').identity.principalId
    secretsPermissions: secretsPermissions
    keysPermissions: keysPermissions
    certificatesPermissions: certificatesPermissions
  }
  dependsOn: [
    key_vault_name
    CASControllerAccessPolicy
  ]
}

module Phase1_SpreHostSetup '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase1-SpreHostSetup'
  params: {
    location: location
    vmName: spre_vm_name_var
    commandToExecute: 'mkdir -p /var/log/sas/install && set -o pipefail; ./viya_prereq.sh ${storageAccountName} ${fileShareName} ${fileShareName} ${SASApplicationName} ${domain_name} ${ansible_vm_name_var} ${microservices_vm_name_var} ${cascontroller_vm_name_var} ${spre_vm_name_var} ${casworker_vm_name_var} ${key_vault_secretname_sasinst} ${key_vault_secretname_sasext} ${key_vault_name_var} ${key_vault_secretname_pvtkey} ${key_vault_secretname_pubkey} ${numberOfViyaCASNodes} ${artifactsLocation} ${key_vault_secretname_stgacc} ${storage_account_uri} 2>&1 | tee /var/log/sas/install/runPhase1_HostSetup.log'
    filepath: 'scripts/viya_prereq.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    spre_vm_name
    SpreAccessPolicy
  ]
}

module SpreContentFileDownload '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'SpreContentFileDownload'
  params: {
    location: location
    vmName: spre_vm_name_var
    commandToExecute: 'cp viya-ark.tar.gz /tmp'
    filepath: 'properties/viya-ark.tar.gz'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    spre_vm_name
    Phase1_SpreHostSetup
  ]
}

module Phase2_SpreViyaARK '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase2-SpreViyaARK'
  params: {
    location: location
    vmName: spre_vm_name_var
    commandToExecute: 'set -o pipefail;./viya_ark.sh 2>&1 | tee /var/log/sas/install/runPhase2_viyaark.log'
    filepath: 'scripts/viya_ark.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    SpreContentFileDownload
    Phase1_AnsibleHostSetup
  ]
}

resource cascontroller_nw_interface 'Microsoft.Network/networkInterfaces@2019-09-01' = {
  name: cascontroller_nw_interface_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet_name_var, vnet_viya_pvt_subnt)
          }
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    networkSecurityGroup: {
      id: cascontroller_nw_sg.id
    }
  }
  dependsOn: [
    vnet_name
  ]
}

resource Cascontroller_vm_name 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: cascontroller_vm_name_var
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: sasviyavm_tags
  properties: {
    hardwareProfile: {
      vmSize: viyaCASControllerVMSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '7.7'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: '${cascontroller_vm_name_var}-osdisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: sas_osdisk_size
      }
      dataDisks: [
        {
          name: '${cascontroller_vm_name_var}-opt-sas'
          diskSizeGB: sas_opt_sas_disk_size
          lun: 0
          createOption: 'Empty'
        }
        {
          name: '${cascontroller_vm_name_var}-sasbackup'
          diskSizeGB: sas_viya_backup_size
          lun: 1
          createOption: 'Empty'
        }
        {
          name: '${cascontroller_vm_name_var}-sasdata'
          diskSizeGB: SASViyaDataStorage
          lun: 2
          createOption: 'Empty'
        }
      ]
    }
    osProfile: {
      computerName: cascontroller_vm_name_var
      adminUsername: primaryUserName
      customData: base64(custom_data_cas)
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${primaryUserName}/.ssh/authorized_keys'
              keyData: SSHPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: cascontroller_nw_interface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(diagnostic_storagegroup_name_var).primaryEndpoints.blob
      }
    }
    proximityPlacementGroup: {
      id: ppg_name.id
    }
  }
  dependsOn: [
    diagnostic_storagegroup_name
  ]
}

module CASControllerRoleAssignment '?' /*TODO: replace with correct path to [variables('role_assignment_template')]*/ = {
  name: 'CASControllerRoleAssignment'
  params: {
    roleAssignmentName: guid(Cascontroller_vm_name.id, reader_role, rbacPrincipalID)
    roleDefinitionID: reader_role
    principalId: reference(Cascontroller_vm_name.id, '2019-07-01', 'Full').identity.principalId
  }
}

module CASControllerAccessPolicy '?' /*TODO: replace with correct path to [variables('access_policy_template')]*/ = {
  name: 'CASControllerAccessPolicy'
  params: {
    keyVaultName: key_vault_name_var
    tenantId: tenantId
    objectId: reference(Cascontroller_vm_name.id, '2019-12-01', 'Full').identity.principalId
    secretsPermissions: secretsPermissions
    keysPermissions: keysPermissions
    certificatesPermissions: certificatesPermissions
  }
  dependsOn: [
    MicroServicesAccessPolicy
    key_vault_name
  ]
}

module Phase1_CASControllerHostSetup '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase1-CASControllerHostSetup'
  params: {
    location: location
    vmName: cascontroller_vm_name_var
    commandToExecute: 'mkdir -p /var/log/sas/install && set -o pipefail; ./viya_prereq.sh ${storageAccountName} ${fileShareName} ${fileShareName} ${SASApplicationName} ${domain_name} ${ansible_vm_name_var} ${microservices_vm_name_var} ${cascontroller_vm_name_var} ${spre_vm_name_var} ${casworker_vm_name_var} ${key_vault_secretname_sasinst} ${key_vault_secretname_sasext} ${key_vault_name_var} ${key_vault_secretname_pvtkey} ${key_vault_secretname_pubkey} ${numberOfViyaCASNodes} ${artifactsLocation} ${key_vault_secretname_stgacc} ${storage_account_uri} 2>&1 | tee /var/log/sas/install/runPhase1_HostSetup.log'
    filepath: 'scripts/viya_prereq.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    Cascontroller_vm_name
    CASControllerAccessPolicy
  ]
}

module CASContentFileDownload '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'CASContentFileDownload'
  params: {
    location: location
    vmName: cascontroller_vm_name_var
    commandToExecute: 'cp viya-ark.tar.gz /tmp'
    filepath: 'properties/viya-ark.tar.gz'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    Cascontroller_vm_name
    Phase1_CASControllerHostSetup
  ]
}

module Phase2_CASControllerViyaARK '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = {
  name: 'Phase2-CASControllerViyaARK'
  params: {
    location: location
    vmName: cascontroller_vm_name_var
    commandToExecute: 'set -o pipefail;./viya_ark.sh 2>&1 | tee /var/log/sas/install/runPhase2_viyaark.log'
    filepath: 'scripts/viya_ark.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    CASContentFileDownload
    Phase1_AnsibleHostSetup
  ]
}

resource SASApplicationName_casworker_vm_name_nic 'Microsoft.Network/networkInterfaces@2019-09-01' = [for i in range(0, numberOfViyaCASNodes): {
  name: '${SASApplicationName}_${casworker_vm_name_var}${i}_nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet_name_var, vnet_viya_pvt_subnt)
          }
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    networkSecurityGroup: {
      id: casworker_nw_sg.id
    }
  }
  dependsOn: [
    casworker_nw_sg
    vnet_name
  ]
}]

resource casworker_vm_name 'Microsoft.Compute/virtualMachines@2019-07-01' = [for i in range(0, numberOfViyaCASNodes): {
  name: concat(casworker_vm_name_var, i)
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: sasviyavm_tags
  properties: {
    hardwareProfile: {
      vmSize: viyaCASWorkerVMSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'RedHat'
        offer: 'RHEL'
        sku: '7.7'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: '${casworker_vm_name_var}${i}-osdisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: sas_osdisk_size
      }
      dataDisks: [
        {
          name: '${casworker_vm_name_var}${i}-opt-sas'
          diskSizeGB: sas_opt_sas_disk_size
          lun: 0
          createOption: 'Empty'
        }
        {
          name: '${casworker_vm_name_var}${i}-sasbackup'
          diskSizeGB: sas_viya_backup_size
          lun: 1
          createOption: 'Empty'
        }
      ]
    }
    osProfile: {
      computerName: concat(casworker_vm_name_var, i)
      adminUsername: primaryUserName
      customData: base64(custom_data_cas)
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${primaryUserName}/.ssh/authorized_keys'
              keyData: SSHPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${SASApplicationName}_${casworker_vm_name_var}${i}_nic')
        }
      ]
    }
    proximityPlacementGroup: {
      id: ppg_name.id
    }
  }
  dependsOn: [
    SASApplicationName_casworker_vm_name_nic
  ]
}]

module casworker_vm_name_roleassignment '?' /*TODO: replace with correct path to [variables('role_assignment_template')]*/ = [for i in range(0, numberOfViyaCASNodes): {
  name: '${casworker_vm_name_var}${i}roleassignment'
  params: {
    roleAssignmentName: guid(resourceId('Microsoft.Compute/virtualMachines', concat(casworker_vm_name_var, i)), reader_role, rbacPrincipalID)
    roleDefinitionID: reader_role
    principalId: reference(resourceId('Microsoft.Compute/virtualMachines', concat(casworker_vm_name_var, i)), '2019-07-01', 'Full').identity.principalId
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines', concat(casworker_vm_name_var, i))
  ]
}]

@batchSize(1)
module casworker_vm_name_accesspolicy '?' /*TODO: replace with correct path to [variables('access_policy_template')]*/ = [for i in range(0, numberOfViyaCASNodes): {
  name: '${casworker_vm_name_var}${i}accesspolicy'
  params: {
    keyVaultName: key_vault_name_var
    tenantId: tenantId
    objectId: reference(resourceId('Microsoft.Compute/virtualMachines', concat(casworker_vm_name_var, i)), '2019-07-01', 'Full').identity.principalId
    secretsPermissions: secretsPermissions
    keysPermissions: keysPermissions
    certificatesPermissions: certificatesPermissions
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines', concat(casworker_vm_name_var, i))
    key_vault_name
    SpreAccessPolicy
  ]
}]

module Phase1_casworker_vm_name_Hostsetup '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = [for i in range(0, numberOfViyaCASNodes): {
  name: 'Phase1-${casworker_vm_name_var}${i}Hostsetup'
  params: {
    location: location
    vmName: concat(casworker_vm_name_var, i)
    commandToExecute: 'mkdir -p /var/log/sas/install && set -o pipefail; ./viya_prereq.sh ${storageAccountName} ${fileShareName} ${fileShareName} ${SASApplicationName} ${domain_name} ${ansible_vm_name_var} ${microservices_vm_name_var} ${cascontroller_vm_name_var} ${spre_vm_name_var} ${casworker_vm_name_var} ${key_vault_secretname_sasinst} ${key_vault_secretname_sasext} ${key_vault_name_var} ${key_vault_secretname_pvtkey} ${key_vault_secretname_pubkey} ${numberOfViyaCASNodes} ${artifactsLocation} ${key_vault_secretname_stgacc} ${storage_account_uri} 2>&1 | tee /var/log/sas/install/runPhase1_HostSetup.log'
    filepath: 'scripts/viya_prereq.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    resourceId('Microsoft.Compute/virtualMachines', concat(casworker_vm_name_var, i))
    casworker_vm_name_accesspolicy
  ]
}]

@batchSize(1)
module WorkerContentFileDownload '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = [for i in range(0, numberOfViyaCASNodes): {
  name: 'WorkerContentFileDownload${i}'
  params: {
    location: location
    vmName: concat(casworker_vm_name_var, i)
    commandToExecute: 'cp viya-ark.tar.gz /tmp'
    filepath: 'properties/viya-ark.tar.gz'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    resourceId('Microsoft.Resources/deployments', 'Phase1-${casworker_vm_name_var}${i}Hostsetup')
  ]
}]

module Phase2_casworker_vm_name_ViyaARK '?' /*TODO: replace with correct path to [variables('linux_extension_template')]*/ = [for i in range(0, numberOfViyaCASNodes): {
  name: 'Phase2-${casworker_vm_name_var}${i}ViyaARK'
  params: {
    location: location
    vmName: concat(casworker_vm_name_var, i)
    commandToExecute: 'set -o pipefail;./viya_ark.sh 2>&1 | tee /var/log/sas/install/runPhase2_viyaark.log'
    filepath: 'scripts/viya_ark.sh'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    WorkerContentFileDownload
    Phase1_AnsibleHostSetup
  ]
}]

output AnsibleJumpHostServerIP string = '${ansible_vm_name.properties.osProfile.adminUsername}@${ansible_pub_nw_interface.properties.ipAddress}'
output SASRdpServerIP string = rdp_nw_interface.properties.ipConfigurations[0].properties.privateIPAddress
output SASStudioMidTier string = 'https://${SASApplicationName}${mid_vm_name_var}.${domain_name}:8343/SASStudio'
output SASInstallUser string = 'sasinst'
output viyaSASDrive string = 'https://${SASApplicationName}${microservices_vm_name_var}.${domain_name}/SASDrive'
output viyaSASStudio string = 'https://${SASApplicationName}${microservices_vm_name_var}.${domain_name}/SASStudioV'
output viyaUserLogon string = 'https://${SASApplicationName}${microservices_vm_name_var}.${domain_name}/SASLogon/reset_password?code=${json(split(reference('Phase6-ViyaPostInstall').outputs.instanceView.value.statuses[0].message, '#SASBOOT#')[1]).SAS_BOOT}'