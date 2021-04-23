@description('The CloudLens Project Key. Used by the agents to connect back to the backend.')
@secure()
param cloudlensProjectKey string

@description('User name for the Virtual Machine.')
param adminUsername string

@description('The vm size where Moloch will be deployed')
param toolVmSize string = 'Standard_D2_v2'

@description('The name of the vm where Moloch will be deployed')
param toolVmName string = 'MolochTool'

@description('The vm size where the tap will be deployed')
param tapVmSize string = 'Standard_D1_v2'

@description('The name of the vm where the tap will be deployed')
param tapVmName string = 'CloudLensTap'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/cloudlens-moloch-ubuntu/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var storageAccountType = 'Standard_LRS'
var publicIPAddressType = 'Dynamic'
var virtualNetworkName_var = 'CloudLensVNET'
var ubuntuOSVersion = '16.04.0-LTS'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var toolPublicIPAddressName_var = 'molochPublicIP'
var toolStorageAccountName_var = 'tooldisk${uniqueString(resourceGroup().id)}'
var toolDnsLabelPrefix = 'moloch-${uniqueString(resourceGroup().id)}'
var toolNicName_var = 'MolochVMNic'
var tapPublicIPAddressName_var = 'cloudlensPublicIP'
var tapStorageAccountName_var = 'tapdisk${uniqueString(resourceGroup().id)}'
var tapDnsLabelPrefix = 'cloudlens-${uniqueString(resourceGroup().id)}'
var tapNicName_var = 'CloudLensVMNic'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}
var networkSecurityGroupName_var = 'default-NSG'

resource toolStorageAccountName 'Microsoft.Storage/storageAccounts@2018-02-01' = {
  name: toolStorageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {}
}

resource tapStorageAccountName 'Microsoft.Storage/storageAccounts@2018-02-01' = {
  name: tapStorageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {}
}

resource toolPublicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-06-01' = {
  name: toolPublicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: toolDnsLabelPrefix
    }
  }
}

resource tapPublicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-06-01' = {
  name: tapPublicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: tapDnsLabelPrefix
    }
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName_var
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
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2017-06-01' = {
  name: virtualNetworkName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource toolNicName 'Microsoft.Network/networkInterfaces@2017-06-01' = {
  name: toolNicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: toolPublicIPAddressName.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource tapNicName 'Microsoft.Network/networkInterfaces@2017-06-01' = {
  name: tapNicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: tapPublicIPAddressName.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource toolVmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: toolVmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: toolVmSize
    }
    osProfile: {
      computerName: toolVmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: ubuntuOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: toolNicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: concat(reference('Microsoft.Storage/storageAccounts/${toolStorageAccountName_var}', '2018-02-01').primaryEndpoints.blob)
      }
    }
  }
  dependsOn: [
    toolStorageAccountName
  ]
}

resource tapVmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: tapVmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: tapVmSize
    }
    osProfile: {
      computerName: tapVmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: ubuntuOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: tapNicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: concat(reference('Microsoft.Storage/storageAccounts/${tapStorageAccountName_var}', '2018-02-01').primaryEndpoints.blob)
      }
    }
  }
  dependsOn: [
    tapStorageAccountName
  ]
}

resource toolVmName_config 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = {
  parent: toolVmName_resource
  name: 'config'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      skipDos2Unix: false
      timestamp: 123456789
    }
    protectedSettings: {
      fileUris: [
        '${artifactsLocation}scripts/setup-moloch.sh${artifactsLocationSasToken}'
      ]
      commandToExecute: './setup-moloch.sh ${cloudlensProjectKey}'
    }
  }
}

resource tapVmName_config 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = {
  parent: tapVmName_resource
  name: 'config'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      skipDos2Unix: false
      timestamp: 123456789
    }
    protectedSettings: {
      fileUris: [
        '${artifactsLocation}scripts/setup-tap.sh${artifactsLocationSasToken}'
      ]
      commandToExecute: './setup-tap.sh ${cloudlensProjectKey}'
    }
  }
}

output Moloch_SSH_Command string = 'ssh ${adminUsername}@${reference(toolPublicIPAddressName_var).dnsSettings.fqdn}'
output Moloch_Host_Name string = reference(toolPublicIPAddressName_var).dnsSettings.fqdn
output Tapping_Host_SSH_Command string = 'ssh ${adminUsername}@${reference(tapPublicIPAddressName_var).dnsSettings.fqdn}'
output Tapping_Host_Name string = reference(tapPublicIPAddressName_var).dnsSettings.fqdn