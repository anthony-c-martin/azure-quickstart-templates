@minLength(1)
@description('The administrative user on the Windows VM.')
param vmAdminUserName string

@description('The administrative user password.')
@secure()
param vmAdminPassword string

@minLength(1)
@description('The name of the virtual network resource.')
param vNetName string = 'demo-vnet'

@minLength(1)
@description('The DNS prefix assigned to the public IP address resource.')
param vmPIPDnsName string

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/storage-iops-latency-throughput-demo/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

var vNetPrefix = '10.0.0.0/16'
var vNetSubnet1Name = 'subnet-01'
var vNetSubnet1Prefix = '10.0.0.0/24'
var storageAccountType = [
  'Premium_LRS'
  'Standard_LRS'
]
var storageAccountNamePrefix = [
  'premium'
  'standard'
]
var vmImagePublisher = 'MicrosoftWindowsServer'
var vm1ImageOffer = 'WindowsServer'
var vmOSDiskName = '${vmName_var}-OSDisk'
var vmSize = 'Standard_DS3_v2'
var vmName_var = 'demo-01'
var vmWindowsOSVersion = '2016-Datacenter'
var vmSubnetRef = '${vNetName_resource.id}/subnets/${vNetSubnet1Name}'
var vmContainerName = 'vhds'
var vmNicName_var = '${vmName_var}-nic-0'
var vmPIPName_var = '${vmName_var}-PIP'
var dscResourceFolder = 'dsc'
var dscResourceConfig = 'vmDemo'
var networkSecurityGroupName_var = 'default-NSG'

resource storageAccountNamePrefix_id 'Microsoft.Storage/storageAccounts@2015-06-15' = [for (item, i) in storageAccountType: {
  name: concat(storageAccountNamePrefix[i], uniqueString(resourceGroup().id))
  location: location
  tags: {
    displayName: concat(storageAccountNamePrefix[i], uniqueString(resourceGroup().id))
  }
  properties: {
    accountType: item
  }
  dependsOn: []
}]

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

resource vNetName_resource 'Microsoft.Network/virtualNetworks@2016-03-30' = {
  name: vNetName
  location: location
  tags: {
    displayName: vNetName
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetPrefix
      ]
    }
    subnets: [
      {
        name: vNetSubnet1Name
        properties: {
          addressPrefix: vNetSubnet1Prefix
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource vmNicName 'Microsoft.Network/networkInterfaces@2016-03-30' = {
  name: vmNicName_var
  location: location
  tags: {
    displayName: vmNicName_var
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
            id: vmPIPName.id
          }
        }
      }
    ]
  }
}

resource vmName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName_var
  location: location
  tags: {
    displayName: vmName_var
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
        offer: vm1ImageOffer
        sku: vmWindowsOSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${vmName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          name: '${vmName_var}_DataDisk1'
          lun: 0
          diskSizeGB: '100'
          caching: 'None'
          createOption: 'Empty'
        }
        {
          name: '${vmName_var}_DataDisk2'
          lun: 1
          diskSizeGB: '100'
          caching: 'ReadOnly'
          createOption: 'Empty'
        }
        {
          name: '${vmName_var}_DataDisk3'
          lun: 2
          diskSizeGB: '100'
          caching: 'ReadWrite'
          createOption: 'Empty'
        }
        {
          name: '${vmName_var}_DataDisk4'
          lun: 3
          diskSizeGB: 1023
          caching: 'None'
          createOption: 'Empty'
        }
      ]
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
    storageAccountNamePrefix_id
  ]
}

resource vmName_DSC 'Microsoft.Compute/virtualMachines/extensions@2016-03-30' = {
  parent: vmName
  name: 'DSC'
  location: location
  tags: {
    displayName: '${vmName_var}/DSC'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.9'
    autoUpgradeMinorVersion: true
    settings: {
      configuration: {
        url: uri(artifactsLocation, '${dscResourceFolder}/${dscResourceConfig}.zip${artifactsLocationSasToken}')
        script: '${dscResourceConfig}.ps1'
        function: dscResourceConfig
      }
      configurationArguments: {
        nodeName: vmName_var
      }
    }
    protectedSettings: {}
  }
}

resource vmPIPName 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: vmPIPName_var
  location: location
  tags: {
    displayName: vmPIPName_var
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: vmPIPDnsName
    }
  }
  dependsOn: []
}

output vmURI string = reference(vmPIPName_var).dnsSettings.fqdn