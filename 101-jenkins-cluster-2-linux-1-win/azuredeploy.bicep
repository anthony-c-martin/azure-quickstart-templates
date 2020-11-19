param location string {
  metadata: {
    description: 'Location for cluster'
  }
  default: resourceGroup().location
}
param master_vmSize string {
  metadata: {
    description: 'Master VM Size'
  }
  default: 'Standard_A2_v2'
}
param linux_worker_vmSize string {
  metadata: {
    description: 'Linux worker VM Size'
  }
  default: 'Standard_A2_v2'
}
param win_worker_vmSize string {
  metadata: {
    description: 'Windows Worker VM Size'
  }
  default: 'Standard_D2s_v3'
}
param master_username string {
  metadata: {
    description: 'Admin Username for Jenkins Master'
  }
}
param node_username string {
  metadata: {
    description: 'Admin username for Slave Instances'
  }
}
param master_password string {
  metadata: {
    description: 'Admin Password for Jenkins Master VM'
  }
  secure: true
}
param node_password string {
  metadata: {
    description: 'Password for slave instances'
  }
  secure: true
}
param jenkins_dns string {
  metadata: {
    description: 'DNS Prefix for Jenkins Master'
  }
  default: 'jenkins-${uniqueString(resourceGroup().id)}'
}
param storageName string {
  minLength: 3
  maxLength: 24
  metadata: {
    description: 'storage account prefix'
  }
  default: 'jenkins${uniqueString(resourceGroup().id)}'
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located including a trailing \'/\''
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-jenkins-cluster-2-linux-1-win/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.'
  }
  secure: true
  default: ''
}

var NetIpRange = '10.0.0.0/16'
var SubnetRange = '10.0.1.0/24'
var scriptUrlMaster = uri(artifactsLocation, 'scripts/install-jenkins.sh${artifactsLocationSasToken}')
var scriptUrlNode1 = uri(artifactsLocation, 'scripts/install-slave.sh${artifactsLocationSasToken}')
var scriptUrlNode2 = uri(artifactsLocation, 'win-slave.ps1${artifactsLocationSasToken}')

resource storageName_res 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: toLower(storageName)
  location: location
  tags: {
    displayName: 'Cluster VM Storage Account'
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource Master_PublicIP 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'Master-PublicIP'
  location: location
  tags: {
    displayName: 'PublicIPAddress'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: jenkins_dns
    }
  }
}

resource master_nsg 'Microsoft.Network/networkSecurityGroups@2018-08-01' = {
  name: 'master-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'nsgRule1'
        properties: {
          description: 'SSH Access to Master'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'nsgRule2'
        properties: {
          description: 'HTTP Access to Master'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource jenkins_cluster_VirtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'jenkins-cluster-VirtualNetwork'
  location: location
  tags: {
    displayName: 'Jenkins-VirtualNetwork'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        NetIpRange
      ]
    }
    subnets: [
      {
        name: 'Jenkins-VirtualNetwork-Subnet'
        properties: {
          addressPrefix: SubnetRange
        }
      }
    ]
  }
}

resource Master_NetworkInterface 'Microsoft.Network/networkInterfaces@2019-11-01' = {
  name: 'Master-NetworkInterface'
  location: location
  tags: {
    displayName: 'Jenkins-Master-NetworkInterface'
  }
  properties: {
    networkSecurityGroup: {
      id: master_nsg.id
    }
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.1.10'
          publicIPAddress: {
            id: Master_PublicIP.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'jenkins-cluster-VirtualNetwork', 'Jenkins-VirtualNetwork-Subnet')
          }
        }
      }
    ]
  }
}

resource Jenkins_Master 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: 'Jenkins-Master'
  location: location
  tags: {
    displayName: 'Jenkins master'
  }
  properties: {
    hardwareProfile: {
      vmSize: master_vmSize
    }
    osProfile: {
      computerName: 'Jenkins-master'
      adminUsername: master_username
      adminPassword: master_password
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: 'master-OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: Master_NetworkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageName_res.properties.primaryEndpoints.blob
      }
    }
  }
}

resource node_1_PublicIP 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'node-1-PublicIP'
  location: location
  tags: {
    displayName: 'PublicIPAddress'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: 'node-1-${jenkins_dns}'
    }
  }
}

resource node_1_nsg 'Microsoft.Network/networkSecurityGroups@2018-08-01' = {
  name: 'node-1-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'nsgRule1'
        properties: {
          description: 'SSH Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
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

resource node_1_NetworkInterface 'Microsoft.Network/networkInterfaces@2019-11-01' = {
  name: 'node-1-NetworkInterface'
  location: location
  tags: {
    displayName: 'node-1-NetworkInterface'
  }
  properties: {
    networkSecurityGroup: {
      id: node_1_nsg.id
    }
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.1.11'
          publicIPAddress: {
            id: node_1_PublicIP.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'jenkins-cluster-VirtualNetwork', 'Jenkins-VirtualNetwork-Subnet')
          }
        }
      }
    ]
  }
}

resource node_1 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: 'node-1'
  location: location
  tags: {
    displayName: 'node-1'
  }
  properties: {
    hardwareProfile: {
      vmSize: linux_worker_vmSize
    }
    osProfile: {
      computerName: 'node-1'
      adminUsername: node_username
      adminPassword: node_password
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: 'node-1-OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: node_1_NetworkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageName_res.properties.primaryEndpoints.blob
      }
    }
  }
}

resource node_2_PublicIP 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'node-2-PublicIP'
  location: location
  tags: {
    displayName: 'PublicIPAddress'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: 'node-2-${jenkins_dns}'
    }
  }
}

resource node_2_nsg 'Microsoft.Network/networkSecurityGroups@2018-08-01' = {
  name: 'node-2-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'nsgRule1'
        properties: {
          description: 'description'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
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

resource node_2_NetworkInterface 'Microsoft.Network/networkInterfaces@2019-11-01' = {
  name: 'node-2-NetworkInterface'
  location: location
  tags: {
    displayName: 'node-2 Network Interface'
  }
  properties: {
    networkSecurityGroup: {
      id: node_2_nsg.id
    }
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.1.12'
          publicIPAddress: {
            id: node_2_PublicIP.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'jenkins-cluster-VirtualNetwork', 'Jenkins-VirtualNetwork-Subnet')
          }
        }
      }
    ]
  }
}

resource node_2 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: 'node-2'
  location: location
  tags: {
    displayName: 'node-2'
  }
  properties: {
    hardwareProfile: {
      vmSize: win_worker_vmSize
    }
    osProfile: {
      computerName: 'node-2'
      adminUsername: node_username
      adminPassword: node_password
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter-with-Containers'
        version: 'latest'
      }
      osDisk: {
        name: 'node-2OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: node_2_NetworkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageName_res.properties.primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageName_res
  ]
}

resource Jenkins_Master_installJenkins 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = {
  name: 'Jenkins-Master/installJenkins'
  location: location
  tags: {
    displayName: 'jenkins-master-script'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        scriptUrlMaster
      ]
    }
    protectedSettings: {
      commandToExecute: 'sh install-jenkins.sh'
    }
  }
}

resource node_2_customScript1 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  name: 'node-2/customScript1'
  location: location
  tags: {
    displayName: 'Jenkins slave for Windows VM'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        scriptUrlNode2
      ]
    }
    protectedSettings: {
      commandToExecute: 'powershell -file win-slave.ps1'
    }
  }
}

resource node_1_installSlave 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  name: 'node-1/installSlave'
  location: location
  tags: {
    displayName: 'Jenkins slave for Linux VM'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        scriptUrlNode1
      ]
    }
    protectedSettings: {
      commandToExecute: 'sh install-slave.sh'
    }
  }
}

output jenkins_dns_out string = 'http://${reference('Master-PublicIP').dnsSettings.fqdn}'