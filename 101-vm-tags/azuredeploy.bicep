param adminUsername string {
  metadata: {
    description: 'Username for the Virtual Machine.'
  }
}
param adminPassword string {
  metadata: {
    description: 'Password for the Virtual Machine.'
  }
  secure: true
}
param dnsLabelPrefix string {
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Virtual Machine.'
  }
  default: 'vm-${uniqueString(resourceGroup().id)}'
}
param windowsOSVersion string {
  allowed: [
    '2016-Datacenter'
    '2016-Datacenter-Server-Core'
    '2016-Datacenter-Server-Core-smalldisk'
    '2016-Datacenter-smalldisk'
    '2016-Datacenter-with-Containers'
    '2016-Datacenter-with-RDSH'
    '2016-Datacenter-zhcn'
    '2019-Datacenter'
    '2019-Datacenter-Core'
    '2019-Datacenter-Core-smalldisk'
    '2019-Datacenter-Core-with-Containers'
    '2019-Datacenter-Core-with-Containers-smalldisk'
    '2019-datacenter-gensecond'
    '2019-Datacenter-smalldisk'
    '2019-Datacenter-with-Containers'
    '2019-Datacenter-with-Containers-smalldisk'
    '2019-Datacenter-zhcn'
    'Datacenter-Core-1803-with-Containers-smalldisk'
    'Datacenter-Core-1809-with-Containers-smalldisk'
    'Datacenter-Core-1903-with-Containers-smalldisk'
  ]
  metadata: {
    description: 'The Windows version for the VM. This will pick a fully patched image of this given Windows version.'
  }
  default: '2019-Datacenter'
}
param departmentName string {
  metadata: {
    description: 'Department Tag'
  }
  default: 'MyDepartment'
}
param applicationName string {
  metadata: {
    description: 'Application Tag'
  }
  default: 'MyApp'
}
param createdBy string {
  metadata: {
    description: 'Created By Tag'
  }
  default: 'MyName'
}
param vmSize string {
  metadata: {
    description: 'Size for the virtual machine.'
  }
  default: 'Standard_D2_V3'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var storageAccountName = '${uniqueString(resourceGroup().id)}satagsvm'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var nicName = 'myVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var vmName = 'MyVM'
var virtualNetworkName = 'MyVNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var networkSecurityGroupName = 'default-NSG'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: storageAccountName
  location: location
  kind: 'Storage'
  sku: {
    name: storageAccountType
  }
  tags: {
    Department: departmentName
    Application: applicationName
    'Created By': createdBy
  }
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2019-06-01' = {
  name: publicIPAddressName
  location: location
  tags: {
    Department: departmentName
    Application: applicationName
    'Created By': createdBy
  }
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-06-01' = {
  name: virtualNetworkName
  location: location
  tags: {
    Department: departmentName
    Application: applicationName
    'Created By': createdBy
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroupName_resource
  ]
}

resource nicName_resource 'Microsoft.Network/networkInterfaces@2019-06-01' = {
  name: nicName
  location: location
  tags: {
    Department: departmentName
    Application: applicationName
    'Created By': createdBy
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName_resource.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
    virtualNetworkName_resource
  ]
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vmName
  location: location
  tags: {
    Department: departmentName
    Application: applicationName
    'Created By': createdBy
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
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName_resource.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(storageAccountName).primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageAccountName_resource
    nicName_resource
  ]
}