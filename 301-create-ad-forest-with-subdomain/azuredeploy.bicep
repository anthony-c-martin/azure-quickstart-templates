@description('Do you want a child domain? If false, the parameters for the child domain are ignored. ')
param createChildDomain bool = true

@description('Do you want a second DC in each domain? If false: parameters for DC2 and DC4 are ignored. ')
param createSecondDc bool = false

@minLength(4)
@description('Full FQDN name for the forest root domain.')
param DomainName string = 'contoso.com'

@minLength(2)
@maxLength(15)
@description('SHORT name for the child domain. New AD trees are not allowed.')
param ChildDomainName string = 'child'

@minLength(6)
@description('The name of the admin account for the Domain(s)')
param adminUsername string

@minLength(8)
@description('The (complex!) password for the Administrator account of the new VMs and Domain(s)')
@secure()
param adminPassword string

@description('The size and type of the VM. *_DS* or *s types support Premium Disks. Hint: the DS* series seem most reliable for this complex template.')
param VMSize string = 'Standard_DS1_v2'

@allowed([
  '2016-Datacenter'
  '2019-Datacenter'
])
@description('Windows Server Version.')
param imageSKU string = '2019-Datacenter'

@allowed([
  'StandardSSD_LRS'
  'Standard_LRS'
  'Premium_LRS'
])
@description('The Storage type of the data Disks. Use Premium_LRS only with *s or *DS* VM types.')
param diskType string = 'Premium_LRS'

@minLength(2)
@maxLength(16)
@description('The name of the new VNET for the DC(s).')
param virtualNetworkName string = 'adVNET'

@description('The address range of the new VNET in CIDR format.')
param virtualNetworkAddressRange string = '10.0.0.0/22'

@description('DNS forwarder for all non-domain (external) related DNS queries.')
param externalDNSForwarder string = '168.63.129.16'

@minLength(2)
@maxLength(16)
@description('The name of the VM subnet created in the new VNET.')
param adSubnetName string = 'adSubnet'

@description('The address range of the subnet created in the new VNET.')
param adSubnet string = '10.0.0.0/24'

@minLength(2)
@maxLength(15)
@description('The computer name of the first DC of the root domain.')
param RootDC1Name string = 'rootdc1'

@description('The IP address of the first DC of the root domain.')
param RootDC1IPAddress string = '10.0.0.4'

@minLength(2)
@maxLength(15)
@description('The computer name of the second DC of the root domain.')
param RootDC2Name string = 'rootdc2'

@description('The IP address of the second DC of the root domain.')
param RootDC2IPAddress string = '10.0.0.5'

@minLength(2)
@maxLength(15)
@description('The computer name of the first DC of the CHILD domain.')
param ChildDC3Name string = 'childdc3'

@description('The IP address of the first DC of the CHILD domain.')
param ChildDC3IPAddress string = '10.0.0.6'

@minLength(2)
@maxLength(15)
@description('The computer name of the second DC of the CHILD domain.')
param ChildDC4Name string = 'childdc4'

@description('The IP address of the second DC of the CHILD domain.')
param ChildDC4IPAddress string = '10.0.0.7'

@description('Location for all resources; takes its default from the Resource Group.')
param location string = resourceGroup().location

@description('The location of resources such as templates and DSC modules that the script depends on. No need to change unless you copy or fork this template.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/301-create-ad-forest-with-subdomain/'

@description('SAS storage token to access _artifactsLocation. No need to change unless you copy or fork this template.')
@secure()
param artifactsLocationSasToken string = ''

var adNSGName_var = '${adSubnetName}NSG'
var adAvailabilitySetNameRoot_var = 'AvailSetRoot'
var adAvailabilitySetNameChild_var = 'AvailSetChild'
var firstVMTemplateUri = uri(artifactsLocation, 'nested/CreateAndPrepnewVM.json${artifactsLocationSasToken}')
var nextVMTemplateUri = uri(artifactsLocation, 'nested/CreateAndPrepnewVM.json${artifactsLocationSasToken}')
var vnetTemplateUri = uri(artifactsLocation, 'nested/vnet.json${artifactsLocationSasToken}')
var vnetwithDNSTemplateUri = uri(artifactsLocation, 'nested/vnet-with-dns-server.json${artifactsLocationSasToken}')
var configureADNextDCTemplateUri = uri(artifactsLocation, 'nested/configureADNextDC.json${artifactsLocationSasToken}')
var createForestTemplateUri = uri(artifactsLocation, 'nested/createForest.json${artifactsLocationSasToken}')
var createChildDomainTemplateUri = uri(artifactsLocation, 'nested/createChildDomain.json${artifactsLocationSasToken}')
var nextDCConfigurationModulesURL = uri(artifactsLocation, 'DSC/ConfigureADNextDC.ps1.zip${artifactsLocationSasToken}')
var nextDCConfigurationFunction = 'ConfigureADNextDC.ps1\\ConfigureADNextDC'

resource adAvailabilitySetNameRoot 'Microsoft.Compute/availabilitySets@2019-12-01' = {
  name: adAvailabilitySetNameRoot_var
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformUpdateDomainCount: 3
    platformFaultDomainCount: 2
  }
}

resource adAvailabilitySetNameChild 'Microsoft.Compute/availabilitySets@2019-12-01' = if (createChildDomain) {
  name: adAvailabilitySetNameChild_var
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformUpdateDomainCount: 3
    platformFaultDomainCount: 2
  }
}

module CreateVNET '?' /*TODO: replace with correct path to [variables('vnetTemplateUri')]*/ = {
  name: 'CreateVNET'
  params: {
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: virtualNetworkAddressRange
    subnetName: adSubnetName
    subnetRange: adSubnet
    location: location
  }
}

resource adNSGName 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: adNSGName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow_Any_RDP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
    ]
  }
  dependsOn: [
    CreateVNET
  ]
}

module CreateADVM1 '?' /*TODO: replace with correct path to [variables('firstVMTemplateUri')]*/ = {
  name: 'CreateADVM1'
  params: {
    virtualNetworkName: virtualNetworkName
    subnetName: adSubnetName
    adAvailabilitySetName: adAvailabilitySetNameRoot_var
    vmName: RootDC1Name
    vmIpAddress: RootDC1IPAddress
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: VMSize
    diskType: diskType
    imageSKU: imageSKU
    location: location
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    CreateVNET
    adAvailabilitySetNameRoot
  ]
}

module CreateForest '?' /*TODO: replace with correct path to [variables('createForestTemplateUri')]*/ = {
  name: 'CreateForest'
  params: {
    vmName: RootDC1Name
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    domainName: DomainName
    DNSForwarder: externalDNSForwarder
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    CreateADVM1
  ]
}

module CreateADVM3 '?' /*TODO: replace with correct path to [variables('firstVMTemplateUri')]*/ = if (createChildDomain) {
  name: 'CreateADVM3'
  params: {
    virtualNetworkName: virtualNetworkName
    subnetName: adSubnetName
    adAvailabilitySetName: adAvailabilitySetNameChild_var
    vmName: ChildDC3Name
    vmIpAddress: ChildDC3IPAddress
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: VMSize
    diskType: diskType
    imageSKU: imageSKU
    location: location
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    CreateVNET
    adAvailabilitySetNameChild
  ]
}

module CreateChildDomain_resource '?' /*TODO: replace with correct path to [variables('createChildDomainTemplateUri')]*/ = if (createChildDomain) {
  name: 'CreateChildDomain'
  params: {
    vmName: ChildDC3Name
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    parentDomainName: DomainName
    childDomainName: ChildDomainName
    DNSForwarder: RootDC1IPAddress
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    CreateADVM3
    CreateForest
  ]
}

module CreateADVM2 '?' /*TODO: replace with correct path to [variables('nextVMTemplateUri')]*/ = if (createSecondDc) {
  name: 'CreateADVM2'
  params: {
    virtualNetworkName: virtualNetworkName
    subnetName: adSubnetName
    adAvailabilitySetName: adAvailabilitySetNameRoot_var
    vmName: RootDC2Name
    vmIpAddress: RootDC2IPAddress
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: VMSize
    diskType: diskType
    imageSKU: imageSKU
    location: location
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    CreateVNET
    adAvailabilitySetNameRoot
  ]
}

module ConfiguringRootDC2 '?' /*TODO: replace with correct path to [variables('configureADNextDCTemplateUri')]*/ = if (createSecondDc) {
  name: 'ConfiguringRootDC2'
  params: {
    adNextDCVMName: RootDC2Name
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    domainName: DomainName
    DNSServer: RootDC1IPAddress
    adNextDCConfigurationFunction: nextDCConfigurationFunction
    adNextDCConfigurationModulesURL: nextDCConfigurationModulesURL
  }
  dependsOn: [
    CreateADVM2
    CreateChildDomain_resource
  ]
}

module CreateADVM4 '?' /*TODO: replace with correct path to [variables('nextVMTemplateUri')]*/ = if (createSecondDc && createChildDomain) {
  name: 'CreateADVM4'
  params: {
    virtualNetworkName: virtualNetworkName
    subnetName: adSubnetName
    adAvailabilitySetName: adAvailabilitySetNameChild_var
    vmName: ChildDC4Name
    vmIpAddress: ChildDC4IPAddress
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: VMSize
    diskType: diskType
    imageSKU: imageSKU
    location: location
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    CreateVNET
    adAvailabilitySetNameChild
  ]
}

module ConfiguringChildDC4 '?' /*TODO: replace with correct path to [variables('configureADNextDCTemplateUri')]*/ = if (createSecondDc && createChildDomain) {
  name: 'ConfiguringChildDC4'
  params: {
    adNextDCVMName: ChildDC4Name
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    domainName: '${ChildDomainName}.${DomainName}'
    DNSServer: ChildDC3IPAddress
    adNextDCConfigurationFunction: nextDCConfigurationFunction
    adNextDCConfigurationModulesURL: nextDCConfigurationModulesURL
  }
  dependsOn: [
    CreateADVM4
    CreateChildDomain_resource
  ]
}

module UpdateVNet '?' /*TODO: replace with correct path to [variables('vnetwithDNSTemplateUri')]*/ = {
  name: 'UpdateVNet'
  params: {
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: virtualNetworkAddressRange
    subnetName: adSubnetName
    subnetRange: adSubnet
    NSGName: adNSGName_var
    DNSServerAddress: [
      RootDC1IPAddress
      RootDC2IPAddress
    ]
    location: location
  }
  dependsOn: [
    CreateChildDomain_resource
  ]
}