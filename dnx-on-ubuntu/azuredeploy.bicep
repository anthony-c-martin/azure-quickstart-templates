@description('The admin username for the Ubuntu machine')
param vmAdminUsername string

@description('The name of the Ubuntu machine')
param vmName string = 'dnx-on-ubuntu'

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

var prefix = 'dnx-on-ubuntu'
var nicName_var = '${prefix}-nic'
var nsgName_var = '${prefix}-nsg'
var pipName_var = '${prefix}-pip'
var vnetName_var = '${prefix}-vnet'
var storageAccountDiagnostics_var = '${uniqueString(resourceGroup().id)}diagsa'
var storageAccountVms_var = '${uniqueString(resourceGroup().id)}vmsa'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${vmAdminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS2'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '14.04.4-LTS'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}_OSDisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
      }
      dataDisks: []
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUsername
      secrets: []
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
        }
      ]
    }
  }
  dependsOn: [
    storageAccountVms
  ]
}

resource vmName_installcustomscript 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  parent: vmName_resource
  name: 'installcustomscript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/dnx-on-ubuntu/scripts/post_deployment.sh'
      ]
      commandToExecute: '/bin/bash post_deployment.sh ${vmAdminUsername}'
    }
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: '10.2.0.4'
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipName.id
          }
          subnet: {
            id: '${vnetName.id}/subnets/default'
          }
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableIPForwarding: false
    networkSecurityGroup: {
      id: nsgName.id
    }
  }
}

resource nsgName 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: nsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-ssh'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
  dependsOn: []
}

resource pipName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: pipName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    idleTimeoutInMinutes: 4
  }
  dependsOn: []
}

resource vnetName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: vnetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.2.0.0/24'
        }
      }
    ]
  }
  dependsOn: []
}

resource storageAccountDiagnostics 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageAccountDiagnostics_var
  location: location
  tags: {}
  properties: {
    accountType: 'Standard_LRS'
  }
  dependsOn: []
}

resource storageAccountVms 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageAccountVms_var
  location: location
  tags: {}
  properties: {
    accountType: 'Premium_LRS'
  }
  dependsOn: []
}