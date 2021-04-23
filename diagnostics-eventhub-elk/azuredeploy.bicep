@description('The name of the Elasticsearch cluster.')
param esClusterName string = 'elasticsearch'

@allowed([
  '2.3.1'
  '2.2.2'
  '2.1.2'
  '1.7.5'
])
@description('Elasticsearch version to install.')
param esVersion string = '2.3.1'

@allowed([
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
])
@description('Number of Elasticsearch client nodes to provision (Setting this to zero puts the data nodes on the load balancer)')
param vmClientNodeCount int = 1

@description('Number of Elasticsearch data nodes')
param vmDataNodeCount int = 1

@allowed([
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
])
@description('Size of the Elasticsearch cluster master nodes')
param vmSizeMasterNodes string = 'Standard_D2_v2'

@allowed([
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
])
@description('Size of the Elasticsearch cluster client nodes')
param vmSizeClientNodes string = 'Standard_D2_v2'

@allowed([
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
])
@description('Size of the Elasticsearch cluster data nodes')
param vmSizeDataNodes string = 'Standard_D2_v2'

@description('User name for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@secure()
param adminPassword string

@allowed([
  '12.04.5-LTS'
  '14.04.4-LTS'
  '16.04.0-LTS'
])
@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
param ubuntuOSVersion string = '14.04.4-LTS'

@description('Existing Event Hub namespace.')
param existingEHNamespace string

@description('Existing Event Hub shared access key name.')
param existingEHSharedAccessKeyName string

@description('Existing Event Hub shared access key.')
param existingEHSharedAccessKey string

@description('Existing Event Hub entity path.')
param existingEHEntityPath string

@description('Existing Event Hub partitions.')
param existingEHPartitions int

@description('Change this value to your repo name if deploying from a fork')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/diagnostics-eventhub-elk'

@description('Auto-generated token to access _artifactsLocation')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

var storageAccountPrefix = concat(substring(uniqueString(resourceGroup().id, esClusterName), 0, 6), substring(esClusterName, 0, 3))
var storageAccountName_var = '${storageAccountPrefix}log'
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var OSDiskName = 'osdiskforlinuxsimple'
var storageAccountType = 'Standard_LRS'
var vmStorageAccountContainerName = 'vhds'
var vmName_var = 'logstashvm1'
var vmSize = 'Standard_D1'
var vmNicName_var = '${vmName_var}-nic'
var vmNsgName_var = '${vmName_var}-nsg'
var vmPipName_var = '${vmName_var}-pip'
var virtualNetworkName = 'elkvnet2'
var subnetRef = '${resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)}/subnets/other'
var esHost = '10.0.2.100'
var esTemplateBase = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/elasticsearch'
var esDeploymentName_var = 'esDeploymentForDiagnosticsEventHubELK'

module esDeploymentName '?' /*TODO: replace with correct path to [concat(variables('esTemplateBase'), '/', 'azuredeploy.json')]*/ = {
  name: esDeploymentName_var
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

resource vmNsgName 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: vmNsgName_var
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

resource vmPipName 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: vmPipName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource vmNicName 'Microsoft.Network/networkInterfaces@2016-03-30' = {
  name: vmNicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig2'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vmPipName.id
          }
          subnet: {
            id: subnetRef
          }
          networkSecurityGroup: {
            id: vmNsgName.id
          }
        }
      }
    ]
  }
  dependsOn: [
    esDeploymentName
  ]
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: storageAccountName_var
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

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName_var
  location: location
  tags: {
    displayName: 'VirtualMachine'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
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
        name: '${vmName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNicName.id
        }
      ]
    }
  }
  dependsOn: [
    storageAccountName
  ]
}

resource vmName_InstallEventHubELK 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  parent: vmName
  name: 'InstallEventHubELK'
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
    esDeploymentName
  ]
}