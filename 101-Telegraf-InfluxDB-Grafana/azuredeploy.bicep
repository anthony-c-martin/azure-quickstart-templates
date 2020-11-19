param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine.'
  }
}
param sshPublicKey string {
  metadata: {
    description: 'Configure the linux machines with the SSH public key string.  Your key should include three parts, for example \'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\''
  }
}
param tigDnsPrefix string {
  maxLength: 50
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Virtual Machine.'
  }
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-Telegraf-InfluxDB-Grafana/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var resourcePrefix = 'tig'
var storageAccountName = concat(resourcePrefix, uniqueString(resourceGroup().id))
var OSDiskName = '${resourcePrefix}OSDisk'
var nicName = '${resourcePrefix}VMNic'
var subnetName = '${resourcePrefix}Subnet'
var publicIPAddressName = '${resourcePrefix}PublicIP'
var vmStorageAccountContainerName = 'vhds'
var vmName = '${resourcePrefix}VM'
var vmExtensionName = '${resourcePrefix}Init'
var virtualNetworkName = '${resourcePrefix}VNET'
var extensionScript = 'tigscript.sh'
var configfilelocation = '${artifactsLocation}scripts/Configfiles.zip${artifactsLocationSasToken}'
var networkSecurityGroupName = 'default-NSG'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2017-10-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2017-10-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: concat(tigDnsPrefix, uniqueString(resourceGroup().id))
    }
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-22'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'TCP'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-3000'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3000'
          protocol: 'TCP'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-8083'
        properties: {
          priority: 1002
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '8083'
          protocol: 'TCP'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-8086'
        properties: {
          priority: 1003
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '8086'
          protocol: 'TCP'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-8090'
        properties: {
          priority: 1004
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '8090'
          protocol: 'TCP'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2017-10-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroupName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroupName_resource
  ]
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2017-10-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName_resource.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
    virtualNetworkName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D1_v2'
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName_resource.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: concat(reference(storageAccountName_resource.id, '2016-01-01').primaryEndpoints.blob)
      }
    }
  }
  dependsOn: [
    storageAccountName_resource
    nicName_resource
  ]
}

resource vmName_vmExtensionName 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = {
  name: '${vmName}/${vmExtensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'scripts/${extensionScript}${artifactsLocationSasToken}')
      ]
    }
    protectedSettings: {
      commandToExecute: 'sh tigscript.sh ${configfilelocation}'
    }
  }
  dependsOn: [
    vmName_resource
  ]
}

output TIGVmFQDN string = reference(publicIPAddressName).dnsSettings.fqdn
output SSH string = 'ssh -L 3000:localhost:3000 -L 8083:localhost:8083 ${adminUsername}@${reference(publicIPAddressName).dnsSettings.fqdn}'