param vmSku string {
  metadata: {
    description: 'Size of VMs in the VM Scale Set.'
  }
  default: 'Standard_D2s_v3'
}
param vmssName string {
  minLength: 3
  maxLength: 61
  metadata: {
    description: 'String used as a base for naming resources. Must be 3-61 characters in length and globally unique across Azure. A hash is prepended to this string for some resources, and resource-specific information is appended.'
  }
}
param capacity int {
  minValue: 1
  maxValue: 20
  metadata: {
    description: 'Number of VM instances (20 or less).'
  }
  default: 2
}
param adminUsername string {
  metadata: {
    description: 'Admin username on all VMs.'
  }
}
param adminPassword string {
  minLength: 12
  metadata: {
    description: 'Admin password on all VMs. It must be at least 12 characters in length.'
  }
  secure: true
}
param sourceImageVhdUri string {
  metadata: {
    description: 'The source of the blob containing the custom image, must be in the same region of the deployment.'
  }
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vmss-linux-customimage-autoscale/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var vmssuniqueName = toLower(take(concat(take(vmssName, 6), uniqueString(resourceGroup().id)), 9))
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName = '${vmssuniqueName}vnet'
var subnetName = '${vmssuniqueName}subnet'
var lbName = '${vmssuniqueName}lb'
var bepoolName = '${lbName}bepool'
var fepoolName = '${lbName}fepool'
var bepoolID = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, bepoolName)
var feIpConfigName = '${fepoolName}IpConfig'
var feIpConfigId = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName, feIpConfigName)
var pipName = '${vmssuniqueName}pip'
var nicName = '${vmssuniqueName}nic'
var natPoolName = '${lbName}natpool'
var ipConfigName = '${vmssuniqueName}ipconfig'
var httpProbeName = 'httpProbe'
var httpsProbeName = 'httpsProbe'
var imageName = 'myCustomImage'

resource imageName_resource 'Microsoft.Compute/images@2020-06-01' = {
  name: imageName
  location: location
  properties: {
    hyperVGeneration: 'V1'
    storageProfile: {
      osDisk: {
        osType: 'Linux'
        osState: 'Generalized'
        blobUri: sourceImageVhdUri
        storageAccountType: 'Standard_LRS'
      }
    }
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
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
        }
      }
    ]
  }
}

resource pipName_resource 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: pipName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: vmssuniqueName
    }
  }
}

resource lbName_resource 'Microsoft.Network/loadBalancers@2020-06-01' = {
  name: lbName
  location: location
  tags: {
    displayName: 'Load Balancer'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: feIpConfigName
        properties: {
          publicIPAddress: {
            id: pipName_resource.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: bepoolName
      }
    ]
    inboundNatPools: [
      {
        name: natPoolName
        properties: {
          frontendIPConfiguration: {
            id: feIpConfigId
          }
          protocol: 'Tcp'
          frontendPortRangeStart: 10022
          frontendPortRangeEnd: 11022
          backendPort: 22
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'HTTPRule'
        properties: {
          loadDistribution: 'Default'
          frontendIPConfiguration: {
            id: feIpConfigId
          }
          backendAddressPool: {
            id: bepoolID
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName, httpsProbeName)
          }
        }
      }
      {
        name: 'HTTPSRule'
        properties: {
          loadDistribution: 'Default'
          frontendIPConfiguration: {
            id: feIpConfigId
          }
          backendAddressPool: {
            id: bepoolID
          }
          protocol: 'Tcp'
          frontendPort: 443
          backendPort: 443
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName, httpsProbeName)
          }
        }
      }
    ]
    probes: [
      {
        name: httpProbeName
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
      {
        name: httpsProbeName
        properties: {
          protocol: 'Tcp'
          port: 443
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
  dependsOn: [
    pipName_resource
  ]
}

resource vmssuniqueName_resource 'Microsoft.Compute/virtualMachineScaleSets@2020-06-01' = {
  name: vmssuniqueName
  location: location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: capacity
  }
  properties: {
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        imageReference: {
          id: imageName_resource.id
        }
      }
      osProfile: {
        computerNamePrefix: vmssuniqueName
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
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, bepoolName)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', lbName, natPoolName)
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
      extensionProfile: {
        extensions: [
          {
            name: 'updatescriptextension'
            properties: {
              publisher: 'Microsoft.Azure.Extensions'
              type: 'CustomScript'
              typeHandlerVersion: '2.0'
              autoUpgradeMinorVersion: true
              settings: {
                fileUris: [
                  uri(artifactsLocation, 'scripts/updateapp.sh${artifactsLocationSasToken}')
                  uri(artifactsLocation, 'app/package.tar.gz${artifactsLocationSasToken}')
                ]
                commandToExecute: 'sudo bash updateapp.sh "package.tar.gz" /nodeserver mainsite.service'
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    virtualNetworkName_resource
    imageName_resource
  ]
}

resource autoscalesettings 'Microsoft.Insights/autoscaleSettings@2015-04-01' = {
  name: 'autoscalesettings'
  location: location
  properties: {
    name: 'autoscalesettings'
    targetResourceUri: vmssuniqueName_resource.id
    enabled: true
    profiles: [
      {
        name: 'Profile1'
        capacity: {
          minimum: '2'
          maximum: '20'
          default: capacity
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricResourceUri: vmssuniqueName_resource.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: '40'
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
              metricResourceUri: vmssuniqueName_resource.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: '30'
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
    vmssuniqueName_resource
  ]
}

output fqdn string = reference(pipName_resource.id, '2020-06-01').dnsSettings.fqdn