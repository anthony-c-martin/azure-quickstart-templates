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
  default: '2016-Datacenter'
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
    description: 'X.509 SHA-1 Certificate Thumbprint'
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
param diskType string {
  allowed: [
    'Standard_LRS'
  ]
  metadata: {
    description: 'Replication option for the VM image disks'
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
param nt0InstanceCount int {
  metadata: {
    description: 'Instance count for node type'
  }
  default: 5
}
param nt1InstanceCount int {
  metadata: {
    description: 'Instance count for node type'
  }
  default: 5
}
param nt2InstanceCount int {
  metadata: {
    description: 'Instance count for node type'
  }
  default: 5
}

var computeLocation = location
var dnsName = toLower(clusterName)
var vmName = 'vm'
var virtualNetworkName_var = 'VNet'
var addressPrefix = '10.0.0.0/16'
var nicName = 'NIC'
var lbIPName = 'PublicIP-LB-FE'
var vnetID = virtualNetworkName.id
var overProvision = 'false'
var nt0applicationStartPort = '20000'
var nt0applicationEndPort = '30000'
var nt0ephemeralStartPort = '49152'
var nt0ephemeralEndPort = '65534'
var nt0fabricTcpGatewayPort = '19000'
var nt0fabricHttpGatewayPort = '19080'
var subnet0Name = 'Subnet-0'
var subnet0Prefix = '10.0.0.0/24'
var subnet0Ref = '${vnetID}/subnets/${subnet0Name}'
var nt1applicationStartPort = '20000'
var nt1applicationEndPort = '30000'
var nt1ephemeralStartPort = '49152'
var nt1ephemeralEndPort = '65534'
var nt1fabricTcpGatewayPort = '19000'
var nt1fabricHttpGatewayPort = '19080'
var subnet1Name = 'Subnet-1'
var subnet1Prefix = '10.0.1.0/24'
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
var nt2applicationStartPort = '20000'
var nt2applicationEndPort = '30000'
var nt2ephemeralStartPort = '49152'
var nt2ephemeralEndPort = '65534'
var nt2fabricTcpGatewayPort = '19000'
var nt2fabricHttpGatewayPort = '19080'
var subnet2Name = 'Subnet-2'
var subnet2Prefix = '10.0.2.0/24'
var subnet2Ref = '${vnetID}/subnets/${subnet2Name}'
var supportLogStorageAccountName_var = toLower('${uniqueString(resourceGroup().id)}2')
var lbID0 = LB_clusterName_vmNodeType0Name.id
var lbIPConfig0 = '${lbID0}/frontendIPConfigurations/LoadBalancerIPConfig'
var lbPoolID0 = '${lbID0}/backendAddressPools/LoadBalancerBEAddressPool'
var lbProbeID0 = '${lbID0}/probes/FabricGatewayProbe'
var lbHttpProbeID0 = '${lbID0}/probes/FabricHttpGatewayProbe'
var lbNatPoolID0 = '${lbID0}/inboundNatPools/LoadBalancerBEAddressNatPool'
var vmNodeType0Name_var = toLower('SF${vmName}')
var vmNodeType0Size = 'Standard_D2_V2'
var lbID1 = LB_clusterName_vmNodeType1Name.id
var lbIPConfig1 = '${lbID1}/frontendIPConfigurations/LoadBalancerIPConfig'
var lbPoolID1 = '${lbID1}/backendAddressPools/LoadBalancerBEAddressPool'
var lbProbeID1 = '${lbID1}/probes/FabricGatewayProbe'
var lbHttpProbeID1 = '${lbID1}/probes/FabricHttpGatewayProbe'
var lbNatPoolID1 = '${lbID1}/inboundNatPools/LoadBalancerBEAddressNatPool'
var vmNodeType1Name_var = toLower('NT1${vmName}')
var vmNodeType1Size = 'Standard_D2_V2'
var lbID2 = LB_clusterName_vmNodeType2Name.id
var lbIPConfig2 = '${lbID2}/frontendIPConfigurations/LoadBalancerIPConfig'
var lbPoolID2 = '${lbID2}/backendAddressPools/LoadBalancerBEAddressPool'
var lbProbeID2 = '${lbID2}/probes/FabricGatewayProbe'
var lbHttpProbeID2 = '${lbID2}/probes/FabricHttpGatewayProbe'
var lbNatPoolID2 = '${lbID2}/inboundNatPools/LoadBalancerBEAddressNatPool'
var vmNodeType2Name_var = toLower('NT2${vmName}')
var vmNodeType2Size = 'Standard_D2_V2'

resource supportLogStorageAccountName 'Microsoft.Storage/storageAccounts@2018-07-01' = {
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

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2018-08-01' = {
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
          networkSecurityGroup: {
            id: nsg_subnet0Name.id
          }
        }
      }
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
          networkSecurityGroup: {
            id: nsg_subnet1Name.id
          }
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Prefix
          networkSecurityGroup: {
            id: nsg_subnet2Name.id
          }
        }
      }
    ]
  }
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
  dependsOn: [
    'Microsoft.Network/networkSecurityGroups/nsg${subnet0Name}'
    'Microsoft.Network/networkSecurityGroups/nsg${subnet1Name}'
    'Microsoft.Network/networkSecurityGroups/nsg${subnet2Name}'
  ]
}

resource lbIPName_0 'Microsoft.Network/publicIPAddresses@2018-08-01' = {
  name: '${lbIPName}-0'
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

resource LB_clusterName_vmNodeType0Name 'Microsoft.Network/loadBalancers@2018-08-01' = {
  name: 'LB-${clusterName}-${vmNodeType0Name_var}'
  location: computeLocation
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerIPConfig'
        properties: {
          publicIPAddress: {
            id: lbIPName_0.id
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
          enableFloatingIP: false
          frontendIPConfiguration: {
            id: lbIPConfig0
          }
          frontendPort: loadBalancedAppPort2
          idleTimeoutInMinutes: 5
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
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
  dependsOn: [
    'Microsoft.Network/publicIPAddresses/${lbIPName}-0'
  ]
}

resource nsg_subnet0Name 'Microsoft.Network/networkSecurityGroups@2018-08-01' = {
  name: 'nsg${subnet0Name}'
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'allowSvcFabSMB'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '445'
          direction: 'Inbound'
          priority: 3950
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          description: 'allow SMB traffic within the net, used by fabric to move packages around'
        }
      }
      {
        name: 'allowSvcFabCluser'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '1025-1027'
          direction: 'Inbound'
          priority: 3920
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          description: 'allow ports within vnet that are used by the fabric to talk between nodes'
        }
      }
      {
        name: 'allowSvcFabEphemeral'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '${nt0ephemeralStartPort}-${nt0ephemeralEndPort}'
          direction: 'Inbound'
          priority: 3930
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          description: 'allow fabric ephemeral ports within the vnet'
        }
      }
      {
        name: 'allowSvcFabPortal'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: nt0fabricHttpGatewayPort
          direction: 'Inbound'
          priority: 3900
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'allow port used to access the fabric cluster web portal'
        }
      }
      {
        name: 'allowSvcFabClient'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: nt0fabricTcpGatewayPort
          direction: 'Inbound'
          priority: 3910
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'allow port used by the fabric client (includes powershell)'
        }
      }
      {
        name: 'allowSvcFabApplication'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '${nt0applicationStartPort}-${nt0applicationEndPort}'
          direction: 'Inbound'
          priority: 3940
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'allow fabric application ports within the vnet'
        }
      }
      {
        name: 'blockAll'
        properties: {
          access: 'Deny'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          direction: 'Inbound'
          priority: 4095
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'block all traffic except what we\'ve explicitly allowed'
        }
      }
      {
        name: 'allowVNetRDP'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389-4500'
          direction: 'Inbound'
          priority: 3960
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'allow RDP within the net'
        }
      }
      {
        name: 'allowAppPort1'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: loadBalancedAppPort1
          direction: 'Inbound'
          priority: 2001
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'allow public application port 1'
        }
      }
      {
        name: 'allowAppPort2'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: loadBalancedAppPort2
          direction: 'Inbound'
          priority: 2002
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'allow public application port 2'
        }
      }
    ]
  }
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
}

resource vmNodeType0Name 'Microsoft.Compute/virtualMachineScaleSets@2018-10-01' = {
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
                dataPath: 'D:\\SvcFab'
                durabilityLevel: 'Bronze'
                nicPrefixOverride: subnet0Prefix
                certificate: {
                  thumbprint: certificateThumbprint
                  x509StoreName: certificateStoreValue
                }
              }
              typeHandlerVersion: '1.0'
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
              id: sourceVaultValue
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
          caching: 'ReadWrite'
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: diskType
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

resource lbIPName_1 'Microsoft.Network/publicIPAddresses@2018-08-01' = {
  name: '${lbIPName}-1'
  location: computeLocation
  properties: {
    dnsSettings: {
      domainNameLabel: '${dnsName}-web'
    }
    publicIPAllocationMethod: 'Dynamic'
  }
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
}

resource LB_clusterName_vmNodeType1Name 'Microsoft.Network/loadBalancers@2018-08-01' = {
  name: 'LB-${clusterName}-${vmNodeType1Name_var}'
  location: computeLocation
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerIPConfig'
        properties: {
          publicIPAddress: {
            id: lbIPName_1.id
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
            id: lbPoolID1
          }
          backendPort: nt1fabricTcpGatewayPort
          enableFloatingIP: false
          frontendIPConfiguration: {
            id: lbIPConfig1
          }
          frontendPort: nt1fabricTcpGatewayPort
          idleTimeoutInMinutes: 5
          probe: {
            id: lbProbeID1
          }
          protocol: 'Tcp'
        }
      }
      {
        name: 'LBHttpRule'
        properties: {
          backendAddressPool: {
            id: lbPoolID1
          }
          backendPort: nt1fabricHttpGatewayPort
          enableFloatingIP: false
          frontendIPConfiguration: {
            id: lbIPConfig1
          }
          frontendPort: nt1fabricHttpGatewayPort
          idleTimeoutInMinutes: 5
          probe: {
            id: lbHttpProbeID1
          }
          protocol: 'Tcp'
        }
      }
      {
        name: 'AppPortLBRule1'
        properties: {
          backendAddressPool: {
            id: lbPoolID1
          }
          backendPort: loadBalancedAppPort1
          enableFloatingIP: false
          frontendIPConfiguration: {
            id: lbIPConfig1
          }
          frontendPort: loadBalancedAppPort1
          idleTimeoutInMinutes: 5
          probe: {
            id: '${lbID1}/probes/AppPortProbe1'
          }
          protocol: 'Tcp'
        }
      }
      {
        name: 'AppPortLBRule2'
        properties: {
          backendAddressPool: {
            id: lbPoolID1
          }
          backendPort: loadBalancedAppPort2
          enableFloatingIP: false
          frontendIPConfiguration: {
            id: lbIPConfig1
          }
          frontendPort: loadBalancedAppPort2
          idleTimeoutInMinutes: 5
          probe: {
            id: '${lbID1}/probes/AppPortProbe2'
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
          port: nt1fabricTcpGatewayPort
          protocol: 'Tcp'
        }
      }
      {
        name: 'FabricHttpGatewayProbe'
        properties: {
          intervalInSeconds: 5
          numberOfProbes: 2
          port: nt1fabricHttpGatewayPort
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
            id: lbIPConfig1
          }
          frontendPortRangeEnd: 4500
          frontendPortRangeStart: 3389
          protocol: 'Tcp'
        }
      }
    ]
  }
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
  dependsOn: [
    'Microsoft.Network/publicIPAddresses/${lbIPName}-1'
  ]
}

resource nsg_subnet1Name 'Microsoft.Network/networkSecurityGroups@2018-08-01' = {
  name: 'nsg${subnet1Name}'
  location: computeLocation
  properties: {
    securityRules: [
      {
        name: 'allowSvcFabSMB'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '445'
          direction: 'Inbound'
          priority: 3950
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          description: 'allow SMB traffic within the net, used by fabric to move packages around'
        }
      }
      {
        name: 'allowSvcFabCluser'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '1025-1027'
          direction: 'Inbound'
          priority: 3920
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          description: 'allow ports within vnet that are used by the fabric to talk between nodes'
        }
      }
      {
        name: 'allowSvcFabEphemeral'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '${nt1ephemeralStartPort}-${nt1ephemeralEndPort}'
          direction: 'Inbound'
          priority: 3930
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          description: 'allow fabric ephemeral ports within the vnet'
        }
      }
      {
        name: 'allowSvcFabPortal'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: nt1fabricHttpGatewayPort
          direction: 'Inbound'
          priority: 3900
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'allow port used to access the fabric cluster web portal'
        }
      }
      {
        name: 'allowSvcFabClient'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: nt1fabricTcpGatewayPort
          direction: 'Inbound'
          priority: 3910
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'allow port used by the fabric client (includes powershell)'
        }
      }
      {
        name: 'allowSvcFabApplication'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '${nt1applicationStartPort}-${nt1applicationEndPort}'
          direction: 'Inbound'
          priority: 3940
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'allow fabric application ports within the vnet'
        }
      }
      {
        name: 'blockAll'
        properties: {
          access: 'Deny'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          direction: 'Inbound'
          priority: 4095
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'block all traffic except what we\'ve explicitly allowed'
        }
      }
      {
        name: 'allowVNetRDP'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389-4500'
          direction: 'Inbound'
          priority: 3960
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'allow RDP within the net'
        }
      }
      {
        name: 'allowAppPort1'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: loadBalancedAppPort1
          direction: 'Inbound'
          priority: 2001
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'allow public application port 1'
        }
      }
      {
        name: 'allowAppPort2'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: loadBalancedAppPort2
          direction: 'Inbound'
          priority: 2002
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'allow public application port 2'
        }
      }
    ]
  }
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
}

resource vmNodeType1Name 'Microsoft.Compute/virtualMachineScaleSets@2018-10-01' = {
  name: vmNodeType1Name_var
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
            name: 'ServiceFabricNodeVmExt_vmNodeType1Name'
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
                nodeTypeRef: vmNodeType1Name_var
                dataPath: 'D:\\SvcFab'
                durabilityLevel: 'Bronze'
                nicPrefixOverride: subnet1Prefix
                certificate: {
                  thumbprint: certificateThumbprint
                  x509StoreName: certificateStoreValue
                }
              }
              typeHandlerVersion: '1.0'
            }
          }
        ]
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${nicName}-1'
            properties: {
              ipConfigurations: [
                {
                  name: '${nicName}-1'
                  properties: {
                    loadBalancerBackendAddressPools: [
                      {
                        id: lbPoolID1
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: lbNatPoolID1
                      }
                    ]
                    subnet: {
                      id: subnet1Ref
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
        computerNamePrefix: vmNodeType1Name_var
        secrets: [
          {
            sourceVault: {
              id: sourceVaultValue
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
          caching: 'ReadWrite'
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: diskType
          }
        }
      }
    }
  }
  sku: {
    name: vmNodeType1Size
    capacity: nt1InstanceCount
    tier: 'Standard'
  }
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
  dependsOn: [
    'Microsoft.Network/loadBalancers/LB-${clusterName}-${vmNodeType1Name_var}'
  ]
}

resource lbIPName_2 'Microsoft.Network/publicIPAddresses@2018-08-01' = {
  name: '${lbIPName}-2'
  location: computeLocation
  properties: {
    dnsSettings: {
      domainNameLabel: '${dnsName}-backend'
    }
    publicIPAllocationMethod: 'Dynamic'
  }
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
}

resource LB_clusterName_vmNodeType2Name 'Microsoft.Network/loadBalancers@2018-08-01' = {
  name: 'LB-${clusterName}-${vmNodeType2Name_var}'
  location: computeLocation
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerIPConfig'
        properties: {
          publicIPAddress: {
            id: lbIPName_2.id
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
            id: lbPoolID2
          }
          backendPort: nt2fabricTcpGatewayPort
          enableFloatingIP: false
          frontendIPConfiguration: {
            id: lbIPConfig2
          }
          frontendPort: nt2fabricTcpGatewayPort
          idleTimeoutInMinutes: 5
          probe: {
            id: lbProbeID2
          }
          protocol: 'Tcp'
        }
      }
      {
        name: 'LBHttpRule'
        properties: {
          backendAddressPool: {
            id: lbPoolID2
          }
          backendPort: nt2fabricHttpGatewayPort
          enableFloatingIP: false
          frontendIPConfiguration: {
            id: lbIPConfig2
          }
          frontendPort: nt2fabricHttpGatewayPort
          idleTimeoutInMinutes: 5
          probe: {
            id: lbHttpProbeID2
          }
          protocol: 'Tcp'
        }
      }
      {
        name: 'AppPortLBRule1'
        properties: {
          backendAddressPool: {
            id: lbPoolID2
          }
          backendPort: loadBalancedAppPort1
          enableFloatingIP: false
          frontendIPConfiguration: {
            id: lbIPConfig2
          }
          frontendPort: loadBalancedAppPort1
          idleTimeoutInMinutes: 5
          probe: {
            id: '${lbID2}/probes/AppPortProbe1'
          }
          protocol: 'Tcp'
        }
      }
      {
        name: 'AppPortLBRule2'
        properties: {
          backendAddressPool: {
            id: lbPoolID2
          }
          backendPort: loadBalancedAppPort2
          enableFloatingIP: false
          frontendIPConfiguration: {
            id: lbIPConfig2
          }
          frontendPort: loadBalancedAppPort2
          idleTimeoutInMinutes: 5
          probe: {
            id: '${lbID2}/probes/AppPortProbe2'
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
          port: nt2fabricTcpGatewayPort
          protocol: 'Tcp'
        }
      }
      {
        name: 'FabricHttpGatewayProbe'
        properties: {
          intervalInSeconds: 5
          numberOfProbes: 2
          port: nt2fabricHttpGatewayPort
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
            id: lbIPConfig2
          }
          frontendPortRangeEnd: 4500
          frontendPortRangeStart: 3389
          protocol: 'Tcp'
        }
      }
    ]
  }
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
  dependsOn: [
    'Microsoft.Network/publicIPAddresses/${lbIPName}-2'
  ]
}

resource nsg_subnet2Name 'Microsoft.Network/networkSecurityGroups@2018-08-01' = {
  name: 'nsg${subnet2Name}'
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'allowSvcFabSMB'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '445'
          direction: 'Inbound'
          priority: 3950
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          description: 'allow SMB traffic within the net, used by fabric to move packages around'
        }
      }
      {
        name: 'allowSvcFabCluser'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '1025-1027'
          direction: 'Inbound'
          priority: 3920
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          description: 'allow ports within vnet that are used by the fabric to talk between nodes'
        }
      }
      {
        name: 'allowSvcFabEphemeral'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '${nt2ephemeralStartPort}-${nt2ephemeralEndPort}'
          direction: 'Inbound'
          priority: 3930
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          description: 'allow fabric ephemeral ports within the vnet'
        }
      }
      {
        name: 'allowSvcFabPortal'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: nt2fabricHttpGatewayPort
          direction: 'Inbound'
          priority: 3900
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'allow port used to access the fabric cluster web portal'
        }
      }
      {
        name: 'allowSvcFabClient'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: nt2fabricTcpGatewayPort
          direction: 'Inbound'
          priority: 3910
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'allow port used by the fabric client (includes powershell)'
        }
      }
      {
        name: 'allowSvcFabApplication'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '${nt2applicationStartPort}-${nt2applicationEndPort}'
          direction: 'Inbound'
          priority: 3940
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'allow fabric application ports within the vnet'
        }
      }
      {
        name: 'blockAll'
        properties: {
          access: 'Deny'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          direction: 'Inbound'
          priority: 4095
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'allow fabric application ports within the vnet'
        }
      }
      {
        name: 'allowVNetRDP'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389-4500'
          direction: 'Inbound'
          priority: 3960
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'allow RDP within the net'
        }
      }
      {
        name: 'allowAppPort1'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: loadBalancedAppPort1
          direction: 'Inbound'
          priority: 2001
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'allow public application port 1'
        }
      }
      {
        name: 'allowAppPort2'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: loadBalancedAppPort2
          direction: 'Inbound'
          priority: 2002
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          description: 'allow public application port 2'
        }
      }
    ]
  }
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
}

resource vmNodeType2Name 'Microsoft.Compute/virtualMachineScaleSets@2018-10-01' = {
  name: vmNodeType2Name_var
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
            name: 'ServiceFabricNodeVmExt_vmNodeType2Name'
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
                nodeTypeRef: vmNodeType2Name_var
                dataPath: 'D:\\SvcFab'
                durabilityLevel: 'Bronze'
                nicPrefixOverride: subnet2Prefix
                certificate: {
                  thumbprint: certificateThumbprint
                  x509StoreName: certificateStoreValue
                }
              }
              typeHandlerVersion: '1.0'
            }
          }
        ]
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${nicName}-2'
            properties: {
              ipConfigurations: [
                {
                  name: '${nicName}-2'
                  properties: {
                    loadBalancerBackendAddressPools: [
                      {
                        id: lbPoolID2
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: lbNatPoolID2
                      }
                    ]
                    subnet: {
                      id: subnet2Ref
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
        computerNamePrefix: vmNodeType2Name_var
        secrets: [
          {
            sourceVault: {
              id: sourceVaultValue
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
          caching: 'ReadWrite'
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: diskType
          }
        }
      }
    }
  }
  sku: {
    name: vmNodeType2Size
    capacity: nt2InstanceCount
    tier: 'Standard'
  }
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
  dependsOn: [
    'Microsoft.Network/loadBalancers/LB-${clusterName}-${vmNodeType2Name_var}'
  ]
}

resource clusterName_res 'Microsoft.ServiceFabric/clusters@2018-02-01' = {
  name: clusterName
  location: location
  properties: {
    certificate: {
      thumbprint: certificateThumbprint
      x509StoreName: certificateStoreValue
    }
    clientCertificateCommonNames: []
    clientCertificateThumbprints: []
    clusterState: 'Default'
    diagnosticsStorageAccountConfig: {
      blobEndpoint: reference('Microsoft.Storage/storageAccounts/${supportLogStorageAccountName_var}', '2016-01-01').primaryEndpoints.blob
      protectedAccountKeyName: 'StorageAccountKey1'
      queueEndpoint: reference('Microsoft.Storage/storageAccounts/${supportLogStorageAccountName_var}', '2016-01-01').primaryEndpoints.queue
      storageAccountName: supportLogStorageAccountName_var
      tableEndpoint: reference('Microsoft.Storage/storageAccounts/${supportLogStorageAccountName_var}', '2016-01-01').primaryEndpoints.table
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
    managementEndpoint: 'https://${reference('${lbIPName}-0').dnsSettings.fqdn}:${nt0fabricHttpGatewayPort}'
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
      {
        name: vmNodeType1Name_var
        applicationPorts: {
          endPort: nt1applicationEndPort
          startPort: nt1applicationStartPort
        }
        clientConnectionEndpointPort: nt1fabricTcpGatewayPort
        durabilityLevel: 'Bronze'
        ephemeralPorts: {
          endPort: nt1ephemeralEndPort
          startPort: nt1ephemeralStartPort
        }
        httpGatewayEndpointPort: nt1fabricHttpGatewayPort
        isPrimary: false
        vmInstanceCount: nt1InstanceCount
      }
      {
        name: vmNodeType2Name_var
        applicationPorts: {
          endPort: nt2applicationEndPort
          startPort: nt2applicationStartPort
        }
        clientConnectionEndpointPort: nt2fabricTcpGatewayPort
        durabilityLevel: 'Bronze'
        ephemeralPorts: {
          endPort: nt2ephemeralEndPort
          startPort: nt2ephemeralStartPort
        }
        httpGatewayEndpointPort: nt2fabricHttpGatewayPort
        isPrimary: false
        vmInstanceCount: nt2InstanceCount
      }
    ]
    provisioningState: 'Default'
    reliabilityLevel: 'Silver'
    upgradeMode: 'Automatic'
    vmImage: 'Windows'
  }
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
  dependsOn: [
    supportLogStorageAccountName
  ]
}

output clusterProperties object = reference(clusterName)