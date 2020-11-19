param adminUsername string {
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
}
param authenticationType string {
  allowed: [
    'password'
    'sshPublicKey'
  ]
  metadata: {
    description: 'Authentication type'
  }
  default: 'sshPublicKey'
}
param adminPassword string {
  metadata: {
    description: 'Password for the Virtual Machine.'
  }
  secure: true
  default: ''
}
param sshPublicKey string {
  metadata: {
    description: 'ssh key for the Virtual Machine.'
  }
  secure: true
  default: ''
}
param vmSize string {
  metadata: {
    description: 'The size of the VM to create'
  }
  default: 'Standard_D2_V3'
}
param desktopInstall bool {
  metadata: {
    description: 'Installs Ubuntu Mate desktop GUI'
  }
  default: false
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-msi-linux-terraform/'
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

var dnsLabelPrefix = 'msi${uniqueString(resourceGroup().id)}'
var infraStorageAccountName = take('storeinfra${uniqueString(resourceGroup().id)}${dnsLabelPrefix}', 24)
var stateStorageAccountName = take('storestate${uniqueString(resourceGroup().id)}${dnsLabelPrefix}', 24)
var nicName = 'nic${vmName}'
var networkSecurityGroupName = 'nsg${vmName}'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressName = 'pip${uniqueString(resourceGroup().id)}'
var vmName = 'vm${uniqueString(resourceGroup().id)}'
var virtualNetworkName = 'vnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var linuxConfiguration = {
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
var contributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
var installParm1 = ' -u ${adminUsername}'
var installParm2 = ' -s ${subscription().subscriptionId}'
var installParm3 = ' -a ${stateStorageAccountName}'
var installParm4 = ((desktopInstall == bool('true')) ? ' -d ${desktopInstall}' : '')
var installParm5 = ' -t ${subscription().tenantId}'

resource infraStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: infraStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource stateStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: stateStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-11-01' = {
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
        }
      }
    ]
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-ssh'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '22'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'rdp-rule'
        properties: {
          description: 'Allow RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1001
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2019-11-01' = {
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
            id: subnetRef
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupName_resource.id
    }
  }
  dependsOn: [
    publicIPAddressName_resource
    virtualNetworkName_resource
    networkSecurityGroupName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
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
        storageUri: reference(infraStorageAccountName).primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    nicName_resource
  ]
}

resource id_contributor 'Microsoft.Authorization/roleAssignments@2019-04-01-preview' = {
  name: guid(resourceGroup().id, contributor)
  properties: {
    roleDefinitionId: contributor
    principalId: reference(vmName, '2019-12-01', 'Full').identity.principalId
    scope: subscriptionResourceId('Microsoft.Resources/resourceGroups', resourceGroup().name)
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    vmName_resource
  ]
}

resource vmName_customscriptextension 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  name: '${vmName}/customscriptextension'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, 'scripts/infra.sh${artifactsLocationSasToken}')
        uri(artifactsLocation, 'scripts/install.sh${artifactsLocationSasToken}')
        uri(artifactsLocation, 'scripts/desktop.sh${artifactsLocationSasToken}')
        uri(artifactsLocation, 'scripts/azureProviderAndCreds.tf${artifactsLocationSasToken}')
      ]
    }
    protectedSettings: {
      commandToExecute: 'bash infra.sh && bash install.sh ${installParm1}${installParm2}${installParm3}${installParm4}${installParm5} -k ${listKeys(stateStorageAccountName_resource.id, '2019-06-01').keys[0].value} -l ${reference(vmName, '2019-12-01', 'Full').identity.principalId}'
    }
  }
  dependsOn: [
    id_contributor
  ]
}

output fqdn string = reference(publicIPAddressName_resource.id, '2019-09-01').dnsSettings.fqdn