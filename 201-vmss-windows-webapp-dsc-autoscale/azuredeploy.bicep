param vmSku string {
  metadata: {
    description: 'Size of VMs in the VM Scale Set.'
  }
  default: 'Standard_A1_v2'
}
param windowsOSVersion string {
  allowed: [
    '2008-R2-SP1'
    '2012-Datacenter'
    '2012-R2-Datacenter'
    '2016-Datacenter'
    '2019-Datacenter'
  ]
  metadata: {
    description: 'The Windows version for the VM. This will pick a fully patched image of this given Windows version. Allowed values: 2008-R2-SP1, 2012-Datacenter, 2012-R2-Datacenter & 2016-Datacenter, 2019-Datacenter.'
  }
  default: '2016-Datacenter'
}
param vmssName string {
  minLength: 3
  maxLength: 61
  metadata: {
    description: 'String used as a base for naming resources. Must be 3-61 characters in length and globally unique across Azure. A hash is prepended to this string for some resources, and resource-specific information is appended.'
  }
}
param instanceCount int {
  minValue: 1
  maxValue: 100
  metadata: {
    description: 'Number of VM instances (100 or less).'
  }
  default: 3
}
param singlePlacementGroup bool {
  metadata: {
    description: 'When true this limits the scale set to a single placement group, of max size 100 virtual machines. NOTE: If singlePlacementGroup is true, it may be modified to false. However, if singlePlacementGroup is false, it may not be modified to true.'
  }
  default: true
}
param adminUsername string {
  metadata: {
    description: 'Admin username on all VMs.'
  }
  default: 'vmssadmin'
}
param adminPassword string {
  metadata: {
    description: 'Admin password on all VMs.'
  }
  secure: true
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. For example, if stored on a public GitHub repo, you\'d use the following URI: https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vmss-windows-webapp-dsc-autoscale/.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vmss-windows-webapp-dsc-autoscale/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  If your artifacts are stored on a public repo or public storage account you can leave this blank.'
  }
  secure: true
  default: ''
}
param powershelldscZip string {
  metadata: {
    description: 'Location of the PowerShell DSC zip file relative to the URI specified in the _artifactsLocation, i.e. DSC/IISInstall.ps1.zip'
  }
  default: 'DSC/IISInstall.ps1.zip'
}
param webDeployPackage string {
  metadata: {
    description: 'Location of the  of the WebDeploy package zip file relative to the URI specified in _artifactsLocation, i.e. WebDeploy/DefaultASPWebApp.v1.0.zip'
  }
  default: 'WebDeploy/DefaultASPWebApp.v1.0.zip'
}
param powershelldscUpdateTagVersion string {
  metadata: {
    description: 'Version number of the DSC deployment. Changing this value on subsequent deployments will trigger the extension to run.'
  }
  default: '1.0'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param platformFaultDomainCount int {
  metadata: {
    description: 'Fault Domain count for each placement group.'
  }
  default: 1
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
var lbProbeID = resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName, 'tcpProbe')
var natPoolName = '${namingInfix}natpool'
var bePoolName = '${namingInfix}bepool'
var lbPoolID = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, bePoolName)
var natStartPort = 50000
var natEndPort = 50119
var natBackendPort = 3389
var nicName = '${namingInfix}nic'
var ipConfigName = '${namingInfix}ipconfig'
var frontEndIPConfigID = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, 'loadBalancerFrontEnd')
var osType = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: windowsOSVersion
  version: 'latest'
}
var imageReference = osType
var webDeployPackageFullPath = uri(artifactsLocation, concat(webDeployPackage, artifactsLocationSasToken))
var powershelldscZipFullPath = uri(artifactsLocation, concat(powershelldscZip, artifactsLocationSasToken))

resource loadBalancerName_resource 'Microsoft.Network/loadBalancers@2020-06-01' = {
  name: loadBalancerName
  location: location
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
    loadBalancingRules: [
      {
        name: 'LBRule'
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          backendAddressPool: {
            id: lbPoolID
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: lbProbeID
          }
        }
      }
    ]
    probes: [
      {
        name: 'tcpProbe'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
  ]
}

resource namingInfix_resource 'Microsoft.Compute/virtualMachineScaleSets@2020-06-01' = {
  name: namingInfix
  location: location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    overprovision: true
    upgradePolicy: {
      mode: 'Automatic'
    }
    singlePlacementGroup: singlePlacementGroup
    platformFaultDomainCount: platformFaultDomainCount
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          caching: 'ReadWrite'
          createOption: 'FromImage'
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
                        id: lbPoolID
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
      extensionProfile: {
        extensions: [
          {
            name: 'Microsoft.Powershell.DSC'
            properties: {
              publisher: 'Microsoft.Powershell'
              type: 'DSC'
              typeHandlerVersion: '2.9'
              autoUpgradeMinorVersion: true
              forceUpdateTag: powershelldscUpdateTagVersion
              settings: {
                configuration: {
                  url: powershelldscZipFullPath
                  script: 'IISInstall.ps1'
                  function: 'InstallIIS'
                }
                configurationArguments: {
                  nodeName: 'localhost'
                  WebDeployPackagePath: webDeployPackageFullPath
                }
              }
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

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: longNamingInfix
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

resource autoscalehost 'Microsoft.Insights/autoscaleSettings@2015-04-01' = {
  name: 'autoscalehost'
  location: location
  properties: {
    name: 'autoscalehost'
    targetResourceUri: namingInfix_resource.id
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
              metricResourceUri: namingInfix_resource.id
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
              metricResourceUri: namingInfix_resource.id
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

output applicationUrl string = 'http://${reference(publicIPAddressName).dnsSettings.fqdn}/MyApp'