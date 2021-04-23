@description('Username for the Virtual Machine.')
param adminUsername string

@allowed([
  'password'
  'sshPublicKey'
])
@description('Authentication type')
param authenticationType string = 'sshPublicKey'

@description('Password for the Virtual Machine.')
@secure()
param adminPassword string = ''

@description('ssh key for the Virtual Machine.')
@secure()
param sshPublicKey string = ''

@description('The size of the VM to create')
param vmSize string = 'Standard_D2_V3'

@description('Installs Ubuntu Mate desktop GUI')
param desktopInstall bool = false

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-msi-linux-terraform/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

var dnsLabelPrefix = 'msi${uniqueString(resourceGroup().id)}'
var infraStorageAccountName_var = take('storeinfra${uniqueString(resourceGroup().id)}${dnsLabelPrefix}', 24)
var stateStorageAccountName_var = take('storestate${uniqueString(resourceGroup().id)}${dnsLabelPrefix}', 24)
var nicName_var = 'nic${vmName_var}'
var networkSecurityGroupName_var = 'nsg${vmName_var}'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressName_var = 'pip${uniqueString(resourceGroup().id)}'
var vmName_var = 'vm${uniqueString(resourceGroup().id)}'
var virtualNetworkName_var = 'vnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
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
var installParm3 = ' -a ${stateStorageAccountName_var}'
var installParm4 = ((desktopInstall == bool('true')) ? ' -d ${desktopInstall}' : '')
var installParm5 = ' -t ${subscription().tenantId}'

resource infraStorageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: infraStorageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource stateStorageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: stateStorageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2019-11-01' = {
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
        }
      }
    ]
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: networkSecurityGroupName_var
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

resource nicName 'Microsoft.Network/networkInterfaces@2019-11-01' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupName.id
    }
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName_var
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
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
          id: nicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(infraStorageAccountName_var).primaryEndpoints.blob
      }
    }
  }
}

resource id_contributor 'Microsoft.Authorization/roleAssignments@2019-04-01-preview' = {
  name: guid(resourceGroup().id, contributor)
  properties: {
    roleDefinitionId: contributor
    principalId: reference(vmName_var, '2019-12-01', 'Full').identity.principalId
    scope: subscriptionResourceId('Microsoft.Resources/resourceGroups', resourceGroup().name)
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    vmName
  ]
}

resource vmName_customscriptextension 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  parent: vmName
  name: 'customscriptextension'
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
      commandToExecute: 'bash infra.sh && bash install.sh ${installParm1}${installParm2}${installParm3}${installParm4}${installParm5} -k ${listKeys(stateStorageAccountName.id, '2019-06-01').keys[0].value} -l ${reference(vmName_var, '2019-12-01', 'Full').identity.principalId}'
    }
  }
  dependsOn: [
    id_contributor
  ]
}

output fqdn string = reference(publicIPAddressName.id, '2019-09-01').dnsSettings.fqdn