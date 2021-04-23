@description('Team Services Account URL (e.g. https://myaccount.visualstudio.com)')
param vstsAccountURL string

@description('Team Services PAT for user with Agent Pools (read,manage) permissions')
param vstsPAT string

@description('Team Services Agent Pool Name')
param vstsPoolName string = 'Default'

@description('Team Services Agent Name')
param vstsAgentName string = 'redhat-build-full'

@description('Linux VM User Account Name')
param adminUsername string = 'vstsbuild'

@description('Linux VM User Password')
@secure()
param adminPassword string

@description('DNS Label for the Public IP. It must be lowercase and must match the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$.')
param dnsLabelPrefix string

@description('The number of VM build servers to provision in this deployment.')
param agentVMCount int = 1

@description('Location for all resources.')
param location string = resourceGroup().location

var imagePublisher = 'redhat'
var imageOffer = 'rhel'
var imageSKU = '7.3'
var nicName_var = '${dnsLabelPrefix}-nic-'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.0.0/24'
var publicIPAddressName_var = '${dnsLabelPrefix}-ip-'
var vmName_var = '${dnsLabelPrefix}-'
var virtualNetworkName_var = 'MyVNET'
var storageAccountName_var = 'vhds${uniqueString(resourceGroup().id)}'
var subnet1Ref = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName_var, subnet1Name)

resource StorageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = [for i in range(0, agentVMCount): {
  name: concat(storageAccountName_var, i)
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}]

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = [for i in range(0, agentVMCount): {
  name: concat(publicIPAddressName_var, i)
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: '${dnsLabelPrefix}-${i}'
    }
  }
}]

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
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
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, agentVMCount): {
  name: concat(nicName_var, i)
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', concat(publicIPAddressName_var, i))
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
  dependsOn: [
    concat(publicIPAddressName_var, i)
    virtualNetworkName
  ]
}]

resource vmName 'Microsoft.Compute/virtualMachines@2015-06-15' = [for i in range(0, agentVMCount): {
  name: concat(vmName_var, i)
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_F1'
    }
    osProfile: {
      computerName: concat(vmName_var, i)
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: base64(publicIPAddressName_var)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        name: 'osdisk1'
        vhd: {
          uri: '${reference(resourceId('Microsoft.Storage/storageAccounts/', concat(storageAccountName_var, i)), '2015-06-15').primaryEndpoints.blob}vhds/${dnsLabelPrefix}${i}.vhd'
        }
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(nicName_var, i))
        }
      ]
    }
  }
  dependsOn: [
    concat(storageAccountName_var, i)
    concat(nicName_var, i)
  ]
}]

resource vmName_configScript 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, agentVMCount): {
  name: '${vmName_var}${i}/configScript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/vsts-fullbuild-redhat-vm/scripts/full-rh-vstsbuild-install.sh'
      ]
      commandToExecute: 'sh full-rh-vstsbuild-install.sh ${vstsAccountURL} ${vstsPAT} ${vstsPoolName} ${vstsAgentName}${i} ${adminUsername}'
    }
  }
  dependsOn: [
    concat(vmName_var, i)
  ]
}]