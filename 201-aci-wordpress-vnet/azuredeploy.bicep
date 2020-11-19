param vnetName string {
  metadata: {
    description: 'VNet name'
  }
  default: 'aci-vnet'
}
param vnetAddressPrefix string {
  metadata: {
    description: 'Address prefix'
  }
  default: '10.0.0.0/16'
}
param subnet1AddressPrefix string {
  metadata: {
    description: 'Subnet prefix for ACI'
  }
  default: '10.0.0.0/24'
}
param subnet1Name string {
  metadata: {
    description: 'Subnet name for ACI'
  }
  default: 'aci-subnet'
}
param subnet2AddressPrefix string {
  metadata: {
    description: 'Subnet prefix for application gateway'
  }
  default: '10.0.1.0/24'
}
param subnet2Name string {
  metadata: {
    description: 'Subnet name for application gateway'
  }
  default: 'ag-subnet'
}
param mysqlPassword string {
  metadata: {
    description: 'MySQL database password'
  }
  secure: true
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var storageAccountName = uniqueString(resourceGroup().id)
var storageAccountType = 'Standard_LRS'
var publicIPAddressName = 'publicIp1'
var publicIPRef = publicIPAddressName_resource.id
var networkProfileName = 'aci-networkProfile'
var interfaceConfigName = 'eth0'
var interfaceIpConfig = 'ipconfigprofile1'
var image = 'microsoft/azure-cli'
var shareContainerGroupName = 'createshare-containerinstance'
var wordpressContainerGroupName = 'wordpress-containerinstance'
var mysqlContainerGroupName = 'mysql-containerinstance'
var wordpressShareName = 'wordpress-share'
var mysqlShareName = 'mysql-share'
var port = 80
var cpuCores = '1.0'
var memoryInGb = '1.5'
var skuName = 'Standard_Medium'
var capacity = '2'
var applicationGatewayName = 'applicationGateway1'
var subnet2Ref = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnet2Name)
var wordpressContainerGroupRef = wordpressContainerGroupName_resource.id
var mysqlContainerGroupRef = mysqlContainerGroupName_resource.id

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2017-10-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2018-07-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: 'acisite${uniqueString(resourceGroup().id)}'
    }
  }
}

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2018-07-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1AddressPrefix
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: [
                location
              ]
            }
          ]
          delegations: [
            {
              name: 'DelegationService'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2AddressPrefix
        }
      }
    ]
  }
}

resource networkProfileName_resource 'Microsoft.Network/networkProfiles@2018-07-01' = {
  name: networkProfileName
  location: location
  properties: {
    containerNetworkInterfaceConfigurations: [
      {
        name: interfaceConfigName
        properties: {
          ipConfigurations: [
            {
              name: interfaceIpConfig
              properties: {
                subnet: {
                  id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnet1Name)
                }
              }
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    vnetName_resource
  ]
}

resource shareContainerGroupName_resource 'Microsoft.ContainerInstance/containerGroups@2018-07-01' = {
  name: shareContainerGroupName
  location: location
  properties: {
    containers: [
      {
        name: wordpressShareName
        properties: {
          image: image
          command: [
            'az'
            'storage'
            'share'
            'create'
            '--name'
            wordpressShareName
          ]
          environmentVariables: [
            {
              name: 'AZURE_STORAGE_KEY'
              value: listKeys(storageAccountName, '2017-10-01').keys[0].value
            }
            {
              name: 'AZURE_STORAGE_ACCOUNT'
              value: storageAccountName
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGb: memoryInGb
            }
          }
        }
      }
      {
        name: mysqlShareName
        properties: {
          image: image
          command: [
            'az'
            'storage'
            'share'
            'create'
            '--name'
            mysqlShareName
          ]
          environmentVariables: [
            {
              name: 'AZURE_STORAGE_KEY'
              value: listKeys(storageAccountName, '2017-10-01').keys[0].value
            }
            {
              name: 'AZURE_STORAGE_ACCOUNT'
              value: storageAccountName
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGb: memoryInGb
            }
          }
        }
      }
    ]
    restartPolicy: 'OnFailure'
    osType: 'Linux'
  }
  dependsOn: [
    storageAccountName_resource
  ]
}

resource mysqlContainerGroupName_resource 'Microsoft.ContainerInstance/containerGroups@2018-07-01' = {
  name: mysqlContainerGroupName
  location: location
  properties: {
    containers: [
      {
        name: 'mysql'
        properties: {
          image: 'mysql:5.6'
          ports: [
            {
              protocol: 'Tcp'
              port: 3306
            }
          ]
          environmentVariables: [
            {
              name: 'MYSQL_ROOT_PASSWORD'
              value: mysqlPassword
            }
          ]
          volumeMounts: [
            {
              mountPath: '/var/lib/mysql'
              name: 'mysqlfile'
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGb: memoryInGb
            }
          }
        }
      }
    ]
    volumes: [
      {
        azureFile: {
          shareName: mysqlShareName
          storageAccountKey: listKeys(storageAccountName, '2017-10-01').keys[0].value
          storageAccountName: storageAccountName
        }
        name: 'mysqlfile'
      }
    ]
    networkProfile: {
      Id: networkProfileName_resource.id
    }
    osType: 'Linux'
  }
  dependsOn: [
    shareContainerGroupName_resource
    networkProfileName_resource
  ]
}

resource wordpressContainerGroupName_resource 'Microsoft.ContainerInstance/containerGroups@2018-07-01' = {
  name: wordpressContainerGroupName
  location: location
  properties: {
    containers: [
      {
        name: 'wordpress'
        properties: {
          image: 'wordpress:4.9-apache'
          ports: [
            {
              protocol: 'Tcp'
              port: 80
            }
          ]
          environmentVariables: [
            {
              name: 'WORDPRESS_DB_HOST'
              value: '${reference(mysqlContainerGroupRef).ipAddress.ip}:3306'
            }
            {
              name: 'WORDPRESS_DB_PASSWORD'
              value: mysqlPassword
            }
          ]
          volumeMounts: [
            {
              mountPath: '/var/www/html'
              name: 'wordpressfile'
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGb: memoryInGb
            }
          }
        }
      }
    ]
    volumes: [
      {
        azureFile: {
          shareName: wordpressShareName
          storageAccountKey: listKeys(storageAccountName, '2017-10-01').keys[0].value
          storageAccountName: storageAccountName
        }
        name: 'wordpressfile'
      }
    ]
    networkProfile: {
      Id: networkProfileName_resource.id
    }
    osType: 'Linux'
  }
  dependsOn: [
    shareContainerGroupName_resource
    mysqlContainerGroupName_resource
  ]
}

resource applicationGatewayName_resource 'Microsoft.Network/applicationGateways@2017-06-01' = {
  name: applicationGatewayName
  location: location
  properties: {
    sku: {
      name: skuName
      tier: 'Standard'
      capacity: capacity
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnet2Ref
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          PublicIPAddress: {
            id: publicIPRef
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          Port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          BackendAddresses: [
            {
              IpAddress: reference(wordpressContainerGroupRef).ipAddress.ip
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          Port: 80
          Protocol: 'Http'
          CookieBasedAffinity: 'Disabled'
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          FrontendIPConfiguration: {
            Id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'appGatewayFrontendIP')
          }
          FrontendPort: {
            Id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'appGatewayFrontendPort')
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
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'appGatewayBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'appGatewayBackendHttpSettings')
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetName_resource
    publicIPAddressName_resource
    wordpressContainerGroupName_resource
  ]
}

output SiteFQDN string = reference(publicIPRef).dnsSettings.fqdn