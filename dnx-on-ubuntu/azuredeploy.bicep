param vmAdminUsername string {
  metadata: {
    description: 'The admin username for the Ubuntu machine'
  }
}
param vmName string {
  metadata: {
    description: 'The name of the Ubuntu machine'
  }
  default: 'dnx-on-ubuntu'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
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

var prefix = 'dnx-on-ubuntu'
var nicName = '${prefix}-nic'
var nsgName = '${prefix}-nsg'
var pipName = '${prefix}-pip'
var vnetName = '${prefix}-vnet'
var storageAccountDiagnostics = '${uniqueString(resourceGroup().id)}diagsa'
var storageAccountVms = '${uniqueString(resourceGroup().id)}vmsa'
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
          id: nicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    storageAccountVms_resource
    nicName_resource
  ]
}

resource vmName_installcustomscript 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/installcustomscript'
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
  dependsOn: [
    vmName_resource
  ]
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: '10.2.0.4'
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipName_resource.id
          }
          subnet: {
            id: '${vnetName_resource.id}/subnets/default'
          }
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableIPForwarding: false
    networkSecurityGroup: {
      id: nsgName_resource.id
    }
  }
  dependsOn: [
    pipName_resource
    vnetName_resource
    nsgName_resource
  ]
}

resource nsgName_resource 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: nsgName
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

resource pipName_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: pipName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    idleTimeoutInMinutes: 4
  }
  dependsOn: []
}

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: vnetName
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

resource storageAccountDiagnostics_resource 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageAccountDiagnostics
  location: location
  tags: {}
  properties: {
    accountType: 'Standard_LRS'
  }
  dependsOn: []
}

resource storageAccountVms_resource 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageAccountVms
  location: location
  tags: {}
  properties: {
    accountType: 'Premium_LRS'
  }
  dependsOn: []
}