@minValue(2)
@maxValue(20)
@description('Number of subnets in the VNet. Must be between 2 and 20')
param numberOfSubnets int = 3

@minValue(1)
@maxValue(20)
@description('Member servers for each subnet. Must be between 1 and 20')
param memberServersPerSubnet int = 1

@allowed([
  'Standard'
  'Premium'
])
@description('Storage type. Can be either Standard (HDD) or Premium (SSD)')
param storageCategory string = 'Standard'

@description('Domain to create for the Lab')
param domainName string = 'fabrikam.com'

@description('The location of resources such as templates and DSC modules that the script is dependent')
param assetLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/301-subnet-driven-deployment/'

@description('Admin username')
param adminUsername string

@description('Admin password')
@secure()
param adminPassword string

@description('Unique public DNS label for the deployment. The fqdn will look something like \'dnsname.region.cloudapp.azure.com\'. Up to 62 chars, digits or dashes, lowercase, should start with a letter: must conform to \'^[a-z][a-z0-9-]{1,61}[a-z0-9]$\'.')
param dnsLabelPrefix string

var vnetName = uniqueString(resourceGroup().id, 'labVNet')
var labVNetPrefix = '172.16.0.0/12'
var storageAccountSuffix = 'st'
var storageAccountType = '${storageCategory}_LRS'
var adDataDiskSize = '30'
var mbrDataDiskSize = '127'

module sbn0 'LabSubnet.bicep' = {
  name: 'sbn0'
  params: {
    labVNetPrefix: labVNetPrefix
    subnets: []
    addedSubnetName: 'sbn-Central'
    addedSubnetPrefix: '172.16.0.0/24'
    vnetName: vnetName
    dnsLabel: dnsLabelPrefix
  }
}

module sbn_1 'LabSubnet.bicep' = [for i in range(0, (numberOfSubnets + -1)): {
  name: 'sbn${(i + 1)}'
  params: {
    labVNetPrefix: labVNetPrefix
    subnets: reference('sbn${i}').outputs.vnetSubnets.value
    vnetName: vnetName
    dnsLabel: dnsLabelPrefix
    addedSubnetName: 'sbn-${(i + 1)}'
    addedSubnetPrefix: '172.16.${(i + 1)}.0/24'
  }
}]

module LabStorage 'Storage.bicep' = {
  name: 'LabStorage'
  params: {
    storageAccountSuffix: storageAccountSuffix
    storageAccountType: storageAccountType
  }
}

module Step0 'AVSet.bicep' = {
  name: 'Step0'
  params: {
    availabilitySetName: 'AVSetDC'
  }
}

module confDC0 'ConfigDC.bicep' = {
  name: 'confDC0'
  params: {
    indx: 0
    vmNamePrefix: ''
    computerName: 'dc'
    domainName: domainName
    adminUsername: adminUsername
    adminPassword: adminPassword
    assetLocation: assetLocation
  }
  dependsOn: [
    sbn0
    LabStorage
    dc0
  ]
}

module Step1 'SetVNetDNS.bicep' = {
  name: 'Step1'
  params: {
    dnsServerAddresses: [
      reference('dc0').outputs.vmIPAddress.value
    ]
    virtualNetworkName: vnetName
    virtualNetworkSubnets: reference('sbn${(numberOfSubnets + -1)}').outputs.vnetSubnets.value
    virtualNetworkAddressRanges: [
      labVNetPrefix
    ]
  }
  dependsOn: [
    dc0
  ]
}

module dc0 'WinServ.bicep' = {
  name: 'dc0'
  params: {
    indx: 0
    bootDiagnostics: (storageCategory == 'Standard')
    vmSize: 'Standard_DS2'
    lbName: reference('sbn0').outputs.lbName.value
    computerName: 'dc'
    publicIPAddressName: reference('sbn0').outputs.publicIPAddressName.value
    publicStartRdpPort: 5000
    vnetName: vnetName
    subnets: reference('sbn0').outputs.vnetSubnets.value
    storageAccountName: reference('LabStorage').outputs.storageAccountName.value
    availabilitySetName: 'AvSetDC'
    vmNamePrefix: ''
    nicNamePrefix: 'nic'
    adminUsername: adminUsername
    adminPassword: adminPassword
    assetLocation: assetLocation
    dDisks: [
      {
        name: 'dc0dataDisk0'
        caching: 'None'
        createOption: 'Empty'
        diskSizeGB: adDataDiskSize
        lun: 0
      }
    ]
  }
  dependsOn: [
    Step0
  ]
}

module dc_1 'WinServ.bicep' = [for i in range(0, (numberOfSubnets + -1)): {
  name: 'dc${(i + 1)}'
  params: {
    indx: (i + 1)
    bootDiagnostics: (storageCategory == 'Standard')
    vmSize: 'Standard_DS2'
    lbName: reference('sbn0').outputs.lbName.value
    computerName: 'dc'
    publicIPAddressName: reference('sbn0').outputs.publicIPAddressName.value
    publicStartRdpPort: 5000
    vnetName: vnetName
    subnets: reference('sbn${(numberOfSubnets + -1)}').outputs.vnetSubnets.value
    storageAccountName: reference('LabStorage').outputs.storageAccountName.value
    availabilitySetName: 'AvSetDC'
    vmNamePrefix: ''
    nicNamePrefix: 'nic'
    adminUsername: adminUsername
    adminPassword: adminPassword
    assetLocation: assetLocation
    dDisks: [
      {
        name: 'adDataDisk${(i + 1)}'
        caching: 'None'
        createOption: 'Empty'
        diskSizeGB: adDataDiskSize
        lun: 0
      }
    ]
  }
  dependsOn: [
    Step1
    dc0
  ]
}]

module Members 'WinServ.bicep' = [for i in range(0, (numberOfSubnets * memberServersPerSubnet)): {
  name: 'Members${i}'
  params: {
    indx: i
    bootDiagnostics: (storageCategory == 'Standard')
    vmSize: 'Standard_DS2'
    lbName: reference('sbn0').outputs.lbName.value
    computerName: 'srvMbmr'
    publicStartRdpPort: 6000
    publicIPAddressName: reference('sbn0').outputs.publicIPAddressName.value
    vnetName: vnetName
    subnets: reference('sbn${(numberOfSubnets + -1)}').outputs.vnetSubnets.value
    storageAccountName: reference('LabStorage').outputs.storageAccountName.value
    availabilitySetName: 'AVSetDC'
    adminUsername: adminUsername
    adminPassword: adminPassword
    assetLocation: assetLocation
    dDisks: [
      {
        name: 'dataDisk${i}'
        caching: 'None'
        createOption: 'Empty'
        diskSizeGB: mbrDataDiskSize
        lun: 0
      }
    ]
  }
  dependsOn: [
    Step1
    dc0
  ]
}]

module confDc_1 'ConfigDC.bicep' = [for i in range(0, (numberOfSubnets + -1)): {
  name: 'confDc${(i + 1)}'
  params: {
    indx: (i + 1)
    computerName: 'dc'
    vmNamePrefix: ''
    domainName: domainName
    adminUsername: adminUsername
    adminPassword: adminPassword
    assetLocation: assetLocation
  }
  dependsOn: [
    confDC0
    'Microsoft.Resources/deployments/dc${(i + 1)}'
  ]
}]

module confMembers 'confDomainMember.bicep' = [for i in range(0, (numberOfSubnets * memberServersPerSubnet)): {
  name: 'confMembers${i}'
  params: {
    indx: i
    computerName: 'srvMbmr'
    domainName: domainName
    domainJoinUsername: adminUsername
    domainJoinPassword: adminPassword
  }
  dependsOn: [
    confDC0
    'Microsoft.Resources/deployments/Members${i}'
  ]
}]

output vmIPAddress string = reference('dc0').outputs.vmIPAddress.value
output subnets array = reference('sbn${(numberOfSubnets + -1)}').outputs.vnetSubnets.value
output lenVnetSubnets int = reference('sbn${(numberOfSubnets + -1)}').outputs.vnetLength.value