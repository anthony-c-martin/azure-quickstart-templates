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
  maxLength: 57
  metadata: {
    description: 'String used as a base for naming resources. Must be 3-57 characters in length and globally unique across Azure. A hash is prepended to this string for some resources, and resource-specific information is appended.'
  }
}
param instanceCount int {
  maxValue: 1000
  metadata: {
    description: 'Number of VM instances (1000 or less).'
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

var namingInfix = toLower(substring(concat(vmssName, uniqueString(resourceGroup().id)), 0, 9))
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.8.0/21'
var virtualNetworkName = '${namingInfix}vnet'
var subnetName = '${namingInfix}subnet'
var nicName = '${namingInfix}nic'
var ipConfigName = '${namingInfix}ipconfig'
var imageReference = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: windowsOSVersion
  version: 'latest'
}
var appGwPublicIPAddressName = '${namingInfix}appGwPip'
var appGwName = '${namingInfix}appGw'
var appGwPublicIPAddressID = appGwPublicIPAddressName_resource.id
var appGwID = appGwName_resource.id
var appGwSubnetName = '${namingInfix}appGwSubnet'
var appGwSubnetPrefix = '10.0.1.0/24'
var appGwSubnetID = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, appGwSubnetName)
var appGwFrontendPort = 80
var appGwBackendPort = 80
var appGwBePoolName = '${namingInfix}appGwBepool'

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2016-03-30' = {
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
      {
        name: appGwSubnetName
        properties: {
          addressPrefix: appGwSubnetPrefix
        }
      }
    ]
  }
}

resource appGwPublicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: appGwPublicIPAddressName
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource appGwName_resource 'Microsoft.Network/applicationGateways@2016-03-30' = {
  name: appGwName
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'Standard_Large'
      tier: 'Standard'
      capacity: '10'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGwIpConfig'
        properties: {
          subnet: {
            id: appGwSubnetID
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwFrontendIP'
        properties: {
          PublicIPAddress: {
            id: appGwPublicIPAddressID
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGwFrontendPort'
        properties: {
          Port: appGwFrontendPort
        }
      }
    ]
    backendAddressPools: [
      {
        name: appGwBePoolName
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGwBackendHttpSettings'
        properties: {
          Port: appGwBackendPort
          Protocol: 'Http'
          CookieBasedAffinity: 'Disabled'
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGwHttpListener'
        properties: {
          FrontendIPConfiguration: {
            Id: '${appGwID}/frontendIPConfigurations/appGwFrontendIP'
          }
          FrontendPort: {
            Id: '${appGwID}/frontendPorts/appGwFrontendPort'
          }
          Protocol: 'Http'
          SslCertificate: null
        }
      }
    ]
    requestRoutingRules: [
      {
        Name: 'rule1'
        properties: {
          RuleType: 'Basic'
          httpListener: {
            id: '${appGwID}/httpListeners/appGwHttpListener'
          }
          backendAddressPool: {
            id: '${appGwID}/backendAddressPools/${appGwBePoolName}'
          }
          backendHttpSettings: {
            id: '${appGwID}/backendHttpSettingsCollection/appGwBackendHttpSettings'
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
    appGwPublicIPAddressName_resource
  ]
}

resource namingInfix_resource 'Microsoft.Compute/virtualMachineScaleSets@2016-04-30-preview' = {
  name: namingInfix
  location: resourceGroup().location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    overprovision: 'true'
    singlePlacementGroup: 'false'
    upgradePolicy: {
      mode: 'Automatic'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          caching: 'ReadWrite'
          createOption: 'FromImage'
        }
        dataDisks: []
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
                      id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName}/subnets/${subnetName}'
                    }
                    ApplicationGatewayBackendAddressPools: [
                      {
                        id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${appGwName}/backendAddressPools/${appGwBePoolName}'
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
    virtualNetworkName_resource
    appGwName_resource
  ]
}