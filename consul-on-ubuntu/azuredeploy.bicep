@description('Admin username for VM')
param adminUsername string

@allowed([
  'Standard_A1'
  'Standard_A2'
  'Standard_A3'
  'Standard_D1_v2'
  'Standard_D2_v2'
  'Standard_D3_v2'
])
@description('Size of the Virtual Machine.')
param vmSize string = 'Standard_A1'

@maxLength(11)
@description('Prefix for each component (VMs, networks, etc)')
param appPrefix string

@description('Your existing access token from Atlas')
param existingAtlasToken string

@description('The name of your existing infrastructure in Atlas (username/infraName)')
param existingAtlasInfraName string

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

var imagePublisher = 'Canonical'
var vnetID = resourceId('Microsoft.Network/virtualNetworks', vnetIDRef)
var subnet1Name = 'Subnet-1'
var customScriptFilePath = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/consul-on-ubuntu/install-consul.sh'
var addressPrefix = '10.0.0.0/16'
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var numberOfInstances = 3
var customScriptCommandToExecute = 'bash install-consul.sh'
var subnet1Prefix = '10.0.0.0/24'
var publicIPAddressType = 'Dynamic'
var imageSKU = '14.04.5-LTS'
var vnetIDRef = '${appPrefix}_VNET'
var imageOffer = 'UbuntuServer'
var storageAccountName_var = concat(uniqueString(resourceGroup().id), appPrefix)
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

resource storageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  properties: {
    accountType: 'Standard_LRS'
  }
  location: location
  name: storageAccountName_var
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2015-06-15' = [for i in range(0, numberOfInstances): {
  name: 'publicIP${i}'
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
  }
}]

resource appPrefix_AS 'Microsoft.Compute/availabilitySets@2017-12-01' = {
  location: location
  name: '${appPrefix}_AS'
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
}

resource appPrefix_SG 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  properties: {
    securityRules: [
      {
        name: 'ssh_rule'
        properties: {
          priority: 100
          direction: 'Inbound'
          protocol: 'Tcp'
          description: 'Allow external SSH'
          access: 'Allow'
          destinationPortRange: '22'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          sourceAddressPrefix: 'Internet'
        }
      }
    ]
  }
  location: location
  name: '${appPrefix}_SG'
}

resource appPrefix_VNET 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: '${appPrefix}_VNET'
  location: location
  properties: {
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
        }
      }
    ]
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
  }
  dependsOn: [
    'Microsoft.Network/networkSecurityGroups/${appPrefix}_SG'
  ]
}

resource appPrefix_LB 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: '${appPrefix}_LB'
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'loadBalancerFrontEnd'
        properties: {
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'lbrule'
        properties: {
          frontendIPConfiguration: {
            id: '${appPrefix_LB.id}/frontendIpConfigurations/loadBalancerFrontEnd'
          }
          backendPort: 8500
          probe: {
            id: '${appPrefix_LB.id}/probes/lbprobe'
          }
          protocol: 'Tcp'
          backendAddressPool: {
            id: '${appPrefix_LB.id}/backendAddressPools/loadBalancerBackEnd'
          }
          frontendPort: 8500
          idleTimeoutInMinutes: 15
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'loadBalancerBackEnd'
      }
    ]
    probes: [
      {
        name: 'lbprobe'
        properties: {
          protocol: 'Tcp'
          numberOfProbes: 2
          intervalInSeconds: 15
          port: 8500
        }
      }
    ]
  }
  dependsOn: [
    'Microsoft.Network/virtualNetworks/${appPrefix}_VNET'
  ]
}

resource appPrefix_nic1 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, numberOfInstances): {
  name: '${appPrefix}_nic1${i}'
  location: location
  properties: {
    networkSecurityGroup: {
      id: appPrefix_SG.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet1Ref
          }
          privateIPAllocationMethod: 'Dynamic'
          loadBalancerBackendAddressPools: [
            {
              id: '${appPrefix_LB.id}/backendAddressPools/loadBalancerBackEnd'
            }
          ]
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIpAddresses', 'publicIP${i}')
          }
        }
      }
    ]
  }
  dependsOn: [
    'Microsoft.Network/publicIPAddresses/publicIP${i}'
    'Microsoft.Network/virtualNetworks/${appPrefix}_VNET'
    'Microsoft.Network/loadBalancers/${appPrefix}_LB'
  ]
}]

resource appPrefix_vm 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, numberOfInstances): {
  name: '${appPrefix}_vm${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      adminUsername: adminUsername
      computerName: 'vm${i}'
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    availabilitySet: {
      id: appPrefix_AS.id
    }
    storageProfile: {
      imageReference: {
        sku: imageSKU
        publisher: imagePublisher
        version: 'latest'
        offer: imageOffer
      }
      osDisk: {
        caching: 'ReadWrite'
        name: '${appPrefix}_vm${i}_OSDisk'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${appPrefix}_nic1${i}')
          properties: {
            primary: true
          }
        }
      ]
    }
  }
  dependsOn: [
    'Microsoft.Network/networkInterfaces/${appPrefix}_nic1${i}'
    storageAccountName
    'Microsoft.Compute/availabilitySets/${appPrefix}_AS'
  ]
}]

resource appPrefix_vm_extension 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, numberOfInstances): {
  name: '${appPrefix}_vm${i}/extension'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        customScriptFilePath
      ]
    }
    protectedSettings: {
      commandToExecute: '${customScriptCommandToExecute} ${existingAtlasInfraName} ${existingAtlasToken}'
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${appPrefix}_vm${i}'
  ]
}]