param vmSku string {
  metadata: {
    description: 'Size of VMs in the VM Scale Set.'
  }
  default: 'Standard_A1'
}
param ubuntuOSVersion string {
  allowed: [
    '14.04.4-LTS'
    '16.04-LTS'
  ]
  metadata: {
    description: 'The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version. Allowed values are: 15.10, 14.04.4-LTS.'
  }
  default: '16.04-LTS'
}
param vmssName string {
  maxLength: 61
  metadata: {
    description: 'String used as a base for naming resources. Must be 3-61 characters in length and globally unique across Azure. A hash is prepended to this string for some resources, and resource-specific information is appended.'
  }
}
param instanceCount int {
  maxValue: 100
  metadata: {
    description: 'Number of VM instances (100 or less).'
  }
}
param adminUsername string {
  metadata: {
    description: 'Admin username on all VMs.'
  }
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

var namingInfix = toLower(substring(concat(vmssName, uniqueString(resourceGroup().id)), 0, 9))
var longNamingInfix = toLower(vmssName)
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName = '${namingInfix}vnet'
var publicIPAddressName = '${namingInfix}pip'
var subnetName = '${namingInfix}subnet'
var loadBalancerName = '${namingInfix}lb'
var publicIPAddressID = publicIPAddressName_resource.id
var lbID = loadBalancerName_resource.id
var natPoolName = '${namingInfix}natpool'
var bePoolName = '${namingInfix}bepool'
var natStartPort = 50000
var natEndPort = 50119
var natBackendPort = 22
var nicName = '${namingInfix}nic'
var ipConfigName = '${namingInfix}ipconfig'
var frontEndIPConfigID = '${lbID}/frontendIPConfigurations/loadBalancerFrontEnd'
var osType = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: ubuntuOSVersion
  version: 'latest'
}
var imageReference = osType
var computeApiVersion = '2017-03-30'
var networkApiVersion = '2017-04-01'
var storageApiVersion = '2015-06-15'
var insightsApiVersion = '2015-04-01'
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

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2017-04-01' = {
  name: virtualNetworkName
  location: resourceGroup().location
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

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2017-04-01' = {
  name: publicIPAddressName
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: longNamingInfix
    }
  }
}

resource loadBalancerName_resource 'Microsoft.Network/loadBalancers@2017-04-01' = {
  name: loadBalancerName
  location: resourceGroup().location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: publicIPAddressID
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: bePoolName
      }
    ]
    inboundNatPools: [
      {
        name: natPoolName
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPortRangeStart: natStartPort
          frontendPortRangeEnd: natEndPort
          backendPort: natBackendPort
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
  ]
}

resource namingInfix_resource 'Microsoft.Compute/virtualMachineScaleSets@2017-03-30' = {
  name: namingInfix
  location: resourceGroup().location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    overprovision: 'true'
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
        }
        imageReference: imageReference
      }
      osProfile: {
        computerNamePrefix: namingInfix
        adminUsername: adminUsername
        adminPassword: adminPasswordOrKey
        linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: nicName
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: ipConfigName
                  properties: {
                    subnet: {
                      id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName}/subnets/${subnetName}'
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${loadBalancerName}/backendAddressPools/${bePoolName}'
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${loadBalancerName}/inboundNatPools/${natPoolName}'
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    loadBalancerName_resource
    virtualNetworkName_resource
  ]
}

resource autoscalewad 'Microsoft.Insights/autoscaleSettings@2015-04-01' = {
  name: 'autoscalewad'
  location: resourceGroup().location
  properties: {
    name: 'autoscalewad'
    targetResourceUri: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachineScaleSets/${namingInfix}'
    enabled: true
    profiles: [
      {
        name: 'Profile1'
        capacity: {
          minimum: '1'
          maximum: '10'
          default: '1'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: ''
              metricResourceUri: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachineScaleSets/${namingInfix}'
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 60
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT1M'
            }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: ''
              metricResourceUri: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachineScaleSets/${namingInfix}'
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
  dependsOn: [
    namingInfix_resource
  ]
}