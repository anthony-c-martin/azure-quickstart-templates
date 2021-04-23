@description('Administrator Username for the local admin account')
param virtualMachineAdminUserName string = 'azadmin'

@description('Administrator password for the local admin account')
@secure()
param virtualMachineAdminPassword string

@maxLength(15)
@description('Name of the virtual machine to be created')
param virtualMachineNamePrefix string = 'MyVM0'

@description('Number of  virtual machines to be created')
param virtualMachineCount int = 3

@allowed([
  'Standard_DS1_v2'
  'Standard_DS2_v2'
  'Standard_DS3_v2'
  'Standard_DS4_v2'
  'Standard_DS5_v2'
])
@description('Virtual Machine Size')
param virtualMachineSize string = 'Standard_DS2_v2'

@allowed([
  'Server2012R2'
  'Server2016'
  'Server2019'
])
@description('Operating System of the Server')
param operatingSystem string = 'Server2019'

@description('Availability Set Name where the VM will be placed')
param availabilitySetName string = 'MyAvailabilitySet'

@minLength(1)
@maxLength(14)
@description('Globally unique DNS prefix for the Public IPs used to access the Virtual Machines')
param dnsPrefixForPublicIP string = uniqueString(resourceGroup().id)

@description('Location for all resources.')
param location string = resourceGroup().location

var myVNETName_var = 'myVNET'
var myVNETPrefix = '10.0.0.0/16'
var myVNETSubnet1Name = 'Subnet1'
var myVNETSubnet1Prefix = '10.0.0.0/24'
var diagnosticStorageAccountName_var = 'diagst${uniqueString(resourceGroup().id)}'
var operatingSystemValues = {
  Server2012R2: {
    PublisherValue: 'MicrosoftWindowsServer'
    OfferValue: 'WindowsServer'
    SkuValue: '2012-R2-Datacenter'
  }
  Server2016: {
    PublisherValue: 'MicrosoftWindowsServer'
    OfferValue: 'WindowsServer'
    SkuValue: '2016-Datacenter'
  }
  Server2019: {
    PublisherValue: 'MicrosoftWindowsServer'
    OfferValue: 'WindowsServer'
    SkuValue: '2019-Datacenter'
  }
}
var availabilitySetPlatformFaultDomainCount = '2'
var availabilitySetPlatformUpdateDomainCount = '5'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', myVNETName_var, myVNETSubnet1Name)
var networkSecurityGroupName_var = 'default-NSG'

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
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

resource myVNETName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: myVNETName_var
  location: location
  tags: {
    displayName: myVNETName_var
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        myVNETPrefix
      ]
    }
    subnets: [
      {
        name: myVNETSubnet1Name
        properties: {
          addressPrefix: myVNETSubnet1Prefix
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource diagnosticStorageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: diagnosticStorageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  tags: {
    displayName: 'diagnosticStorageAccount'
  }
  kind: 'StorageV2'
}

resource availabilitySetName_resource 'Microsoft.Compute/availabilitySets@2020-06-01' = {
  name: availabilitySetName
  location: location
  properties: {
    platformFaultDomainCount: availabilitySetPlatformFaultDomainCount
    platformUpdateDomainCount: availabilitySetPlatformUpdateDomainCount
  }
  sku: {
    name: 'Aligned'
  }
}

resource virtualMachineNamePrefix_1 'Microsoft.Compute/virtualMachines@2020-06-01' = [for i in range(0, virtualMachineCount): {
  name: concat(virtualMachineNamePrefix, (i + 1))
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      imageReference: {
        publisher: operatingSystemValues[operatingSystem].PublisherValue
        offer: operatingSystemValues[operatingSystem].OfferValue
        sku: operatingSystemValues[operatingSystem].SkuValue
        version: 'latest'
      }
      osDisk: {
        name: concat(virtualMachineNamePrefix, (i + 1))
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        caching: 'ReadWrite'
      }
    }
    osProfile: {
      computerName: concat(virtualMachineNamePrefix, (i + 1))
      adminUsername: virtualMachineAdminUserName
      windowsConfiguration: {
        provisionVMAgent: true
      }
      adminPassword: virtualMachineAdminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${virtualMachineNamePrefix}${(i + 1)}-NIC1')
        }
      ]
    }
    availabilitySet: {
      id: availabilitySetName_resource.id
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(diagnosticStorageAccountName.id, '2016-01-01').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    availabilitySetName_resource
    diagnosticStorageAccountName
    resourceId('Microsoft.Network/networkInterfaces', '${virtualMachineNamePrefix}${(i + 1)}-NIC1')
  ]
}]

resource virtualMachineNamePrefix_1_NIC1 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, virtualMachineCount): {
  name: '${virtualMachineNamePrefix}${(i + 1)}-NIC1'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', '${virtualMachineNamePrefix}${(i + 1)}-PIP1')
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
    enableIPForwarding: false
  }
  dependsOn: [
    resourceId('Microsoft.Network/publicIPAddresses', '${virtualMachineNamePrefix}${(i + 1)}-PIP1')
    myVNETName
  ]
}]

resource virtualMachineNamePrefix_1_PIP1 'Microsoft.Network/publicIPAddresses@2020-05-01' = [for i in range(0, virtualMachineCount): {
  name: '${virtualMachineNamePrefix}${(i + 1)}-PIP1'
  location: location
  tags: {
    displayName: '${virtualMachineNamePrefix}${(i + 1)}-PIP1'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: concat(dnsPrefixForPublicIP, (i + 1))
    }
  }
}]