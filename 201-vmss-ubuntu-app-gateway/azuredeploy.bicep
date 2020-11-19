param vmSku string {
  metadata: {
    description: 'Size of VMs in the VM Scale Set.'
  }
  default: 'Standard_A1'
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

var namingInfix_var = toLower(substring(concat(vmssName, uniqueString(resourceGroup().id)), 0, 9))
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.8.0/21'
var virtualNetworkName_var = '${namingInfix_var}vnet'
var subnetName = '${namingInfix_var}subnet'
var nicName = '${namingInfix_var}nic'
var ipConfigName = '${namingInfix_var}ipconfig'
var imageReference = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: '16.04-LTS'
  version: 'latest'
}
var appGwPublicIPAddressName_var = '${namingInfix_var}appGwPip'
var appGwName_var = '${namingInfix_var}appGw'
var appGwPublicIPAddressID = appGwPublicIPAddressName.id
var appGwID = appGwName.id
var appGwSubnetName = '${namingInfix_var}appGwSubnet'
var appGwSubnetPrefix = '10.0.1.0/24'
var appGwSubnetID = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, appGwSubnetName)
var appGwFrontendPort = 80
var appGwBackendPort = 80
var appGwBePoolName = '${namingInfix_var}appGwBepool'
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
      {
        name: appGwSubnetName
        properties: {
          addressPrefix: appGwSubnetPrefix
        }
      }
    ]
  }
}

resource appGwPublicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-04-01' = {
  name: appGwPublicIPAddressName_var
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource appGwName 'Microsoft.Network/applicationGateways@2017-04-01' = {
  name: appGwName_var
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
        computerNamePrefix: namingInfix_var
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
                      id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName_var}/subnets/${subnetName}'
                    }
                    applicationGatewayBackendAddressPools: [
                      {
                        id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${appGwName_var}/backendAddressPools/${appGwBePoolName}'
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
}