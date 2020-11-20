param vmSku string {
  metadata: {
    description: 'Size of VMs in the VM Scale Set.'
  }
  default: 'Standard_DS1_v2'
}
param imagePublisher string = 'Canonical'
param imageOffer string = 'UbuntuServer'
param imageSku string = '18.04-LTS'
param imageOSVersion string = 'latest'
param vmssName string {
  maxLength: 61
  metadata: {
    description: 'String used as a base for naming resources. Must be 3-61 characters in length and globally unique across Azure. A hash is prepended to this string for some resources, and resource-specific information is appended.'
  }
}
param instanceCount int {
  minValue: 2
  maxValue: 100
  metadata: {
    description: 'Number of VM instances (100 or less).'
  }
  default: 2
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
param healthProbePort int {
  metadata: {
    description: 'Local http port on VM at which health extension to probe'
  }
  default: 80
}
param healthProbeProtocol string {
  metadata: {
    description: 'Protocol used by health extension to probe app health'
  }
  default: 'http'
}
param location string {
  metadata: {
    description: 'Location for the VM scale set'
  }
  default: resourceGroup().location
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located including a trailing \'/\''
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vmss-automatic-repairs-slb-health-probe/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.'
  }
  secure: true
  default: ''
}

var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var namingInfix = toLower(substring(concat(vmssName, uniqueString(resourceGroup().id)), 0, 9))
var virtualNetworkName_var = '${namingInfix}vnet'
var lbName_var = '${namingInfix}lb'
var bepoolName = '${lbName_var}bepool'
var fepoolName = '${lbName_var}fepool'
var feIpConfigName = '${fepoolName}IpConfig'
var probeName = '${lbName_var}probe'
var bepoolID = resourceId('Microsoft.Network/loadBalancers/backendAddressPools/', lbName_var, bepoolName)
var feIpConfigId = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations/', lbName_var, feIpConfigName)
var platformImageReference = {
  publisher: imagePublisher
  offer: imageOffer
  sku: imageSku
  version: imageOSVersion
}
var imageReference = platformImageReference

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2019-12-01' = {
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

resource lbName 'Microsoft.Network/loadBalancers@2019-12-01' = {
  name: lbName_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: feIpConfigName
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: bepoolName
      }
    ]
    loadBalancingRules: [
      {
        name: 'ProbeRule'
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
            id: resourceId('Microsoft.Network/loadBalancers/probes/', lbName_var, probeName)
          }
        }
      }
    ]
    probes: [
      {
        name: probeName
        properties: {
          protocol: healthProbeProtocol
          port: healthProbePort
          requestPath: '/'
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource vmssName_res 'Microsoft.Compute/virtualMachineScaleSets@2019-03-01' = {
  name: vmssName
  location: location
  tags: {
    vmsstag: 'automaticrepairs'
  }
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    upgradePolicy: {
      mode: 'Manual'
    }
    automaticRepairsPolicy: {
      enabled: true
      gracePeriod: 'PT30M'
    }
    virtualMachineProfile: {
      storageProfile: {
        imageReference: imageReference
      }
      osProfile: {
        computerNamePrefix: 'vmss'
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      extensionProfile: {
        extensions: [
          {
            name: 'CustomScriptToInstallApache'
            properties: {
              publisher: 'Microsoft.Azure.Extensions'
              type: 'CustomScript'
              typeHandlerVersion: '2.0'
              autoUpgradeMinorVersion: true
              settings: {
                fileUris: [
                  uri(artifactsLocation, 'install_apache.sh${artifactsLocationSasToken}')
                ]
                commandToExecute: 'sh install_apache.sh'
              }
            }
          }
        ]
      }
      networkProfile: {
        healthProbe: {
          id: resourceId('Microsoft.Network/loadBalancers/probes/', lbName_var, probeName)
        }
        networkInterfaceConfigurations: [
          {
            name: 'nic1'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ip1'
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: bepoolID
                      }
                    ]
                    publicIPAddressConfiguration: {
                      name: 'pub1'
                      properties: {
                        idleTimeoutInMinutes: 15
                      }
                    }
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
    lbName
    virtualNetworkName
  ]
}