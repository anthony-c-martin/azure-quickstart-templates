@description('Name of the Virtual Machine.')
param vmName string = 'dnsproxy'

@description('User name for the Virtual Machine.')
param adminUsername string

@description('The name of the storage account for diagnostics.  Storage account names must be globally unique.')
param storageAccountName string

@description('This is the IP address to forward DNS queries to. The default value represents Azure\'s internal DNS recursive resolvers.')
param forwardIP string = '168.63.129.16'

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('Virtual machine size')
param vmSize string = 'Standard_A1_v2'

@description('The base URI where artifacts required by this template are located.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/301-dns-forwarder/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var ubuntuOSVersion = '18.04-LTS'
var asetName_var = 'dnsproxy-avail'
var nsgName_var = 'dnsproxy-nsg'
var vnetName_var = 'dnsproxy-vnet'
var vnetAddressPrefix = '10.0.0.0/8'
var subNet1Name = 'subnet1'
var subNet1Prefix = '10.1.0.0/16'
var storType = 'Standard_LRS'
var location_var = location
var nicName_var = '${vmName}-nic'
var pipName_var = '${vmName}-pip'
var scriptUrl = uri(artifactsLocation, 'forwarderSetup.sh${artifactsLocationSasToken}')
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

resource storageAccountName_resource 'Microsoft.Storage/StorageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location_var
  sku: {
    name: storType
  }
  kind: 'StorageV2'
}

resource asetName 'Microsoft.Compute/availabilitySets@2019-12-01' = {
  name: asetName_var
  location: location_var
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 2
  }
}

resource nsgName 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: nsgName_var
  location: location_var
  properties: {
    securityRules: [
      {
        name: 'allow_ssh_in'
        properties: {
          description: 'The only thing allowed is SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vnetName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnetName_var
  location: location_var
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subNet1Name
        properties: {
          addressPrefix: subNet1Prefix
        }
      }
    ]
  }
}

resource pipName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: pipName_var
  location: location_var
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nicName_var
  location: location_var
  properties: {
    networkSecurityGroup: {
      id: nsgName.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipName.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subNet1Name)
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetName
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName
  location: location_var
  properties: {
    availabilitySet: {
      id: asetName.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: ubuntuOSVersion
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
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
        storageUri: reference(resourceId('Microsoft.Storage/storageAccounts', toLower(storageAccountName))).primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageAccountName_resource
  ]
}

resource vmName_setupdnsfirewall 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  parent: vmName_resource
  name: 'setupdnsfirewall'
  location: location_var
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        scriptUrl
      ]
      commandToExecute: 'sh forwarderSetup.sh ${forwardIP} ${vnetAddressPrefix}'
    }
  }
}