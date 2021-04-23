@description('Administrator Username for the local admin account')
param virtualMachineAdminUserName string

@description('Administrator password for the local admin account')
@secure()
param virtualMachineAdminPassword string

@maxLength(15)
@description('Name of the virtual machine to be created')
param virtualMachineNamePrefix string = 'MyVM0'

@minValue(1)
@maxValue(150)
@description('Number of  virtual machines to be created')
param virtualMachineCount int = 3

@allowed([
  'Standard_B1ls'
  'Standard_B1s'
  'Standard_B1ms'
  'Standard_B2s'
  'Standard_B2ms'
  'Standard_DS1_v2'
  'Standard_DS2_v2'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
])
@description('Virtual Machine Size.')
param virtualMachineSize string = 'Standard_DS1_v2'

@allowed([
  'Win2019DataCenter'
  'Win2016DataCenter'
  'UbuntuLTS'
])
@description('Operating System of the Server')
param operatingSystem string = 'UbuntuLTS'

@description('Virtual Machine Scale Set Name where the VM will be placed')
param virtualMachineScaleSetName string = 'MyVirtualMachineScaleSet'

@allowed([
  'none'
  '1'
  '2'
  '3'
])
@description('Specify an Availability Zone for the Virtual Machine Scale Set. All Virtual Machines added the the scale set will inherit this zone. Not all Azure regions support Availability zones. VMSS deployed into a zone must have a platformFaultDomainCount = 1. Learn more about maximum fault domain count by region: https://aka.ms/azurefdcountbyregion')
param virtualMachineScaleSetAvailabilityZone string = 'none'

@minLength(1)
@maxLength(14)
@description('Globally unique DNS prefix for the Public IPs used to access the Virtual Machines')
param dnsPrefixForPublicIP string = 'd${uniqueString(resourceGroup().id)}'

@description('Location for all resources.')
param location string = resourceGroup().location

var myVNETName_var = 'myVMSS-VNET'
var myVNETPrefix = '10.0.0.0/16'
var myVNETSubnet1Name = 'VMSS-Subnet1'
var myVNETSubnet1Prefix = '10.0.0.0/24'
var operatingSystemValues = {
  Win2019DataCenter: {
    PublisherValue: 'MicrosoftWindowsServer'
    OfferValue: 'WindowsServer'
    SkuValue: '2019-Datacenter'
  }
  Win2016DataCenter: {
    PublisherValue: 'MicrosoftWindowsServer'
    OfferValue: 'WindowsServer'
    SkuValue: '2016-Datacenter'
  }
  UbuntuLTS: {
    PublisherValue: 'Canonical'
    OfferValue: 'UbuntuServer'
    SkuValue: '18.04-LTS'
  }
}
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', myVNETName_var, myVNETSubnet1Name)
var fdCountOptions = {
  zonal: 1
  nonzonal: 2
}
var selectedZone = ((virtualMachineScaleSetAvailabilityZone == 'none') ? '' : array(virtualMachineScaleSetAvailabilityZone))
var virtualMachineScaleSetPlatformFaultDomainCount = ((virtualMachineScaleSetAvailabilityZone == 'none') ? fdCountOptions.nonzonal : fdCountOptions.zonal)
var networkSecurityGroupName_var = '${myVNETSubnet1Name}-nsg'

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-22'
        properties: {
          priority: 1000
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

resource myVNETName 'Microsoft.Network/virtualNetworks@2019-04-01' = {
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

resource virtualMachineScaleSetName_resource 'Microsoft.Compute/virtualMachineScaleSets@2020-12-01' = {
  name: virtualMachineScaleSetName
  location: location
  properties: {
    singlePlacementGroup: 'false'
    platformFaultDomainCount: virtualMachineScaleSetPlatformFaultDomainCount
  }
  zones: selectedZone
}

resource virtualMachineNamePrefix_1 'Microsoft.Compute/virtualMachines@2020-12-01' = [for i in range(0, virtualMachineCount): {
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
      adminPassword: virtualMachineAdminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${virtualMachineNamePrefix}${(i + 1)}-NIC1')
        }
      ]
    }
    virtualMachineScaleSet: {
      id: virtualMachineScaleSetName_resource.id
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  dependsOn: [
    virtualMachineScaleSetName_resource
    resourceId('Microsoft.Network/networkInterfaces', '${virtualMachineNamePrefix}${(i + 1)}-NIC1')
  ]
}]

resource virtualMachineNamePrefix_1_NIC1 'Microsoft.Network/networkInterfaces@2019-07-01' = [for i in range(0, virtualMachineCount): {
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

resource virtualMachineNamePrefix_1_PIP1 'Microsoft.Network/publicIPAddresses@2020-08-01' = [for i in range(0, virtualMachineCount): {
  name: '${virtualMachineNamePrefix}${(i + 1)}-PIP1'
  location: location
  zones: selectedZone
  tags: {
    displayName: '${virtualMachineNamePrefix}${(i + 1)}-PIP1'
  }
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: concat(dnsPrefixForPublicIP, (i + 1))
    }
  }
}]