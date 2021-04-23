@description('VNet name')
param vnetName string = 'aci-vnet'

@description('Address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet prefix for ACI')
param subnet1AddressPrefix string = '10.0.0.0/24'

@description('Subnet name for ACI')
param subnet1Name string = 'aci-subnet'

@description('Subnet prefix for application gateway')
param subnet2AddressPrefix string = '10.0.1.0/24'

@description('Subnet name for application gateway')
param subnet2Name string = 'ag-subnet'

@description('MySQL database password')
@secure()
param mysqlPassword string

@description('Location for all resources.')
param location string = resourceGroup().location

var storageAccountName_var = uniqueString(resourceGroup().id)
var storageAccountType = 'Standard_LRS'
var publicIPAddressName_var = 'publicIp1'
var publicIPRef = publicIPAddressName.id
var networkProfileName_var = 'aci-networkProfile'
var interfaceConfigName = 'eth0'
var interfaceIpConfig = 'ipconfigprofile1'
var image = 'microsoft/azure-cli'
var shareContainerGroupName_var = 'createshare-containerinstance'
var wordpressContainerGroupName_var = 'wordpress-containerinstance'
var mysqlContainerGroupName_var = 'mysql-containerinstance'
var wordpressShareName = 'wordpress-share'
var mysqlShareName = 'mysql-share'
var port = 80
var cpuCores = '1.0'
var memoryInGb = '1.5'
var skuName = 'Standard_Medium'
var capacity = '2'
var applicationGatewayName_var = 'applicationGateway1'
var subnet2Ref = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnet2Name)
var wordpressContainerGroupRef = wordpressContainerGroupName.id
var mysqlContainerGroupRef = mysqlContainerGroupName.id

resource storageAccountName 'Microsoft.Storage/storageAccounts@2017-10-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {}
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2018-07-01' = {
  name: publicIPAddressName_var
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

resource networkProfileName 'Microsoft.Network/networkProfiles@2018-07-01' = {
  name: networkProfileName_var
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

resource shareContainerGroupName 'Microsoft.ContainerInstance/containerGroups@2018-07-01' = {
  name: shareContainerGroupName_var
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
              value: listKeys(storageAccountName_var, '2017-10-01').keys[0].value
            }
            {
              name: 'AZURE_STORAGE_ACCOUNT'
              value: storageAccountName_var
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
              value: listKeys(storageAccountName_var, '2017-10-01').keys[0].value
            }
            {
              name: 'AZURE_STORAGE_ACCOUNT'
              value: storageAccountName_var
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
    storageAccountName
  ]
}

resource mysqlContainerGroupName 'Microsoft.ContainerInstance/containerGroups@2018-07-01' = {
  name: mysqlContainerGroupName_var
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
          storageAccountKey: listKeys(storageAccountName_var, '2017-10-01').keys[0].value
          storageAccountName: storageAccountName_var
        }
        name: 'mysqlfile'
      }
    ]
    networkProfile: {
      Id: networkProfileName.id
    }
    osType: 'Linux'
  }
  dependsOn: [
    shareContainerGroupName
  ]
}

resource wordpressContainerGroupName 'Microsoft.ContainerInstance/containerGroups@2018-07-01' = {
  name: wordpressContainerGroupName_var
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
          storageAccountKey: listKeys(storageAccountName_var, '2017-10-01').keys[0].value
          storageAccountName: storageAccountName_var
        }
        name: 'wordpressfile'
      }
    ]
    networkProfile: {
      Id: networkProfileName.id
    }
    osType: 'Linux'
  }
  dependsOn: [
    shareContainerGroupName
  ]
}

resource applicationGatewayName 'Microsoft.Network/applicationGateways@2017-06-01' = {
  name: applicationGatewayName_var
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
          publicIPAddress: {
            id: publicIPRef
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: reference(wordpressContainerGroupRef).ipAddress.ip
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName_var, 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName_var, 'appGatewayFrontendPort')
          }
          protocol: 'Http'
          sslCertificate: null
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName_var, 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName_var, 'appGatewayBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName_var, 'appGatewayBackendHttpSettings')
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetName_resource
  ]
}

output SiteFQDN string = reference(publicIPRef).dnsSettings.fqdn