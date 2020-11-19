param vmAdminUserName string {
  metadata: {
    description: 'VM admin user name'
  }
}
param vmAdminPassword string {
  metadata: {
    description: 'VM admin password. The supplied password must be between 8-123 characters long and must satisfy at least 3 of password complexity requirements from the following: 1) Contains an uppercase character 2) Contains a lowercase character 3) Contains a numeric digit 4) Contains a special character.'
  }
  secure: true
}
param vmVisualStudioVersion string {
  allowed: [
    'VS-2015-Comm-VSU3-AzureSDK-29-WS2012R2'
    'VS-2015-Comm-VSU3-AzureSDK-291-WS2012R2'
    'VS-2015-Ent-VSU3-AzureSDK-29-WS2012R2'
    'VS-2017-Comm-Latest-Preview-WS2016'
    'VS-2017-Comm-Latest-WS2016'
    'VS-2017-Comm-WS2016'
    'VS-2017-Ent-Latest-Preview-WS2016'
    'VS-2017-Ent-Latest-WS2016'
    'VS-2017-Ent-WS2016'
    'vs-2019-preview-ws2016'
  ]
  metadata: {
    description: 'Which version of Visual Studio you would like to deploy'
  }
  default: 'VS-2017-Ent-Latest-WS2016'
}
param vmIPPublicDnsNamePrefix string {
  metadata: {
    description: 'Globally unique naming prefix for per region for the public IP address. For instance, myVMuniqueIP.westus.cloudapp.azure.com. It must conform to the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param vmSize string {
  metadata: {
    description: 'VM Size'
  }
  default: 'Standard_D2s_v3'
}

var vmName_var = '${substring(vmVisualStudioVersion, 0, 8)}vm'
var vnet01Prefix = '10.0.0.0/16'
var vnet01Subnet1Name = 'Subnet-1'
var vnetName_var = 'vnet'
var vnet01Subnet1Prefix = '10.0.0.0/24'
var vmImagePublisher = 'MicrosoftVisualStudio'
var vmImageOffer = 'VisualStudio'
var vmSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, vnet01Subnet1Name)
var vmNicName_var = '${vmName_var}-nic'
var vmIP01Name_var = 'VMIP01'
var networkSecurityGroupName_var = '${vnet01Subnet1Name}-nsg'

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

resource vnetName 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: vnetName_var
  location: location
  tags: {
    displayName: 'VNet01'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet01Prefix
      ]
    }
    subnets: [
      {
        name: vnet01Subnet1Name
        properties: {
          addressPrefix: vnet01Subnet1Prefix
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource vmNicName 'Microsoft.Network/networkInterfaces@2020-03-01' = {
  name: vmNicName_var
  location: location
  tags: {
    displayName: 'VMNic01'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vmSubnetRef
          }
          publicIPAddress: {
            id: vmIP01Name.id
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName_var
  location: location
  tags: {
    displayName: 'VM01'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: vmAdminUserName
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: vmImagePublisher
        offer: vmImageOffer
        sku: vmVisualStudioVersion
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
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
}

resource vmIP01Name 'Microsoft.Network/publicIPAddresses@2020-03-01' = {
  name: vmIP01Name_var
  location: location
  tags: {
    displayName: 'VMIP01'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: vmIPPublicDnsNamePrefix
    }
  }
}

output vm_fqdn string = reference(vmIP01Name_var).dnsSettings.fqdn