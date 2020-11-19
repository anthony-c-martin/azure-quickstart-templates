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

var vmssuniqueName_var = toLower(take(concat(take(vmssName, 6), uniqueString(resourceGroup().id)), 9))
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName_var = '${vmssuniqueName_var}vnet'
var subnetName = '${vmssuniqueName_var}subnet'
var lbName_var = '${vmssuniqueName_var}lb'
var bepoolName = '${lbName_var}bepool'
var fepoolName = '${lbName_var}fepool'
var bepoolID = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName_var, bepoolName)
var feIpConfigName = '${fepoolName}IpConfig'
var feIpConfigId = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName_var, feIpConfigName)
var pipName_var = '${vmssuniqueName_var}pip'
var nicName = '${vmssuniqueName_var}nic'
var natPoolName = '${lbName_var}natpool'
var ipConfigName = '${vmssuniqueName_var}ipconfig'
var httpProbeName = 'httpProbe'
var httpsProbeName = 'httpsProbe'
var imageName_var = 'myCustomImage'

resource imageName 'Microsoft.Compute/images@2020-06-01' = {
  name: imageName_var
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

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2020-06-01' = {
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
        }
      }
    ]
  }
}

resource pipName 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: pipName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: vmssuniqueName_var
    }
  }
}

resource lbName 'Microsoft.Network/loadBalancers@2020-06-01' = {
  name: lbName_var
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
            id: pipName.id
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
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName_var, httpsProbeName)
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
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName_var, httpsProbeName)
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
}

resource vmssuniqueName 'Microsoft.Compute/virtualMachineScaleSets@2020-06-01' = {
  name: vmssuniqueName_var
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
          id: imageName.id
        }
      }
      osProfile: {
        computerNamePrefix: vmssuniqueName_var
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
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName_var, bepoolName)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', lbName_var, natPoolName)
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
}

resource autoscalesettings 'Microsoft.Insights/autoscaleSettings@2015-04-01' = {
  name: 'autoscalesettings'
  location: location
  properties: {
    name: 'autoscalesettings'
    targetResourceUri: vmssuniqueName.id
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
              metricResourceUri: vmssuniqueName.id
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
              metricResourceUri: vmssuniqueName.id
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
}

output fqdn string = reference(pipName.id, '2020-06-01').dnsSettings.fqdn