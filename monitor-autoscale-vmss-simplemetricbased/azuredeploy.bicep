param vmSku string {
  metadata: {
    description: 'Size of VMs in the VM Scale Set.'
  }
  default: 'Standard_A1'
}
param windowsOSVersion string {
  allowed: [
    '2012-Datacenter'
    '2012-R2-Datacenter'
    '2016-Datacenter'
    '2016-Datacenter-Server-Core'
    '2016-Datacenter-with-Containers'
  ]
  metadata: {
    description: 'The Windows version for the VM.'
  }
  default: '2016-Datacenter'
}
param vmssName string {
  minLength: 3
  maxLength: 61
  metadata: {
    description: 'String used as a base for naming resources. Must be 3-61 characters in length and globally unique across Azure.'
  }
}
param instanceCount int {
  minValue: 1
  maxValue: 1000
  metadata: {
    description: 'Number of VM instances (1000 or less).'
  }
  default: 2
}
param adminUsername string {
  metadata: {
    description: 'Admin username.'
  }
}
param adminPassword string {
  metadata: {
    description: 'Admin password.'
  }
  secure: true
}
param minimumCapacity int {
  minValue: 1
  maxValue: 1000
  metadata: {
    description: 'The minimum capacity.  Autoscale engine will ensure the instance count is at least this value.'
  }
  default: 2
}
param maximumCapacity int {
  minValue: 1
  maxValue: 1000
  metadata: {
    description: 'The maximum capacity.  Autoscale engine will ensure the instance count is not greater than this value.'
  }
  default: 10
}
param defaultCapacity int {
  minValue: 1
  maxValue: 1000
  metadata: {
    description: 'The default capacity.  Autoscale engine will preventively set the instance count to be this value if it can not find any metric data.'
  }
  default: 10
}
param metricName string {
  metadata: {
    description: 'The metric name.'
  }
  default: 'Percentage CPU'
}
param metricThresholdToScaleOut int {
  metadata: {
    description: 'The metric upper threshold.  If the metric value is above this threshold then autoscale engine will initiate scale out action.'
  }
  default: 60
}
param metricThresholdToScaleIn int {
  metadata: {
    description: 'The metric lower threshold.  If the metric value is below this threshold then autoscale engine will initiate scale in action.'
  }
  default: 20
}
param changePercentScaleOut int {
  metadata: {
    description: 'The percentage to increase the instance count when autoscale engine is initiating scale out action.'
  }
  default: 20
}
param changePercentScaleIn int {
  metadata: {
    description: 'The percentage to decrease the instance count when autoscale engine is initiating scale in action.'
  }
  default: 10
}
param autoscaleEnabled bool {
  metadata: {
    description: 'A boolean to indicate whether the autoscale policy is enabled or disabled.'
  }
}

var settingName = '${toLower(namingInfix)}-setting'
var targetResourceId = namingInfix_resource.id
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
var natBackendPort = 3389
var nicName = '${namingInfix}nic'
var ipConfigName = '${namingInfix}ipconfig'
var frontEndIPConfigID = '${lbID}/frontendIPConfigurations/loadBalancerFrontEnd'
var osType = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: windowsOSVersion
  version: 'latest'
}
var imageReference = osType

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
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, bePoolName)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', loadBalancerName, natPoolName)
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

resource settingName_resource 'Microsoft.Insights/autoscalesettings@2014-04-01' = {
  name: settingName
  location: resourceGroup().location
  properties: {
    profiles: [
      {
        name: 'DefaultAutoscaleProfile'
        capacity: {
          minimum: minimumCapacity
          maximum: maximumCapacity
          default: defaultCapacity
        }
        rules: [
          {
            metricTrigger: {
              metricName: metricName
              metricNamespace: ''
              metricResourceUri: targetResourceId
              timeGrain: 'PT5M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: metricThresholdToScaleOut
            }
            scaleAction: {
              direction: 'Increase'
              type: 'PercentChangeCount'
              value: changePercentScaleOut
              cooldown: 'PT10M'
            }
          }
          {
            metricTrigger: {
              metricName: metricName
              metricNamespace: ''
              metricResourceUri: targetResourceId
              timeGrain: 'PT5M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: metricThresholdToScaleIn
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'PercentChangeCount'
              value: changePercentScaleIn
              cooldown: 'PT10M'
            }
          }
        ]
      }
    ]
    enabled: autoscaleEnabled
    targetResourceUri: targetResourceId
  }
  dependsOn: [
    namingInfix_resource
  ]
}