@description('Storage Account name')
param storagename string = 'storage${uniqueString(resourceGroup().id)}'

@description('VM DNS label prefix')
param vm_dns string = 'docker-${uniqueString(resourceGroup().id)}'

@description('Admin user for VM')
param adminUser string

@description('Password for admin user')
@secure()
param adminPassword string

@description('VM size for VM')
param vmsize string = 'Standard_D4_v4'

@description('Size of the attached data disk in GB')
param diskSizeGB string = '256'

@description('Deployment location')
param location string = resourceGroup().location

@minLength(1)
@description('Email address for Let\'s Encrypt setup in Traefik')
param email string

@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/docker-portainer-traefik-windows-vm/'

@description('SAS Token for accessing script path')
@secure()
param artifactsLocationSasToken string = ''

var scriptUrl = uri(artifactsLocation, 'setup.ps1${artifactsLocationSasToken}')
var templateUrl = uri(artifactsLocation, 'configs/docker-compose.yml.template${artifactsLocationSasToken}')
var sshdConfigUrl = uri(artifactsLocation, 'configs/sshd_config_wpwd${artifactsLocationSasToken}')

resource storagename_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: toLower(storagename)
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  tags: {
    displayName: 'Storage account'
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'publicIP'
  location: location
  tags: {
    displayName: 'PublicIPAddress'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: vm_dns
    }
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-04-01' = {
  name: 'nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'rdp'
        properties: {
          description: 'description'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'https'
        properties: {
          description: 'description'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'ssh'
        properties: {
          description: 'description'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-04-01' = {
  name: 'virtualNetwork'
  location: location
  tags: {
    displayName: 'Virtual Network'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2020-04-01' = {
  name: 'nic'
  location: location
  tags: {
    displayName: 'Network Interface'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'virtualNetwork', 'subnet')
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetwork
  ]
}

resource dockerhost 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: 'dockerhost'
  location: location
  tags: {
    displayName: 'Docker host with Portainer and Traefik'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmsize
    }
    osProfile: {
      computerName: 'dockerhost'
      adminUsername: adminUser
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: 'datacenter-core-2004-with-containers-smalldisk'
        version: 'latest'
      }
      osDisk: {
        name: 'osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          diskSizeGB: diskSizeGB
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(resourceId('Microsoft.Storage/storageAccounts/', storagename)).primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    resourceId('Microsoft.Storage/storageAccounts', storagename)
  ]
}

resource dockerhost_setupScript 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  parent: dockerhost
  name: 'setupScript'
  location: location
  tags: {
    displayName: 'Setup script for portainer and Traefik'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        scriptUrl
        sshdConfigUrl
        templateUrl
      ]
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Bypass -file setup.ps1 -email ${email} -publicdnsname ${publicIP.properties.dnsSettings.fqdn} -adminPwd ${adminPassword}'
    }
  }
}

output dockerhost_dns string = publicIP.properties.dnsSettings.fqdn
output portainer_url string = 'https://${publicIP.properties.dnsSettings.fqdn}/portainer/'