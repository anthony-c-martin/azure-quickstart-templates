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
param encodedConfigString string {
  metadata: {
    description: 'Base64 encoded string which is the Logstash configuration. If you don\'t want to enter a custom Logstash configuration and would like to use the logstash-input-azurewadtable plugin set this to \'na\'.'
  }
  default: 'na'
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
param existingDiagnosticsStorageAccountName string {
  metadata: {
    description: 'Existing diagnostics storage account name.'
  }
  default: ''
}
param existingDiagnosticsStorageAccountKey string {
  metadata: {
    description: 'Existing diagnostics storage account key.'
  }
  default: ''
}
param existingDiagnosticsStorageTableNames string {
  metadata: {
    description: 'List of existing tables containing diagnostics data separated by semicolon (;).'
  }
  default: ''
}
param artifactsLocation string {
  metadata: {
    description: 'Change this value to your repo name if deploying from a fork'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/diagnostics-with-elk'
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
var storageAccountName_var = '${storageAccountPrefix}log'
var extensionName = 'ELKSimple'
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
var esDeploymentName_var = 'esDeploymentForDiagnosticsWithELK'

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

resource vmName_extensionName 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName_var}/${extensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}/scripts/elk-simple-install-ubuntu.sh${artifactsLocationSasToken}'
      ]
    }
    protectedSettings: {
      commandToExecute: 'bash ./elk-simple-install-ubuntu.sh -e ${encodedConfigString} -a ${existingDiagnosticsStorageAccountName} -k ${existingDiagnosticsStorageAccountKey} -t ${existingDiagnosticsStorageTableNames} -i ${esHost}'
    }
  }
  dependsOn: [
    vmName
    esDeploymentName
  ]
}