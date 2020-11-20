param vmSku string {
  metadata: {
    description: 'Size of VMs in the VM Scale Set.'
  }
  default: 'Standard_A1'
}
param windowsOSVersion string {
  allowed: [
    '2008-R2-SP1'
    '2012-Datacenter'
    '2012-R2-Datacenter'
  ]
  metadata: {
    description: 'The Windows version for the VM. This will pick a fully patched image of this given Windows version. Allowed values: 2008-R2-SP1, 2012-Datacenter, 2012-R2-Datacenter.'
  }
  default: '2012-R2-Datacenter'
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
param adminPassword string {
  metadata: {
    description: 'Admin password on all VMs.'
  }
  secure: true
}

var namingInfix_var = toLower(substring(concat(vmssName, uniqueString(resourceGroup().id)), 0, 9))
var longNamingInfix = toLower(vmssName)
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName_var = '${namingInfix_var}vnet'
var publicIPAddressName_var = '${namingInfix_var}pip'
var subnetName = '${namingInfix_var}subnet'
var loadBalancerName_var = '${namingInfix_var}lb'
var publicIPAddressID = publicIPAddressName.id
var lbID = loadBalancerName.id
var natPoolName = '${namingInfix_var}natpool'
var bePoolName = '${namingInfix_var}bepool'
var natStartPort = 50000
var natEndPort = 50119
var natBackendPort = 3389
var nicName = '${namingInfix_var}nic'
var ipConfigName = '${namingInfix_var}ipconfig'
var frontEndIPConfigID = '${lbID}/frontendIPConfigurations/loadBalancerFrontEnd'
var osType = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: windowsOSVersion
  version: 'latest'
}
var imageReference = osType
var computeApiVersion = '2017-03-30'
var networkApiVersion = '2017-04-01'
var storageApiVersion = '2015-06-15'
var insightsApiVersion = '2015-04-01'

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2017-04-01' = {
  name: virtualNetworkName_var
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

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-04-01' = {
  name: publicIPAddressName_var
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: longNamingInfix
    }
  }
}

resource loadBalancerName 'Microsoft.Network/loadBalancers@2017-04-01' = {
  name: loadBalancerName_var
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
}

resource namingInfix 'Microsoft.Compute/virtualMachineScaleSets@2017-03-30' = {
  name: namingInfix_var
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
        computerNamePrefix: namingInfix_var
        adminUsername: adminUsername
        adminPassword: adminPassword
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
                      id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName_var}/subnets/${subnetName}'
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${loadBalancerName_var}/backendAddressPools/${bePoolName}'
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/loadBalancers/${loadBalancerName_var}/inboundNatPools/${natPoolName}'
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
    loadBalancerName
    virtualNetworkName
  ]
}

resource cpuautoscale 'Microsoft.Insights/autoscaleSettings@2015-04-01' = {
  name: 'cpuautoscale'
  location: resourceGroup().location
  properties: {
    name: 'cpuautoscale'
    targetResourceUri: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachineScaleSets/${namingInfix_var}'
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
              metricResourceUri: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachineScaleSets/${namingInfix_var}'
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 50
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: ''
              metricResourceUri: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachineScaleSets/${namingInfix_var}'
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
    namingInfix
  ]
}