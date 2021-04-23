@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/couchbase/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Number of Couchbase Servers')
param serverNodeCount int

@description('Size of Disk in GB for each Couchbase Server')
param serverDiskSize int

@description('Number of Couchbase Sync Gateways')
param syncGatewayNodeCount int

@description('Size of VM for Coucbase Server and Sync Gateway')
param vmSize string

@description('Admin Username')
param adminUsername string

@description('Admin Password')
@secure()
param adminPassword string

@description('Location')
param location string = resourceGroup().location

@description('License can be hourly_pricing or byol')
param license string = 'hourly_pricing'

var uniqueString = uniqueString(resourceGroup().id, deployment().name)

resource networksecuritygroups 'Microsoft.Network/networkSecurityGroups@2016-06-01' = {
  name: 'networksecuritygroups'
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          description: 'SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'ErlangPortMapper'
        properties: {
          description: 'Erlang Port Mapper ( epmd )'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '4369'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
      {
        name: 'SyncGateway'
        properties: {
          description: 'Sync Gateway'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '4984-4985'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 102
          direction: 'Inbound'
        }
      }
      {
        name: 'Server'
        properties: {
          description: 'Server'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8091-8094'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 103
          direction: 'Inbound'
        }
      }
      {
        name: 'Index'
        properties: {
          description: 'Index'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9100-9105'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 104
          direction: 'Inbound'
        }
      }
      {
        name: 'Internal'
        properties: {
          description: 'Internal'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9998-9999'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 105
          direction: 'Inbound'
        }
      }
      {
        name: 'XDCR'
        properties: {
          description: 'XDCR'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '11207-11215'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 106
          direction: 'Inbound'
        }
      }
      {
        name: 'SSL'
        properties: {
          description: 'SSL'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '18091-18093'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 107
          direction: 'Inbound'
        }
      }
      {
        name: 'NodeDataExchange'
        properties: {
          description: 'Node data exchange'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '21100-21299'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 108
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: 'vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/8'
      ]
    }
    subnets: [
      {
        name: 'subnet'
        properties: {
          addressPrefix: '10.0.0.0/16'
          networkSecurityGroup: {
            id: networksecuritygroups.id
          }
        }
      }
    ]
  }
}

resource server 'Microsoft.Compute/virtualMachineScaleSets@2017-03-30' = {
  name: 'server'
  location: location
  plan: {
    publisher: 'couchbase'
    product: 'couchbase-server-enterprise'
    name: license
  }
  sku: {
    name: vmSize
    tier: 'Standard'
    capacity: serverNodeCount
  }
  properties: {
    overprovision: false
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
        }
        imageReference: {
          publisher: 'couchbase'
          offer: 'couchbase-server-enterprise'
          sku: license
          version: 'latest'
        }
        dataDisks: [
          {
            lun: 0
            createOption: 'Empty'
            managedDisk: {
              storageAccountType: 'Premium_LRS'
            }
            caching: 'None'
            diskSizeGB: serverDiskSize
          }
        ]
      }
      osProfile: {
        computerNamePrefix: 'server'
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    subnet: {
                      id: '${vnet.id}/subnets/subnet'
                    }
                    publicIPAddressConfiguration: {
                      name: 'public'
                      properties: {
                        idleTimeoutInMinutes: 30
                        dnsSettings: {
                          domainNameLabel: 'server-${uniqueString}'
                        }
                      }
                    }
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
            name: 'extension'
            properties: {
              publisher: 'Microsoft.Azure.Extensions'
              type: 'CustomScript'
              typeHandlerVersion: '2.0'
              autoUpgradeMinorVersion: true
              settings: {
                fileUris: [
                  uri(artifactsLocation, 'scripts/server.sh${artifactsLocationSasToken}')
                  uri(artifactsLocation, 'scripts/util.sh${artifactsLocationSasToken}')
                ]
                commandToExecute: 'bash server.sh ${adminUsername} ${adminPassword} ${uniqueString} ${location}'
              }
            }
          }
        ]
      }
    }
  }
}

resource syncgateway 'Microsoft.Compute/virtualMachineScaleSets@2017-03-30' = {
  name: 'syncgateway'
  location: location
  plan: {
    publisher: 'couchbase'
    product: 'couchbase-sync-gateway-enterprise'
    name: license
  }
  sku: {
    name: vmSize
    tier: 'Standard'
    capacity: syncGatewayNodeCount
  }
  properties: {
    overprovision: false
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
        }
        imageReference: {
          publisher: 'couchbase'
          offer: 'couchbase-sync-gateway-enterprise'
          sku: license
          version: 'latest'
        }
      }
      osProfile: {
        computerNamePrefix: 'syncgateway'
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    subnet: {
                      id: '${vnet.id}/subnets/subnet'
                    }
                    publicIPAddressConfiguration: {
                      name: 'public'
                      properties: {
                        idleTimeoutInMinutes: 30
                        dnsSettings: {
                          domainNameLabel: 'syncgateway-${uniqueString}'
                        }
                      }
                    }
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
            name: 'extension'
            properties: {
              publisher: 'Microsoft.Azure.Extensions'
              type: 'CustomScript'
              typeHandlerVersion: '2.0'
              autoUpgradeMinorVersion: true
              settings: {
                fileUris: [
                  uri(artifactsLocation, 'scripts/syncGateway.sh${artifactsLocationSasToken}')
                  uri(artifactsLocation, 'scripts/util.sh${artifactsLocationSasToken}')
                ]
                commandToExecute: 'bash syncGateway.sh ${uniqueString} ${location}'
              }
            }
          }
        ]
      }
    }
  }
}

output serverAdminURL string = '${reference('/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachineScaleSets/server/virtualMachines/0/networkInterfaces/nic/ipConfigurations/ipconfig/publicIPAddresses/public', '2017-03-30').dnsSettings.fqdn}:8091'
output syncGatewayAdminURL string = '${reference('/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachineScaleSets/syncgateway/virtualMachines/0/networkInterfaces/nic/ipConfigurations/ipconfig/publicIPAddresses/public', '2017-03-30').dnsSettings.fqdn}:4985/_admin/'