param esClusterName string {
  metadata: {
    description: 'The name of the Elasticsearch cluster.'
  }
  default: 'elasticsearch'
}
param esVersion string {
  allowed: [
    '2.3.1'
    '2.2.2'
    '2.1.2'
    '1.7.5'
  ]
  metadata: {
    description: 'Elasticsearch version to install.'
  }
  default: '2.3.1'
}
param vmClientNodeCount int {
  allowed: [
    0
    1
    2
    3
    4
    5
    6
    7
    8
    9
  ]
  metadata: {
    description: 'Number of Elasticsearch client nodes to provision (Setting this to zero puts the data nodes on the load balancer)'
  }
  default: 1
}
param vmDataNodeCount int {
  metadata: {
    description: 'Number of Elasticsearch data nodes'
  }
  default: 1
}
param vmSizeMasterNodes string {
  allowed: [
    'Standard_D2_v2'
    'Standard_D3_v2'
    'Standard_D4_v2'
    'Standard_A2'
    'Standard_A3'
    'Standard_A4'
    'Standard_A5'
    'Standard_A6'
    'Standard_A7'
    'Standard_DS2'
    'Standard_DS3'
    'Standard_DS4'
    'Standard_DS13'
  ]
  metadata: {
    description: 'Size of the Elasticsearch cluster master nodes'
  }
  default: 'Standard_D2_v2'
}
param vmSizeClientNodes string {
  allowed: [
    'Standard_D2_v2'
    'Standard_D3_v2'
    'Standard_D4_v2'
    'Standard_A2'
    'Standard_A3'
    'Standard_A4'
    'Standard_A5'
    'Standard_A6'
    'Standard_A7'
    'Standard_DS2'
    'Standard_DS3'
    'Standard_DS4'
    'Standard_DS13'
  ]
  metadata: {
    description: 'Size of the Elasticsearch cluster client nodes'
  }
  default: 'Standard_D2_v2'
}
param vmSizeDataNodes string {
  allowed: [
    'Standard_D2_v2'
    'Standard_D3_v2'
    'Standard_D4_v2'
    'Standard_A2'
    'Standard_A3'
    'Standard_A4'
    'Standard_A5'
    'Standard_A6'
    'Standard_A7'
    'Standard_DS2'
    'Standard_DS3'
    'Standard_DS4'
    'Standard_DS13'
  ]
  metadata: {
    description: 'Size of the Elasticsearch cluster data nodes'
  }
  default: 'Standard_D2_v2'
}
param adminUsername string {
  metadata: {
    description: 'User name for the Virtual Machine.'
  }
}
param adminPassword string {
  metadata: {
    description: 'Password for the Virtual Machine.'
  }
  secure: true
}
param ubuntuOSVersion string {
  allowed: [
    '12.04.5-LTS'
    '14.04.4-LTS'
    '16.04.0-LTS'
  ]
  metadata: {
    description: 'The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.'
  }
  default: '14.04.4-LTS'
}
param existingEHNamespace string {
  metadata: {
    description: 'Existing Event Hub namespace.'
  }
}
param existingEHSharedAccessKeyName string {
  metadata: {
    description: 'Existing Event Hub shared access key name.'
  }
}
param existingEHSharedAccessKey string {
  metadata: {
    description: 'Existing Event Hub shared access key.'
  }
}
param existingEHEntityPath string {
  metadata: {
    description: 'Existing Event Hub entity path.'
  }
}
param existingEHPartitions int {
  metadata: {
    description: 'Existing Event Hub partitions.'
  }
}
param artifactsLocation string {
  metadata: {
    description: 'Change this value to your repo name if deploying from a fork'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/diagnostics-eventhub-elk'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'Auto-generated token to access _artifactsLocation'
  }
  secure: true
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var storageAccountPrefix = concat(substring(uniqueString(resourceGroup().id, esClusterName), 0, 6), substring(esClusterName, 0, 3))
var storageAccountName = '${storageAccountPrefix}log'
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var OSDiskName = 'osdiskforlinuxsimple'
var storageAccountType = 'Standard_LRS'
var vmStorageAccountContainerName = 'vhds'
var vmName = 'logstashvm1'
var vmSize = 'Standard_D1'
var vmNicName = '${vmName}-nic'
var vmNsgName = '${vmName}-nsg'
var vmPipName = '${vmName}-pip'
var virtualNetworkName = 'elkvnet2'
var subnetRef = '${resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)}/subnets/other'
var esHost = '10.0.2.100'
var esTemplateBase = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/elasticsearch'
var esDeploymentName = 'esDeploymentForDiagnosticsEventHubELK'

module esDeploymentName_resource '<failed to parse [concat(variables(\'esTemplateBase\'), \'/\', \'azuredeploy.json\')]>' = {
  name: esDeploymentName
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    virtualNetworkName: virtualNetworkName
    OS: 'ubuntu'
    authenticationType: 'password'
    sshPublicKey: ''
    loadBalancerType: 'internal'
    jumpbox: 'Yes'
    vmClientNodeCount: vmClientNodeCount
    vmSizeClientNodes: vmSizeClientNodes
    vmSizeMasterNodes: vmSizeMasterNodes
    vmSizeDataNodes: vmSizeDataNodes
    vmDataNodeCount: vmDataNodeCount
    esClusterName: esClusterName
    esVersion: esVersion
    afs: 'no'
    marvel: 'no'
    marvelCluster: 'no'
    vmSizeMarvelNodes: 'Standard_D2_v2'
    kibana: 'yes'
    sense: 'no'
    jmeterAgent: 'no'
    cloudAzure: 'no'
    cloudAzureStorageAccount: ''
    cloudAzureStorageKey: ''
    '_artifactsLocation': esTemplateBase
    '_artifactsLocationSasToken': ''
  }
}

resource vmNsgName_resource 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: vmNsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          description: 'Allows SSH traffic'
          protocol: 'Tcp'
          sourcePortRange: '22'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vmPipName_resource 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: vmPipName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource vmNicName_resource 'Microsoft.Network/networkInterfaces@2016-03-30' = {
  name: vmNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig2'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vmPipName_resource.id
          }
          subnet: {
            id: subnetRef
          }
          networkSecurityGroup: {
            id: vmNsgName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    esDeploymentName_resource
    vmNsgName_resource
    vmPipName_resource
  ]
}

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: storageAccountName
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  location: location
  tags: {
    displayName: 'StorageAccount'
  }
  properties: {}
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: location
  tags: {
    displayName: 'VirtualMachine'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: ubuntuOSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNicName_resource.id
        }
      ]
    }
  }
  dependsOn: [
    storageAccountName_resource
    vmNicName_resource
  ]
}

resource vmName_InstallEventHubELK 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/InstallEventHubELK'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}/scripts/logstash-eventhub-install-ubuntu.sh${artifactsLocationSasToken}'
      ]
    }
    protectedSettings: {
      commandToExecute: 'bash ./logstash-eventhub-install-ubuntu.sh -n ${existingEHNamespace} -a ${existingEHSharedAccessKeyName} -k ${existingEHSharedAccessKey} -e ${existingEHEntityPath} -p ${existingEHPartitions} -i ${esHost}'
    }
  }
  dependsOn: [
    vmName_resource
    esDeploymentName_resource
  ]
}