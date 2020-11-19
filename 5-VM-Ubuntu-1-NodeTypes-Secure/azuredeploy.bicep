param clusterLocation string {
  metadata: {
    description: 'Location of the Cluster'
  }
  default: resourceGroup().location
}
param clusterName string {
  metadata: {
    description: 'Name of your cluster - Between 3 and 23 characters. Letters and numbers only'
  }
  default: 'sf-${uniqueString(resourceGroup().id)}'
}
param adminUserName string {
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
  default: 'Canonical'
}
param vmImageOffer string {
  metadata: {
    description: 'VM image offer'
  }
  default: 'UbuntuServer'
}
param vmImageSku string {
  metadata: {
    description: 'VM image SKU'
  }
  default: '16.04-LTS'
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
param sourceVaultValue string {
  metadata: {
    description: 'Resource Id of the key vault, is should be in the format of /subscriptions/<Sub ID>/resourceGroups/<Resource group name>/providers/Microsoft.KeyVault/vaults/<vault name>'
  }
}
param certificateUrlValue string {
  metadata: {
    description: 'Refers to the location URL in your key vault where the certificate was uploaded, it is should be in the format of https://<name of the vault>.vault.azure.net:443/secrets/<exact location>'
  }
}
param storageAccountType string {
  allowed: [
    'Standard_LRS'
    'Standard_GRS'
  ]
  metadata: {
    description: 'Replication option for the VM image storage account'
  }
  default: 'Standard_LRS'
}
param supportLogStorageAccountType string {
  allowed: [
    'Standard_LRS'
    'Standard_GRS'
  ]
  metadata: {
    description: 'Replication option for the support log storage account'
  }
  default: 'Standard_LRS'
}
param applicationDiagnosticsStorageAccountType string {
  allowed: [
    'Standard_LRS'
    'Standard_GRS'
  ]
  metadata: {
    description: 'Replication option for the application diagnostics storage account'
  }
  default: 'Standard_LRS'
}
param nt0InstanceCount int {
  metadata: {
    description: 'Instance count for node type'
  }
  default: 5
}
param vmNodeType0Size string {
  metadata: {
    description: 'VM Type'
  }
  default: 'Standard_D2_v2'
}

var computeLocation = clusterLocation
var dnsName = clusterName
var vmName = 'vm'
var virtualNetworkName_var = 'VNet'
var addressPrefix = '10.0.0.0/16'
var nicName = 'NIC'
var lbName = 'LoadBalancer'
var lbIPName = 'PublicIP-LB-FE'
var overProvision = 'false'
var nt0applicationStartPort = '20000'
var nt0applicationEndPort = '30000'
var nt0ephemeralStartPort = '49152'
var nt0ephemeralEndPort = '65534'
var nt0fabricTcpGatewayPort = '19000'
var nt0fabricHttpGatewayPort = '19080'
var subnet0Name = 'Subnet-0'
var subnet0Prefix = '10.0.0.0/24'
var subnet0Ref = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName_var, subnet0Name)
var supportLogStorageAccountName_var = toLower('${uniqueString(resourceGroup().id)}2')
var applicationDiagnosticsStorageAccountName_var = toLower('wad${uniqueString(resourceGroup().id)}3')
var wadlogs = '<WadCfg><DiagnosticMonitorConfiguration>'
var wadperfcounters1 = '<PerformanceCounters scheduledTransferPeriod="PT1M"><PerformanceCounterConfiguration counterSpecifier="\\Memory\\AvailableMemory" sampleRate="PT15S" unit="Bytes"><annotation displayName="Memory available" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Memory\\PercentAvailableMemory" sampleRate="PT15S" unit="Percent"><annotation displayName="Mem. percent available" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Memory\\UsedMemory" sampleRate="PT15S" unit="Bytes"><annotation displayName="Memory used" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Memory\\PercentUsedMemory" sampleRate="PT15S" unit="Percent"><annotation displayName="Memory percentage" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Memory\\PercentUsedByCache" sampleRate="PT15S" unit="Percent"><annotation displayName="Mem. used by cache" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Processor\\PercentIdleTime" sampleRate="PT15S" unit="Percent"><annotation displayName="CPU idle time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Processor\\PercentUserTime" sampleRate="PT15S" unit="Percent"><annotation displayName="CPU user time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Processor\\PercentProcessorTime" sampleRate="PT15S" unit="Percent"><annotation displayName="CPU percentage guest OS" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\Processor\\PercentIOWaitTime" sampleRate="PT15S" unit="Percent"><annotation displayName="CPU IO wait time" locale="en-us"/></PerformanceCounterConfiguration>'
var wadperfcounters2 = '<PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\BytesPerSecond" sampleRate="PT15S" unit="BytesPerSecond"><annotation displayName="Disk total bytes" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\ReadBytesPerSecond" sampleRate="PT15S" unit="BytesPerSecond"><annotation displayName="Disk read guest OS" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\WriteBytesPerSecond" sampleRate="PT15S" unit="BytesPerSecond"><annotation displayName="Disk write guest OS" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\TransfersPerSecond" sampleRate="PT15S" unit="CountPerSecond"><annotation displayName="Disk transfers" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\ReadsPerSecond" sampleRate="PT15S" unit="CountPerSecond"><annotation displayName="Disk reads" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\WritesPerSecond" sampleRate="PT15S" unit="CountPerSecond"><annotation displayName="Disk writes" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\AverageReadTime" sampleRate="PT15S" unit="Seconds"><annotation displayName="Disk read time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\AverageWriteTime" sampleRate="PT15S" unit="Seconds"><annotation displayName="Disk write time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\AverageTransferTime" sampleRate="PT15S" unit="Seconds"><annotation displayName="Disk transfer time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\\PhysicalDisk\\AverageDiskQueueLength" sampleRate="PT15S" unit="Count"><annotation displayName="Disk queue length" locale="en-us"/></PerformanceCounterConfiguration></PerformanceCounters>'
var wadcfgxstart = '${wadlogs}${wadperfcounters1}${wadperfcounters2}<Metrics resourceId="'
var wadcfgxend = '"><MetricAggregation scheduledTransferPeriod="PT1H"/><MetricAggregation scheduledTransferPeriod="PT1M"/></Metrics></DiagnosticMonitorConfiguration></WadCfg>'
var lbID0 = LB_clusterName_vmNodeType0Name.id
var lbIPConfig0 = '${lbID0}/frontendIPConfigurations/LoadBalancerIPConfig'
var lbPoolID0 = '${lbID0}/backendAddressPools/LoadBalancerBEAddressPool'
var lbProbeID0 = '${lbID0}/probes/FabricGatewayProbe'
var lbHttpProbeID0 = '${lbID0}/probes/FabricHttpGatewayProbe'
var lbNatPoolID0 = '${lbID0}/inboundNatPools/LoadBalancerBEAddressNatPool'
var vmNodeType0Name_var = toLower('NT1${vmName}')
var wadmetricsresourceid0 = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachineScaleSets/${vmNodeType0Name_var}'

resource supportLogStorageAccountName 'Microsoft.Storage/storageAccounts@2017-06-01' = {
  name: supportLogStorageAccountName_var
  location: computeLocation
  properties: {}
  kind: 'Storage'
  sku: {
    name: supportLogStorageAccountType
  }
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
  dependsOn: []
}

resource applicationDiagnosticsStorageAccountName 'Microsoft.Storage/storageAccounts@2017-06-01' = {
  name: applicationDiagnosticsStorageAccountName_var
  location: computeLocation
  properties: {}
  kind: 'Storage'
  sku: {
    name: applicationDiagnosticsStorageAccountType
  }
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
  dependsOn: []
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2017-09-01' = {
  name: virtualNetworkName_var
  location: computeLocation
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
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
  dependsOn: []
}

resource lbIPName_vmNodeType0Name 'Microsoft.Network/publicIPAddresses@2017-09-01' = {
  name: '${lbIPName}-${vmNodeType0Name_var}'
  location: computeLocation
  properties: {
    dnsSettings: {
      domainNameLabel: dnsName
    }
    publicIPAllocationMethod: 'Dynamic'
  }
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
}

resource LB_clusterName_vmNodeType0Name 'Microsoft.Network/loadBalancers@2017-09-01' = {
  name: 'LB-${clusterName}-${vmNodeType0Name_var}'
  location: computeLocation
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerIPConfig'
        properties: {
          publicIPAddress: {
            id: lbIPName_vmNodeType0Name.id
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
          enableFloatingIP: 'false'
          frontendIPConfiguration: {
            id: lbIPConfig0
          }
          frontendPort: nt0fabricTcpGatewayPort
          idleTimeoutInMinutes: '5'
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
          enableFloatingIP: 'false'
          frontendIPConfiguration: {
            id: lbIPConfig0
          }
          frontendPort: nt0fabricHttpGatewayPort
          idleTimeoutInMinutes: '5'
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
          enableFloatingIP: 'false'
          frontendIPConfiguration: {
            id: lbIPConfig0
          }
          frontendPort: loadBalancedAppPort1
          idleTimeoutInMinutes: '5'
          probe: {
            id: '${lbID0}/probes/AppPortProbe1'
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
          enableFloatingIP: 'false'
          frontendIPConfiguration: {
            id: lbIPConfig0
          }
          frontendPort: loadBalancedAppPort2
          idleTimeoutInMinutes: '5'
          probe: {
            id: '${lbID0}/probes/AppPortProbe2'
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
          backendPort: '22'
          frontendIPConfiguration: {
            id: lbIPConfig0
          }
          frontendPortRangeEnd: '4500'
          frontendPortRangeStart: '3389'
          protocol: 'Tcp'
        }
      }
    ]
  }
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
}

resource vmNodeType0Name 'Microsoft.Compute/virtualMachineScaleSets@2017-03-30' = {
  name: vmNodeType0Name_var
  location: computeLocation
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
              type: 'ServiceFabricLinuxNode'
              autoUpgradeMinorVersion: true
              protectedSettings: {
                StorageAccountKey1: listKeys(supportLogStorageAccountName.id, '2017-06-01').keys[0]
                StorageAccountKey2: listKeys(supportLogStorageAccountName.id, '2017-06-01').keys[1]
              }
              publisher: 'Microsoft.Azure.ServiceFabric'
              settings: {
                clusterEndpoint: reference(clusterName).clusterEndpoint
                nodeTypeRef: vmNodeType0Name_var
                durabilityLevel: 'Bronze'
                enableParallelJobs: true
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
              type: 'LinuxDiagnostic'
              autoUpgradeMinorVersion: true
              protectedSettings: {
                storageAccountName: applicationDiagnosticsStorageAccountName_var
                storageAccountKey: listKeys(applicationDiagnosticsStorageAccountName.id, '2017-06-01').keys[0]
                storageAccountEndPoint: 'https://core.windows.net/'
              }
              publisher: 'Microsoft.OSTCExtensions'
              settings: {
                xmlCfg: base64(concat(wadcfgxstart, wadmetricsresourceid0, wadcfgxend))
                StorageAccount: applicationDiagnosticsStorageAccountName_var
              }
              typeHandlerVersion: '2.3'
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
        adminUsername: adminUserName
        computerNamePrefix: vmNodeType0Name_var
        secrets: [
          {
            sourceVault: {
              id: sourceVaultValue
            }
            vaultCertificates: [
              {
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
          caching: 'ReadOnly'
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: storageAccountType
          }
        }
      }
    }
  }
  sku: {
    name: vmNodeType0Size
    capacity: nt0InstanceCount
    tier: 'Standard'
  }
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
  dependsOn: [
    'Microsoft.Network/loadBalancers/LB-${clusterName}-${vmNodeType0Name_var}'
  ]
}

resource clusterName_res 'Microsoft.ServiceFabric/clusters@2017-07-01-preview' = {
  name: clusterName
  location: clusterLocation
  properties: {
    addOnFeatures: [
      'DnsService'
      'RepairManager'
    ]
    certificate: {
      thumbprint: certificateThumbprint
      x509StoreName: certificateStoreValue
    }
    clusterState: 'Default'
    diagnosticsStorageAccountConfig: {
      blobEndpoint: reference('Microsoft.Storage/storageAccounts/${supportLogStorageAccountName_var}', '2017-06-01').primaryEndpoints.blob
      protectedAccountKeyName: 'StorageAccountKey1'
      queueEndpoint: reference('Microsoft.Storage/storageAccounts/${supportLogStorageAccountName_var}', '2017-06-01').primaryEndpoints.queue
      storageAccountName: supportLogStorageAccountName_var
      tableEndpoint: reference('Microsoft.Storage/storageAccounts/${supportLogStorageAccountName_var}', '2017-06-01').primaryEndpoints.table
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
    managementEndpoint: 'https://${reference('${lbIPName}-${vmNodeType0Name_var}').dnsSettings.fqdn}:${nt0fabricHttpGatewayPort}'
    nodeTypes: [
      {
        name: vmNodeType0Name_var
        applicationPorts: {
          endPort: nt0applicationEndPort
          startPort: nt0applicationStartPort
        }
        clientConnectionEndpointPort: nt0fabricTcpGatewayPort
        durabilityLevel: 'Bronze'
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
    vmImage: 'Linux'
  }
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
}

output clusterProperties object = reference(clusterName)