@description('Size of VMs in the VM Scale Set.')
param vmSku string = 'Standard_A1'

@allowed([
  '2012-Datacenter'
  '2012-R2-Datacenter'
  '2016-Datacenter'
  '2016-Datacenter-Server-Core'
  '2016-Datacenter-with-Containers'
])
@description('The Windows version for the VM.')
param windowsOSVersion string = '2016-Datacenter'

@minLength(3)
@maxLength(61)
@description('String used as a base for naming resources. Must be 3-61 characters in length and globally unique across Azure.')
param vmssName string

@minValue(1)
@maxValue(1000)
@description('Number of VM instances (1000 or less).')
param instanceCount int = 2

@description('Admin username.')
param adminUsername string

@description('Admin password.')
@secure()
param adminPassword string

@minValue(1)
@maxValue(1000)
@description('The minimum capacity.  Autoscale engine will ensure the instance count is at least this value.')
param minimumCapacity int = 2

@minValue(1)
@maxValue(1000)
@description('The maximum capacity.  Autoscale engine will ensure the instance count is not greater than this value.')
param maximumCapacity int = 10

@minValue(1)
@maxValue(1000)
@description('The default capacity.  Autoscale engine will preventively set the instance count to be this value if it can not find any metric data.')
param defaultCapacity int = 10

@description('The metric name.')
param metricName string = 'Percentage CPU'

@description('The metric upper threshold.  If the metric value is above this threshold then autoscale engine will initiate scale out action.')
param metricThresholdToScaleOut int = 60

@description('The metric lower threshold.  If the metric value is below this threshold then autoscale engine will initiate scale in action.')
param metricThresholdToScaleIn int = 20

@description('The percentage to increase the instance count when autoscale engine is initiating scale out action.')
param changePercentScaleOut int = 20

@description('The percentage to decrease the instance count when autoscale engine is initiating scale in action.')
param changePercentScaleIn int = 10

@description('A boolean to indicate whether the autoscale policy is enabled or disabled.')
param autoscaleEnabled bool

var settingName_var = '${toLower(namingInfix_var)}-setting'
var targetResourceId = namingInfix.id
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
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName_var, bePoolName)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', loadBalancerName_var, natPoolName)
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

resource settingName 'Microsoft.Insights/autoscalesettings@2014-04-01' = {
  name: settingName_var
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
}