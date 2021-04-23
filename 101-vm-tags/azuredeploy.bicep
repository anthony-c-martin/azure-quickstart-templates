@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@secure()
param adminPassword string

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string = 'vm-${uniqueString(resourceGroup().id)}'

@allowed([
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
])
@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
param windowsOSVersion string = '2019-Datacenter'

@description('Department Tag')
param departmentName string = 'MyDepartment'

@description('Application Tag')
param applicationName string = 'MyApp'

@description('Created By Tag')
param createdBy string = 'MyName'

@description('Size for the virtual machine.')
param vmSize string = 'Standard_D2_V3'

@description('Location for all resources.')
param location string = resourceGroup().location

var storageAccountName_var = '${uniqueString(resourceGroup().id)}satagsvm'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var nicName_var = 'myVMNic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var storageAccountType = 'Standard_LRS'
var publicIPAddressName_var = 'myPublicIP'
var publicIPAddressType = 'Dynamic'
var vmName_var = 'MyVM'
var virtualNetworkName_var = 'MyVNET'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var networkSecurityGroupName_var = 'default-NSG'

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: storageAccountName_var
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

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2019-06-01' = {
  name: publicIPAddressName_var
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

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName_var
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

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2019-06-01' = {
  name: virtualNetworkName_var
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
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2019-06-01' = {
  name: nicName_var
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
            id: publicIPAddressName.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vmName_var
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
      computerName: vmName_var
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
          id: nicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(storageAccountName_var).primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageAccountName
  ]
}