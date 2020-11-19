param cloudlensProjectKey string {
  metadata: {
    description: 'The CloudLens Project Key. Used by the agents to connect back to the backend.'
  }
  secure: true
}
param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine.'
  }
}
param toolVmSize string {
  metadata: {
    description: 'The vm size where Moloch will be deployed'
  }
  default: 'Standard_D2_v2'
}
param toolVmName string {
  metadata: {
    description: 'The name of the vm where Moloch will be deployed'
  }
  default: 'MolochTool'
}
param tapVmSize string {
  metadata: {
    description: 'The vm size where the tap will be deployed'
  }
  default: 'Standard_D1_v2'
}
param tapVmName string {
  metadata: {
    description: 'The name of the vm where the tap will be deployed'
  }
  default: 'CloudLensTap'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/cloudlens-moloch-ubuntu/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param authenticationType string {
  allowed: [
    'sshPublicKey'
    'password'
  ]
  metadata: {
    description: 'Type of authentication to use on the Virtual Machine. SSH key is recommended.'
  }
  default: 'sshPublicKey'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}

var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var storageAccountType = 'Standard_LRS'
var publicIPAddressType = 'Dynamic'
var virtualNetworkName = 'CloudLensVNET'
var ubuntuOSVersion = '16.04.0-LTS'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var toolPublicIPAddressName = 'molochPublicIP'
var toolStorageAccountName = 'tooldisk${uniqueString(resourceGroup().id)}'
var toolDnsLabelPrefix = 'moloch-${uniqueString(resourceGroup().id)}'
var toolNicName = 'MolochVMNic'
var tapPublicIPAddressName = 'cloudlensPublicIP'
var tapStorageAccountName = 'tapdisk${uniqueString(resourceGroup().id)}'
var tapDnsLabelPrefix = 'cloudlens-${uniqueString(resourceGroup().id)}'
var tapNicName = 'CloudLensVMNic'
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
var networkSecurityGroupName = 'default-NSG'

resource toolStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2018-02-01' = {
  name: toolStorageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {}
}

resource tapStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2018-02-01' = {
  name: tapStorageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {}
}

resource toolPublicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2017-06-01' = {
  name: toolPublicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: toolDnsLabelPrefix
    }
  }
}

resource tapPublicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2017-06-01' = {
  name: tapPublicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: tapDnsLabelPrefix
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
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2017-06-01' = {
  name: virtualNetworkName
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

resource toolNicName_resource 'Microsoft.Network/networkInterfaces@2017-06-01' = {
  name: toolNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: toolPublicIPAddressName_resource.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    toolPublicIPAddressName_resource
    virtualNetworkName_resource
  ]
}

resource tapNicName_resource 'Microsoft.Network/networkInterfaces@2017-06-01' = {
  name: tapNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: tapPublicIPAddressName_resource.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    tapPublicIPAddressName_resource
    virtualNetworkName_resource
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
          id: toolNicName_resource.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: concat(reference('Microsoft.Storage/storageAccounts/${toolStorageAccountName}', '2018-02-01').primaryEndpoints.blob)
      }
    }
  }
  dependsOn: [
    toolStorageAccountName_resource
    toolNicName_resource
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
          id: tapNicName_resource.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: concat(reference('Microsoft.Storage/storageAccounts/${tapStorageAccountName}', '2018-02-01').primaryEndpoints.blob)
      }
    }
  }
  dependsOn: [
    tapStorageAccountName_resource
    tapNicName_resource
  ]
}

resource toolVmName_config 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = {
  name: '${toolVmName}/config'
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
  dependsOn: [
    toolVmName_resource
  ]
}

resource tapVmName_config 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = {
  name: '${tapVmName}/config'
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
  dependsOn: [
    tapVmName_resource
  ]
}

output Moloch_SSH_Command string = 'ssh ${adminUsername}@${reference(toolPublicIPAddressName).dnsSettings.fqdn}'
output Moloch_Host_Name string = reference(toolPublicIPAddressName).dnsSettings.fqdn
output Tapping_Host_SSH_Command string = 'ssh ${adminUsername}@${reference(tapPublicIPAddressName).dnsSettings.fqdn}'
output Tapping_Host_Name string = reference(tapPublicIPAddressName).dnsSettings.fqdn