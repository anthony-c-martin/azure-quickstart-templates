param newStorageAccountName string {
  metadata: {
    description: 'Unique DNS Name Prefix for the Storage Account where the Virtual Machine\'s disks will be placed.  StorageAccounts may contain at most variables(\'vmsPerStorageAccount\')'
  }
}
param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine.'
  }
  default: 'azureuser'
}
param dnsNameForPublicIP string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Virtual Machine.'
  }
}
param vmSize string {
  metadata: {
    description: 'The VM role size of the jump box'
  }
  default: 'Standard_D2s_v3'
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

var vmName_var = 'jumpbox'
var availabilitySetNodes_var = 'avail-set'
var osImagePublisher = 'Canonical'
var osImageOffer = 'UbuntuServer'
var osImageSKU = '18.04-LTS'
var publicIPAddressName_var = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var customScriptLocation = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/ubuntu-desktop-gnome/'
var wgetCommandPrefix = 'wget --tries 20 --retry-connrefused --waitretry=15 -qO- ${customScriptLocation}configure-ubuntu.sh | nohup /bin/bash -s '
var wgetCommandPostfix = ' > /var/log/azure/firstinstall.log 2>&1 &\''
var commandPrefix = '/bin/bash -c \''
var virtualNetworkName_var = 'VNET'
var subnetName = 'Subnet'
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var nsgName_var = 'node-nsg'
var nsgID = nsgName.id
var storageAccountType = 'Standard_LRS'
var nodesLbName_var = 'nodeslb'
var nodesLbBackendPoolName = 'node-pool'
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

resource newStorageAccountName_res 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: newStorageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource availabilitySetNodes 'Microsoft.Compute/availabilitySets@2019-12-01' = {
  name: availabilitySetNodes_var
  location: location
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
  sku: {
    name: 'Aligned'
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForPublicIP
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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
            id: nsgID
          }
        }
      }
    ]
  }
  dependsOn: [
    nsgID
  ]
}

resource nsgName 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: nsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'ssh'
        properties: {
          description: 'SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vmName_nic 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: '${vmName_var}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfigNode'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '${split(subnetPrefix, '0/24')[0]}100'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
          }
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', nodesLbName_var, nodesLbBackendPoolName)
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', nodesLbName_var, 'SSH-${vmName_var}')
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    nodesLbName
    virtualNetworkName
  ]
}

resource nodesLbName 'Microsoft.Network/loadBalancers@2020-05-01' = {
  name: nodesLbName_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'NodesLBFrontEnd'
        properties: {
          publicIPAddress: {
            id: publicIPAddressName.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: nodesLbBackendPoolName
      }
    ]
    inboundNatRules: [
      {
        name: 'SSH-${vmName_var}'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', nodesLbName_var, 'NodesLBFrontEnd')
          }
          protocol: 'Tcp'
          frontendPort: 22
          backendPort: 22
          enableFloatingIP: false
        }
      }
    ]
  }
}

resource vmName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName_var
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetNodes.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: osImagePublisher
        offer: osImageOffer
        sku: osImageSKU
        version: 'latest'
      }
      osDisk: {
        name: '${vmName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmName_nic.id
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccountName_res
  ]
}

resource vmName_configuremaster 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${vmName_var}/configuremaster'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: concat(commandPrefix, wgetCommandPrefix, adminUsername, wgetCommandPostfix)
    }
  }
  dependsOn: [
    vmName
  ]
}