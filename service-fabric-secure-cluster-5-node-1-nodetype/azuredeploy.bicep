param location string {
  metadata: {
    description: 'Location of the Cluster'
  }
  default: resourceGroup().location
}
param clusterName string {
  metadata: {
    description: 'Name of your cluster - Between 3 and 23 characters. Letters and numbers only'
  }
}
param adminUsername string {
  metadata: {
    description: 'Remote desktop user Id'
  }
}
param adminPassword string {
  metadata: {
    description: 'Remote desktop user password. Must be a strong password'
  }
  secure: true
}
param vmImagePublisher string {
  metadata: {
    description: 'VM image Publisher'
  }
  default: 'MicrosoftWindowsServer'
}
param vmImageOffer string {
  metadata: {
    description: 'VM image offer'
  }
  default: 'WindowsServer'
}
param vmImageSku string {
  metadata: {
    description: 'VM image SKU'
  }
  default: '2019-Datacenter'
}
param vmImageVersion string {
  metadata: {
    description: 'VM image version'
  }
  default: 'latest'
}
param loadBalancedAppPort1 int {
  metadata: {
    description: 'Input endpoint1 for the application to use. Replace it with what your application uses'
  }
  default: 80
}
param loadBalancedAppPort2 int {
  metadata: {
    description: 'Input endpoint2 for the application to use. Replace it with what your application uses'
  }
  default: 8081
}
param certificateStoreValue string {
  allowed: [
    'My'
  ]
  metadata: {
    description: 'The store name where the cert will be deployed in the virtual machine'
  }
  default: 'My'
}
param certificateThumbprint string {
  metadata: {
    description: 'Certificate Thumbprint'
  }
}
param sourceVaultResourceId string {
  metadata: {
    description: 'Resource Id of the key vault, is should be in the format of /subscriptions/<Sub ID>/resourceGroups/<Resource group name>/providers/Microsoft.KeyVault/vaults/<vault name>'
  }
}
param certificateUrlValue string {
  metadata: {
    description: 'Refers to the location URL in your key vault where the certificate was uploaded'
  }
}
param clusterProtectionLevel string {
  allowed: [
    'None'
    'Sign'
    'EncryptAndSign'
  ]
  metadata: {
    description: 'Protection level.Three values are allowed - EncryptAndSign, Sign, None. It is best to keep the default of EncryptAndSign, unless you have a need not to'
  }
  default: 'EncryptAndSign'
}
param nt0InstanceCount int {
  metadata: {
    description: 'Instance count for node type'
  }
  default: 5
}
param nodeDataDrive string {
  allowed: [
    'OS'
    'Temp'
  ]
  metadata: {
    description: 'The drive to use to store data on a cluster node.'
  }
  default: 'Temp'
}
param nodeTypeSize string {
  metadata: {
    description: 'The VM size to use for cluster nodes.'
  }
  default: 'Standard_D2_v2'
}

var dnsName = clusterName
var vmName = 'vm'
var virtualNetworkName_var = 'VNet'
var addressPrefix = '10.0.0.0/16'
var nicName = 'NIC'
var lbIPName_var = 'PublicIP-LB-FE'
var overProvision = false
var nt0applicationStartPort = '20000'
var nt0applicationEndPort = '30000'
var nt0ephemeralStartPort = '49152'
var nt0ephemeralEndPort = '65534'
var nt0fabricTcpGatewayPort = '19000'
var nt0fabricHttpGatewayPort = '19080'
var subnet0Name = 'Subnet-0'
var subnet0Prefix = '10.0.0.0/24'
var subnet0Ref = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName_var, subnet0Name)
var supportLogStorageAccountName_var = '${uniqueString(resourceGroup().id)}2'
var applicationDiagnosticsStorageAccountName_var = '${uniqueString(resourceGroup().id)}3'
var lbName_var = 'LB-${clusterName}-${vmNodeType0Name_var}'
var lbIPConfig0 = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations/', lbName_var, 'LoadBalancerIPConfig')
var lbPoolID0 = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName_var, 'LoadBalancerBEAddressPool')
var lbProbeID0 = resourceId('Microsoft.Network/loadBalancers/probes', lbName_var, 'FabricGatewayProbe')
var lbHttpProbeID0 = resourceId('Microsoft.Network/loadBalancers/probes', lbName_var, 'FabricHttpGatewayProbe')
var lbNatPoolID0 = resourceId('Microsoft.Network/loadBalancers/inboundNatPools', lbName_var, 'LoadBalancerBEAddressNatPool')
var vmNodeType0Name_var = toLower('NT1${vmName}')
var vmNodeType0Size = nodeTypeSize

resource supportLogStorageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: supportLogStorageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
  properties: {}
}

resource applicationDiagnosticsStorageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: applicationDiagnosticsStorageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
  properties: {}
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName_var
  location: location
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnet0Name
        properties: {
          addressPrefix: subnet0Prefix
        }
      }
    ]
  }
}

resource lbIPName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: lbIPName_var
  location: location
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
  properties: {
    dnsSettings: {
      domainNameLabel: dnsName
    }
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource lbName 'Microsoft.Network/loadBalancers@2020-05-01' = {
  name: lbName_var
  location: location
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerIPConfig'
        properties: {
          publicIPAddress: {
            id: lbIPName.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'LoadBalancerBEAddressPool'
        properties: {}
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRule'
        properties: {
          backendAddressPool: {
            id: lbPoolID0
          }
          backendPort: nt0fabricTcpGatewayPort
          enableFloatingIP: false
          frontendIPConfiguration: {
            id: lbIPConfig0
          }
          frontendPort: nt0fabricTcpGatewayPort
          idleTimeoutInMinutes: 5
          probe: {
            id: lbProbeID0
          }
          protocol: 'Tcp'
        }
      }
      {
        name: 'LBHttpRule'
        properties: {
          backendAddressPool: {
            id: lbPoolID0
          }
          backendPort: nt0fabricHttpGatewayPort
          enableFloatingIP: false
          frontendIPConfiguration: {
            id: lbIPConfig0
          }
          frontendPort: nt0fabricHttpGatewayPort
          idleTimeoutInMinutes: 5
          probe: {
            id: lbHttpProbeID0
          }
          protocol: 'Tcp'
        }
      }
      {
        name: 'AppPortLBRule1'
        properties: {
          backendAddressPool: {
            id: lbPoolID0
          }
          backendPort: loadBalancedAppPort1
          enableFloatingIP: false
          frontendIPConfiguration: {
            id: lbIPConfig0
          }
          frontendPort: loadBalancedAppPort1
          idleTimeoutInMinutes: 5
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName_var, 'AppPortProbe1')
          }
          protocol: 'Tcp'
        }
      }
      {
        name: 'AppPortLBRule2'
        properties: {
          backendAddressPool: {
            id: lbPoolID0
          }
          backendPort: loadBalancedAppPort2
          enableFloatingIP: false
          frontendIPConfiguration: {
            id: lbIPConfig0
          }
          frontendPort: loadBalancedAppPort2
          idleTimeoutInMinutes: 5
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName_var, 'AppPortProbe2')
          }
          protocol: 'Tcp'
        }
      }
    ]
    probes: [
      {
        name: 'FabricGatewayProbe'
        properties: {
          intervalInSeconds: 5
          numberOfProbes: 2
          port: nt0fabricTcpGatewayPort
          protocol: 'Tcp'
        }
      }
      {
        name: 'FabricHttpGatewayProbe'
        properties: {
          intervalInSeconds: 5
          numberOfProbes: 2
          port: nt0fabricHttpGatewayPort
          protocol: 'Tcp'
        }
      }
      {
        name: 'AppPortProbe1'
        properties: {
          intervalInSeconds: 5
          numberOfProbes: 2
          port: loadBalancedAppPort1
          protocol: 'Tcp'
        }
      }
      {
        name: 'AppPortProbe2'
        properties: {
          intervalInSeconds: 5
          numberOfProbes: 2
          port: loadBalancedAppPort2
          protocol: 'Tcp'
        }
      }
    ]
    inboundNatPools: [
      {
        name: 'LoadBalancerBEAddressNatPool'
        properties: {
          backendPort: 3389
          frontendIPConfiguration: {
            id: lbIPConfig0
          }
          frontendPortRangeEnd: 4500
          frontendPortRangeStart: 3389
          protocol: 'Tcp'
        }
      }
    ]
  }
}

resource vmNodeType0Name 'Microsoft.Compute/virtualMachineScaleSets@2020-06-01' = {
  name: vmNodeType0Name_var
  location: location
  sku: {
    name: vmNodeType0Size
    capacity: nt0InstanceCount
    tier: 'Standard'
  }
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
  properties: {
    overprovision: overProvision
    upgradePolicy: {
      mode: 'Automatic'
    }
    virtualMachineProfile: {
      extensionProfile: {
        extensions: [
          {
            name: 'ServiceFabricNodeVmExt_vmNodeType0Name'
            properties: {
              type: 'ServiceFabricNode'
              autoUpgradeMinorVersion: true
              protectedSettings: {
                StorageAccountKey1: listKeys(supportLogStorageAccountName.id, '2015-05-01-preview').key1
                StorageAccountKey2: listKeys(supportLogStorageAccountName.id, '2015-05-01-preview').key2
              }
              publisher: 'Microsoft.Azure.ServiceFabric'
              settings: {
                clusterEndpoint: reference(clusterName).clusterEndpoint
                nodeTypeRef: vmNodeType0Name_var
                dataPath: '${((nodeDataDrive == 'OS') ? 'C' : 'D')}:\\\\SvcFab'
                durabilityLevel: 'Silver'
                nicPrefixOverride: subnet0Prefix
                certificate: {
                  thumbprint: certificateThumbprint
                  x509StoreName: certificateStoreValue
                }
              }
              typeHandlerVersion: '1.0'
            }
          }
          {
            name: 'VMDiagnosticsVmExt_vmNodeType0Name'
            properties: {
              type: 'IaaSDiagnostics'
              autoUpgradeMinorVersion: true
              protectedSettings: {
                storageAccountName: applicationDiagnosticsStorageAccountName_var
                storageAccountKey: listKeys(applicationDiagnosticsStorageAccountName.id, '2015-05-01-preview').key1
                storageAccountEndPoint: 'https://${environment().suffixes.storage}'
              }
              publisher: 'Microsoft.Azure.Diagnostics'
              settings: {
                WadCfg: {
                  DiagnosticMonitorConfiguration: {
                    overallQuotaInMB: '50000'
                    EtwProviders: {
                      EtwEventSourceProviderConfiguration: [
                        {
                          provider: 'Microsoft-ServiceFabric-Actors'
                          scheduledTransferKeywordFilter: '1'
                          scheduledTransferPeriod: 'PT5M'
                          DefaultEvents: {
                            eventDestination: 'ServiceFabricReliableActorEventTable'
                          }
                        }
                        {
                          provider: 'Microsoft-ServiceFabric-Services'
                          scheduledTransferPeriod: 'PT5M'
                          DefaultEvents: {
                            eventDestination: 'ServiceFabricReliableServiceEventTable'
                          }
                        }
                      ]
                      EtwManifestProviderConfiguration: [
                        {
                          provider: 'cbd93bc2-71e5-4566-b3a7-595d8eeca6e8'
                          scheduledTransferLogLevelFilter: 'Information'
                          scheduledTransferKeywordFilter: '4611686018427387904'
                          scheduledTransferPeriod: 'PT5M'
                          DefaultEvents: {
                            eventDestination: 'ServiceFabricSystemEventTable'
                          }
                        }
                      ]
                    }
                  }
                }
                StorageAccount: applicationDiagnosticsStorageAccountName_var
              }
              typeHandlerVersion: '1.5'
            }
          }
        ]
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${nicName}-0'
            properties: {
              ipConfigurations: [
                {
                  name: '${nicName}-0'
                  properties: {
                    loadBalancerBackendAddressPools: [
                      {
                        id: lbPoolID0
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: lbNatPoolID0
                      }
                    ]
                    subnet: {
                      id: subnet0Ref
                    }
                  }
                }
              ]
              primary: true
            }
          }
        ]
      }
      osProfile: {
        adminPassword: adminPassword
        adminUsername: adminUsername
        computerNamePrefix: vmNodeType0Name_var
        secrets: [
          {
            sourceVault: {
              id: sourceVaultResourceId
            }
            vaultCertificates: [
              {
                certificateStore: certificateStoreValue
                certificateUrl: certificateUrlValue
              }
            ]
          }
        ]
      }
      storageProfile: {
        imageReference: {
          publisher: vmImagePublisher
          offer: vmImageOffer
          sku: vmImageSku
          version: vmImageVersion
        }
        osDisk: {
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
          caching: 'ReadOnly'
          createOption: 'FromImage'
        }
      }
    }
  }
}

resource clusterName_res 'Microsoft.ServiceFabric/clusters@2019-03-01' = {
  name: clusterName
  location: location
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
  properties: {
    certificate: {
      thumbprint: certificateThumbprint
      x509StoreName: certificateStoreValue
    }
    clusterState: 'Default'
    diagnosticsStorageAccountConfig: {
      blobEndpoint: reference(supportLogStorageAccountName.id, '2018-07-01').primaryEndpoints.blob
      protectedAccountKeyName: 'StorageAccountKey1'
      queueEndpoint: reference(supportLogStorageAccountName.id, '2018-07-01').primaryEndpoints.queue
      storageAccountName: supportLogStorageAccountName_var
      tableEndpoint: reference(supportLogStorageAccountName.id, '2018-07-01').primaryEndpoints.table
    }
    fabricSettings: [
      {
        parameters: [
          {
            name: 'ClusterProtectionLevel'
            value: clusterProtectionLevel
          }
        ]
        name: 'Security'
      }
    ]
    managementEndpoint: 'https://${reference(lbIPName_var).dnsSettings.fqdn}:${nt0fabricHttpGatewayPort}'
    nodeTypes: [
      {
        name: vmNodeType0Name_var
        applicationPorts: {
          endPort: nt0applicationEndPort
          startPort: nt0applicationStartPort
        }
        clientConnectionEndpointPort: nt0fabricTcpGatewayPort
        durabilityLevel: 'Silver'
        ephemeralPorts: {
          endPort: nt0ephemeralEndPort
          startPort: nt0ephemeralStartPort
        }
        httpGatewayEndpointPort: nt0fabricHttpGatewayPort
        isPrimary: true
        vmInstanceCount: nt0InstanceCount
      }
    ]
    provisioningState: 'Default'
    reliabilityLevel: 'Silver'
    upgradeMode: 'Automatic'
    vmImage: 'Windows'
  }
}

output clusterProperties object = reference(clusterName)