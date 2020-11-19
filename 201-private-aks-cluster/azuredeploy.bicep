param location string {
  metadata: {
    description: 'Specifies the location of AKS cluster.'
  }
  default: resourceGroup().location
}
param aksClusterName string {
  metadata: {
    description: 'Specifies the name of the AKS cluster.'
  }
  default: 'aks-${uniqueString(resourceGroup().id)}'
}
param aksClusterDnsPrefix string {
  metadata: {
    description: 'Specifies the DNS prefix specified when creating the managed cluster.'
  }
  default: aksClusterName
}
param aksClusterTags object {
  metadata: {
    description: 'Specifies the tags of the AKS cluster.'
  }
  default: {
    resourceType: 'AKS Cluster'
    createdBy: 'ARM Template'
  }
}
param aksClusterNetworkPlugin string {
  allowed: [
    'azure'
    'kubenet'
  ]
  metadata: {
    description: 'Specifies the network plugin used for building Kubernetes network. - azure or kubenet.'
  }
  default: 'azure'
}
param aksClusterNetworkPolicy string {
  allowed: [
    'azure'
    'calico'
  ]
  metadata: {
    description: 'Specifies the network policy used for building Kubernetes network. - calico or azure'
  }
  default: 'azure'
}
param aksClusterPodCidr string {
  metadata: {
    description: 'Specifies the CIDR notation IP range from which to assign pod IPs when kubenet is used.'
  }
  default: '10.244.0.0/16'
}
param aksClusterServiceCidr string {
  metadata: {
    description: 'A CIDR notation IP range from which to assign service cluster IPs. It must not overlap with any Subnet IP ranges.'
  }
  default: '10.2.0.0/16'
}
param aksClusterDnsServiceIP string {
  metadata: {
    description: 'Specifies the IP address assigned to the Kubernetes DNS service. It must be within the Kubernetes service address range specified in serviceCidr.'
  }
  default: '10.2.0.10'
}
param aksClusterDockerBridgeCidr string {
  metadata: {
    description: 'Specifies the CIDR notation IP range assigned to the Docker bridge network. It must not overlap with any Subnet IP ranges or the Kubernetes service address range.'
  }
  default: '172.17.0.1/16'
}
param aksClusterLoadBalancerSku string {
  allowed: [
    'basic'
    'standard'
  ]
  metadata: {
    description: 'Specifies the sku of the load balancer used by the virtual machine scale sets used by nodepools.'
  }
  default: 'standard'
}
param aksClusterSkuTier string {
  allowed: [
    'Paid'
    'Free'
  ]
  metadata: {
    description: 'Specifies the tier of a managed cluster SKU: Paid or Free'
  }
  default: 'Paid'
}
param aksClusterKubernetesVersion string {
  metadata: {
    description: 'Specifies the version of Kubernetes specified when creating the managed cluster.'
  }
  default: '1.17.9'
}
param aksClusterAdminUsername string {
  metadata: {
    description: 'Specifies the administrator username of Linux virtual machines.'
  }
}
param aksClusterSshPublicKey string {
  metadata: {
    description: 'Specifies the SSH RSA public key string for the Linux nodes.'
  }
}
param aadEnabled bool {
  metadata: {
    description: 'Specifies whether enabling AAD integration.'
  }
  default: false
}
param aadProfileTenantId string {
  metadata: {
    description: 'Specifies the tenant id of the Azure Active Directory used by the AKS cluster for authentication.'
  }
  default: subscription().tenantId
}
param aadProfileAdminGroupObjectIDs array {
  metadata: {
    description: 'Specifies the AAD group object IDs that will have admin role of the cluster.'
  }
  default: []
}
param aksClusterEnablePrivateCluster bool {
  metadata: {
    description: 'Specifies whether to create the cluster as a private cluster or not.'
  }
  default: true
}
param aadProfileManaged bool {
  metadata: {
    description: 'Specifies whether to enable managed AAD integration.'
  }
  default: false
}
param aadProfileEnableAzureRBAC bool {
  metadata: {
    description: 'Specifies whether to  to enable Azure RBAC for Kubernetes authorization.'
  }
  default: false
}
param nodePoolName string {
  metadata: {
    description: 'Specifies the unique name of the node pool profile in the context of the subscription and resource group.'
  }
  default: 'nodepool1'
}
param nodePoolVmSize string {
  metadata: {
    description: 'Specifies the vm size of nodes in the node pool.'
  }
  default: 'Standard_DS3_v2'
}
param nodePoolOsDiskSizeGB int {
  metadata: {
    description: 'Specifies the OS Disk Size in GB to be used to specify the disk size for every machine in this master/agent pool. If you specify 0, it will apply the default osDisk size according to the vmSize specified..'
  }
  default: 100
}
param nodePoolCount int {
  metadata: {
    description: 'Specifies the number of agents (VMs) to host docker containers. Allowed values must be in the range of 1 to 100 (inclusive). The default value is 1.'
  }
  default: 5
}
param nodePoolOsType string {
  allowed: [
    'Linux'
    'Windows'
  ]
  metadata: {
    description: 'Specifies the OS type for the vms in the node pool. Choose from Linux and Windows. Default to Linux.'
  }
  default: 'Linux'
}
param nodePoolMaxPods int {
  metadata: {
    description: 'Specifies the maximum number of pods that can run on a node. The maximum number of pods per node in an AKS cluster is 250. The default maximum number of pods per node varies between kubenet and Azure CNI networking, and the method of cluster deployment.'
  }
  default: 30
}
param nodePoolMaxCount int {
  metadata: {
    description: 'Specifies the maximum number of nodes for auto-scaling for the node pool.'
  }
  default: 5
}
param nodePoolMinCount int {
  metadata: {
    description: 'Specifies the minimum number of nodes for auto-scaling for the node pool.'
  }
  default: 3
}
param nodePoolEnableAutoScaling bool {
  metadata: {
    description: 'Specifies whether to enable auto-scaling for the node pool.'
  }
  default: true
}
param nodePoolScaleSetPriority string {
  allowed: [
    'Spot'
    'Regular'
  ]
  metadata: {
    description: 'Specifies the virtual machine scale set priority: Spot or Regular.'
  }
  default: 'Regular'
}
param nodePoolNodeLabels object {
  metadata: {
    description: 'Specifies the Agent pool node labels to be persisted across all nodes in agent pool.'
  }
  default: {}
}
param nodePoolNodeTaints array {
  metadata: {
    description: 'Specifies the taints added to new nodes during node pool create and scale. For example, key=value:NoSchedule. - string'
  }
  default: []
}
param nodePoolMode string {
  allowed: [
    'System'
    'User'
  ]
  metadata: {
    description: 'Specifies the mode of an agent pool: System or User'
  }
  default: 'System'
}
param nodePoolType string {
  allowed: [
    'VirtualMachineScaleSets'
    'AvailabilitySet'
  ]
  metadata: {
    description: 'Specifies the type of a node pool: VirtualMachineScaleSets or AvailabilitySet'
  }
  default: 'VirtualMachineScaleSets'
}
param nodePoolAvailabilityZones array {
  metadata: {
    description: 'Specifies the availability zones for nodes. Requirese the use of VirtualMachineScaleSets as node pool type.'
  }
  default: []
}
param virtualNetworkName string {
  metadata: {
    description: 'Specifies the name of the virtual network.'
  }
  default: '${aksClusterName}Vnet'
}
param virtualNetworkAddressPrefixes string {
  metadata: {
    description: 'Specifies the address prefixes of the virtual network.'
  }
  default: '10.0.0.0/8'
}
param aksSubnetName string {
  metadata: {
    description: 'Specifies the name of the default subnet hosting the AKS cluster.'
  }
  default: 'AksSubnet'
}
param aksSubnetAddressPrefix string {
  metadata: {
    description: 'Specifies the address prefix of the subnet hosting the AKS cluster.'
  }
  default: '10.0.0.0/16'
}
param logAnalyticsWorkspaceName string {
  metadata: {
    description: 'Specifies the name of the Log Analytics Workspace.'
  }
}
param logAnalyticsSku string {
  allowed: [
    'Free'
    'Standalone'
    'PerNode'
    'PerGB2018'
  ]
  metadata: {
    description: 'Specifies the service tier of the workspace: Free, Standalone, PerNode, Per-GB.'
  }
  default: 'PerGB2018'
}
param logAnalyticsRetentionInDays int {
  metadata: {
    description: 'Specifies the workspace data retention in days. -1 means Unlimited retention for the Unlimited Sku. 730 days is the maximum allowed for all other Skus.'
  }
  default: 60
}
param vmSubnetName string {
  metadata: {
    description: 'Specifies the name of the subnet which contains the virtual machine.'
  }
  default: 'VmSubnet'
}
param vmSubnetAddressPrefix string {
  metadata: {
    description: 'Specifies the address prefix of the subnet which contains the virtual machine.'
  }
  default: '10.1.0.0/24'
}
param vmName string {
  metadata: {
    description: 'Specifies the name of the virtual machine.'
  }
  default: 'TestVm'
}
param vmSize string {
  metadata: {
    description: 'Specifies the size of the virtual machine.'
  }
  default: 'Standard_DS3_v2'
}
param imagePublisher string {
  metadata: {
    description: 'Specifies the image publisher of the disk image used to create the virtual machine.'
  }
  default: 'Canonical'
}
param imageOffer string {
  metadata: {
    description: 'Specifies the offer of the platform image or marketplace image used to create the virtual machine.'
  }
  default: 'UbuntuServer'
}
param imageSku string {
  metadata: {
    description: 'Specifies the Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.'
  }
  default: '18.04-LTS'
}
param authenticationType string {
  allowed: [
    'sshPublicKey'
    'password'
  ]
  metadata: {
    description: 'Specifies the type of authentication when accessing the Virtual Machine. SSH key is recommended.'
  }
  default: 'password'
}
param vmAdminUsername string {
  metadata: {
    description: 'Specifies the name of the administrator account of the virtual machine.'
  }
}
param vmAdminPasswordOrKey string {
  metadata: {
    description: 'Specifies the SSH Key or password for the virtual machine. SSH key is recommended.'
  }
  secure: true
}
param diskStorageAccounType string {
  allowed: [
    'Premium_LRS'
    'StandardSSD_LRS'
    'Standard_LRS'
    'UltraSSD_LRS'
  ]
  metadata: {
    description: 'Specifies the storage account type for OS and data disk.'
  }
  default: 'Premium_LRS'
}
param numDataDisks int {
  minValue: 0
  maxValue: 64
  metadata: {
    description: 'Specifies the number of data disks of the virtual machine.'
  }
  default: 1
}
param osDiskSize int {
  metadata: {
    description: 'Specifies the size in GB of the OS disk of the VM.'
  }
  default: 50
}
param dataDiskSize int {
  metadata: {
    description: 'Specifies the size in GB of the OS disk of the virtual machine.'
  }
  default: 50
}
param dataDiskCaching string {
  metadata: {
    description: 'Specifies the caching requirements for the data disks.'
  }
  default: 'ReadWrite'
}
param blobStorageAccountName string {
  metadata: {
    description: 'Specifies the globally unique name for the storage account used to store the boot diagnostics logs of the virtual machine.'
  }
  default: 'blob${uniqueString(resourceGroup().id)}'
}
param blobStorageAccountPrivateEndpointName string {
  metadata: {
    description: 'Specifies the name of the private link to the boot diagnostics storage account.'
  }
  default: 'BlobStorageAccountPrivateEndpoint'
}
param bastionSubnetAddressPrefix string {
  metadata: {
    description: 'Specifies the Bastion subnet IP prefix. This prefix must be within vnet IP prefix address space.'
  }
  default: '10.1.1.0/26'
}
param bastionHostName string {
  metadata: {
    description: 'Specifies the name of the Azure Bastion resource.'
  }
  default: '${aksClusterName}Bastion'
}

var vmSubnetNsgName = '${vmSubnetName}Nsg'
var vmSubnetNsgId = vmSubnetNsgName_resource.id
var bastionSubnetNsgName = '${bastionHostName}Nsg'
var bastionSubnetNsgId = bastionSubnetNsgName_resource.id
var vnetId = virtualNetworkName_resource.id
var vmSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, vmSubnetName)
var aksSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, aksSubnetName)
var vmNicName = '${vmName}Nic'
var vmNicId = vmNicName_resource.id
var blobStorageAccountId = blobStorageAccountName_resource.id
var blobPublicDNSZoneForwarder = '.blob.${environment().suffixes.storage}'
var blobPrivateDnsZoneName = 'privatelink${blobPublicDNSZoneForwarder}'
var blobPrivateDnsZoneId = blobPrivateDnsZoneName_resource.id
var blobStorageAccountPrivateEndpointGroupName = 'blob'
var blobPrivateDnsZoneGroup = '${blobStorageAccountPrivateEndpointName}/${blobStorageAccountPrivateEndpointGroupName}PrivateDnsZoneGroup'
var blobStorageAccountPrivateEndpointId = blobStorageAccountPrivateEndpointName_resource.id
var vmId = vmName_resource.id
var omsAgentForLinuxName = 'LogAnalytics'
var omsAgentForLinuxId = vmName_omsAgentForLinuxName.id
var omsDependencyAgentForLinuxName = 'DependencyAgent'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${vmAdminUsername}/.ssh/authorized_keys'
        keyData: vmAdminPasswordOrKey
      }
    ]
  }
  provisionVMAgent: true
}
var bastionPublicIpAddressName = '${bastionHostName}PublicIp'
var bastionPublicIpAddressId = bastionPublicIpAddressName_resource.id
var bastionSubnetName = 'AzureBastionSubnet'
var bastionSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, bastionSubnetName)
var workspaceId = logAnalyticsWorkspaceName_resource.id
var aadProfileConfiguration = {
  managed: aadProfileManaged
  enableAzureRBAC: aadProfileEnableAzureRBAC
  adminGroupObjectIDs: aadProfileAdminGroupObjectIDs
  tenantID: aadProfileTenantId
}

resource bastionPublicIpAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: bastionPublicIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionSubnetNsgName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: bastionSubnetNsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'bastionInAllow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'bastionControlInAllow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationPortRanges: [
            '443'
            '4443'
          ]
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'bastionInDeny'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 900
          direction: 'Inbound'
        }
      }
      {
        name: 'bastionVnetOutAllow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'bastionAzureOutAllow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource bastionHostName_resource 'Microsoft.Network/bastionHosts@2020-05-01' = {
  name: bastionHostName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: bastionSubnetId
          }
          publicIPAddress: {
            id: bastionPublicIpAddressId
          }
        }
      }
    ]
  }
  dependsOn: [
    bastionPublicIpAddressId
    vnetId
  ]
}

resource blobStorageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: blobStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource vmNicName_resource 'Microsoft.Network/networkInterfaces@2020-04-01' = {
  name: vmNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vmSubnetId
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetId
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: osDiskSize
        managedDisk: {
          storageAccountType: diskStorageAccounType
        }
      }
      copy: [
        {
          name: 'dataDisks'
          count: numDataDisks
          input: {
            caching: dataDiskCaching
            diskSizeGB: dataDiskSize
            lun: copyIndex('dataDisks')
            name: '${vmName}-DataDisk${copyIndex('dataDisks')}'
            createOption: 'Empty'
            managedDisk: {
              storageAccountType: diskStorageAccounType
            }
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNicName_resource.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(blobStorageAccountId).primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    vmNicId
  ]
}

resource vmName_omsAgentForLinuxName 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${vmName}/${omsAgentForLinuxName}'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'OmsAgentForLinux'
    typeHandlerVersion: '1.12'
    settings: {
      workspaceId: reference(workspaceId, '2020-03-01-preview').customerId
      stopOnMultipleConnections: false
    }
    protectedSettings: {
      workspaceKey: listKeys(workspaceId, '2020-03-01-preview').primarySharedKey
    }
  }
  dependsOn: [
    vmId
    workspaceId
  ]
}

resource vmName_omsDependencyAgentForLinuxName 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  name: '${vmName}/${omsDependencyAgentForLinuxName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentLinux'
    typeHandlerVersion: '9.10'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    vmId
    workspaceId
    omsAgentForLinuxId
  ]
}

resource vmSubnetNsgName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: vmSubnetNsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSshInbound'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefixes
      ]
    }
    subnets: [
      {
        name: aksSubnetName
        properties: {
          addressPrefix: aksSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: vmSubnetName
        properties: {
          addressPrefix: vmSubnetAddressPrefix
          networkSecurityGroup: {
            id: vmSubnetNsgId
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetAddressPrefix
          networkSecurityGroup: {
            id: bastionSubnetNsgId
          }
        }
      }
    ]
    enableDdosProtection: false
    enableVmProtection: false
  }
  dependsOn: [
    bastionSubnetNsgId
  ]
}

resource aksClusterName_resource 'Microsoft.ContainerService/managedClusters@2020-07-01' = {
  name: aksClusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: aksClusterTags
  properties: {
    kubernetesVersion: aksClusterKubernetesVersion
    dnsPrefix: aksClusterDnsPrefix
    sku: {
      name: 'Basic'
      tier: aksClusterSkuTier
    }
    agentPoolProfiles: [
      {
        name: toLower(nodePoolName)
        count: nodePoolCount
        vmSize: nodePoolVmSize
        osDiskSizeGB: nodePoolOsDiskSizeGB
        vnetSubnetID: aksSubnetId
        maxPods: nodePoolMaxPods
        osType: nodePoolOsType
        maxCount: nodePoolMaxCount
        minCount: nodePoolMinCount
        scaleSetPriority: nodePoolScaleSetPriority
        enableAutoScaling: nodePoolEnableAutoScaling
        mode: nodePoolMode
        type: nodePoolType
        availabilityZones: nodePoolAvailabilityZones
        nodeLabels: nodePoolNodeLabels
        nodeTaints: nodePoolNodeTaints
      }
    ]
    linuxProfile: {
      adminUsername: aksClusterAdminUsername
      ssh: {
        publicKeys: [
          {
            keyData: aksClusterSshPublicKey
          }
        ]
      }
    }
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: workspaceId
        }
      }
    }
    enableRBAC: true
    networkProfile: {
      networkPlugin: aksClusterNetworkPlugin
      networkPolicy: aksClusterNetworkPolicy
      podCidr: aksClusterPodCidr
      serviceCidr: aksClusterServiceCidr
      dnsServiceIP: aksClusterDnsServiceIP
      dockerBridgeCidr: aksClusterDockerBridgeCidr
      loadBalancerSku: aksClusterLoadBalancerSku
    }
    aadProfile: (aadEnabled ? aadProfileConfiguration : json('null'))
    apiServerAccessProfile: {
      enablePrivateCluster: aksClusterEnablePrivateCluster
    }
  }
  dependsOn: [
    vnetId
    workspaceId
  ]
}

resource logAnalyticsWorkspaceName_resource 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: logAnalyticsSku
    }
    retentionInDays: logAnalyticsRetentionInDays
  }
}

resource blobPrivateDnsZoneName_resource 'Microsoft.Network/privateDnsZones@2020-01-01' = {
  name: blobPrivateDnsZoneName
  location: 'global'
  properties: {
    maxNumberOfRecordSets: 25000
    maxNumberOfVirtualNetworkLinks: 1000
    maxNumberOfVirtualNetworkLinksWithRegistration: 100
  }
}

resource blobPrivateDnsZoneName_link_to_virtualNetworkName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-01-01' = {
  name: '${blobPrivateDnsZoneName}/link_to_${toLower(virtualNetworkName)}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
  dependsOn: [
    blobPrivateDnsZoneId
    vnetId
  ]
}

resource blobStorageAccountPrivateEndpointName_resource 'Microsoft.Network/privateEndpoints@2020-04-01' = {
  name: blobStorageAccountPrivateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: blobStorageAccountPrivateEndpointName
        properties: {
          privateLinkServiceId: blobStorageAccountId
          groupIds: [
            blobStorageAccountPrivateEndpointGroupName
          ]
        }
      }
    ]
    subnet: {
      id: vmSubnetId
    }
    customDnsConfigs: [
      {
        fqdn: concat(blobStorageAccountName, blobPublicDNSZoneForwarder)
      }
    ]
  }
  dependsOn: [
    vnetId
    blobStorageAccountId
  ]
}

resource blobPrivateDnsZoneGroup_resource 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  name: blobPrivateDnsZoneGroup
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'dnsConfig'
        properties: {
          privateDnsZoneId: blobPrivateDnsZoneId
        }
      }
    ]
  }
  dependsOn: [
    blobPrivateDnsZoneId
    blobStorageAccountPrivateEndpointId
  ]
}