@minLength(3)
@maxLength(6)
@description('The prefix that should be used to create the resource names.')
param resourcePrefix string = 'MULTI'

@allowed([
  'ABAP'
  'JAVA'
  'ABAP+JAVA'
])
@description('The stack type of the SAP system.')
param stackType string = 'ABAP'

@allowed([
  'Windows Server 2012 Datacenter'
  'Windows Server 2012 R2 Datacenter'
  'Windows Server 2016 Datacenter'
  'SLES 12'
  'SLES 12 BYOS'
  'RHEL 7'
  'Oracle Linux 7'
])
@description('The type of the operating system you want to deploy.')
param osType string = 'Windows Server 2016 Datacenter'

@minValue(1)
@maxValue(10)
@description('The number of SAP systems of this multi SID setup.')
param sapSystemCount int = 2

@allowed([
  'HA'
  'Not HA'
])
@description('Determines whether this is a high available deployment or not. A HA deployment contains multiple instances of single point of failures.')
param systemAvailability string = 'Not HA'

@description('Username for the Virtual Machine.')
param adminUsername string

@allowed([
  'password'
  'sshPublicKey'
])
@description('Type of authentication to use on the Virtual Machine.')
param authenticationType string = 'password'

@description('Password or ssh key for the Virtual Machine.')
@secure()
param adminPasswordOrKey string

@description('The id of the subnet you want to use.')
param subnetId string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/sap-3-tier-marketplace-image-multi-sid-xscs-md/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var images = {
  'Windows Server 2012 Datacenter': {
    sku: '2012-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    version: 'latest'
    OSType: 'Windows'
    Plan: {}
    UsePlan: false
  }
  'Windows Server 2012 R2 Datacenter': {
    sku: '2012-R2-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    version: 'latest'
    OSType: 'Windows'
    Plan: {}
    UsePlan: false
  }
  'Windows Server 2016 Datacenter': {
    sku: '2016-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    version: 'latest'
    OSType: 'Windows'
    Plan: {}
    UsePlan: false
  }
  'SLES 12': {
    sku: '12-SP3'
    offer: 'SLES-SAP'
    publisher: 'SUSE'
    version: 'latest'
    OSType: 'Linux'
    Plan: {}
    UsePlan: false
  }
  'SLES 12 BYOS': {
    sku: '12-SP3'
    offer: 'SLES-SAP-BYOS'
    publisher: 'SUSE'
    version: 'latest'
    OSType: 'Linux'
    Plan: {}
    UsePlan: false
  }
  'RHEL 7': {
    sku: '7.4'
    offer: 'RHEL'
    publisher: 'RedHat'
    version: 'latest'
    OSType: 'Linux'
    Plan: {}
    UsePlan: false
  }
  'Oracle Linux 7': {
    sku: '7.3'
    offer: 'Oracle-Linux'
    publisher: 'Oracle'
    version: 'latest'
    OSType: 'Linux'
    Plan: {}
    UsePlan: false
  }
}
var internalOSType = images[osType].OSType
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}
var systemCountSizes = {
  '1': {
    Size: 'Small'
  }
  '2': {
    Size: 'Small'
  }
  '3': {
    Size: 'Small'
  }
  '4': {
    Size: 'Medium'
  }
  '5': {
    Size: 'Medium'
  }
  '6': {
    Size: 'Medium'
  }
  '7': {
    Size: 'Medium'
  }
  '8': {
    Size: 'Large'
  }
  '9': {
    Size: 'Large'
  }
  '10': {
    Size: 'Large'
  }
}
var vmSizes = {
  Small: {
    'Not HA': {
      xscsserversize: 'Standard_DS2_v2'
      xscsservercount: 1
    }
    HA: {
      xscsserversize: 'Standard_DS2_v2'
      xscsservercount: 2
    }
  }
  Medium: {
    'Not HA': {
      xscsserversize: 'Standard_DS3_v2'
      xscsservercount: 1
    }
    HA: {
      xscsserversize: 'Standard_DS3_v2'
      xscsservercount: 2
    }
  }
  Large: {
    'Not HA': {
      xscsserversize: 'Standard_DS4_v2'
      xscsservercount: 1
    }
    HA: {
      xscsserversize: 'Standard_DS4_v2'
      xscsservercount: 2
    }
  }
}
var xscsvmSize = vmSizes[systemCountSizes[string(sapSystemCount)].Size][systemAvailability].xscsserversize
var xscsvmCount = vmSizes[systemCountSizes[string(sapSystemCount)].Size][systemAvailability].xscsservercount
var sidlower = toLower(resourcePrefix)
var vmName = sidlower
var vnetName_var = '${sidlower}-vnet'
var subnetName = 'Subnet'
var subnets = {
  true: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnetName)
  false: subnetId
}
var selectedSubnetId = subnets[string((length(subnetId) == 0))]
var nestedDeploymentNameLBXSCS_var = '${deployment().name}-lbxscs'
var publicIpNameXSCS_var = '${sidlower}-pip-xscs'
var avSetNameXSCS_var = '${sidlower}-avset-xscs'
var nsgNameXSCS_var = '${sidlower}-nsg'
var osSecurityRules = {
  Windows: [
    {
      name: 'RDP'
      properties: {
        description: 'Allow RDP Subnet'
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
  Linux: [
    {
      name: 'SSH'
      properties: {
        description: 'Allow SSH Subnet'
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
var selectedSecurityRules = osSecurityRules[internalOSType]
var loadBalancerNameXSCS = '${sidlower}-lb-xscs'
var vmNameXSCS_var = '${vmName}-xscs'
var nicNameXSCS_var = '${sidlower}-nic-xscs'

resource nsgNameXSCS 'Microsoft.Network/networkSecurityGroups@2018-04-01' = if (length(subnetId) == 0) {
  name: concat(nsgNameXSCS_var)
  location: location
  properties: {
    securityRules: selectedSecurityRules
  }
}

resource vnetName 'Microsoft.Network/virtualNetworks@2018-04-01' = if (length(subnetId) == 0) {
  name: vnetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsgNameXSCS.id
          }
        }
      }
    ]
  }
}

resource avSetNameXSCS 'Microsoft.Compute/availabilitySets@2017-03-30' = {
  name: avSetNameXSCS_var
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 20
  }
}

resource publicIpNameXSCS 'Microsoft.Network/publicIPAddresses@2018-04-01' = [for i in range(0, xscsvmCount): if (length(subnetId) == 0) {
  name: '${publicIpNameXSCS_var}-${i}'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  dependsOn: [
    vnetName
  ]
}]

module nestedDeploymentNameLBXSCS '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('nestedtemplates/loadbalancer.json', parameters('_artifactsLocationSasToken')))]*/ = if (xscsvmCount > 1) {
  name: nestedDeploymentNameLBXSCS_var
  params: {
    loadBalancerName: loadBalancerNameXSCS
    sapSystemCount: sapSystemCount
    stackType: stackType
    osType: internalOSType
    subnetId: selectedSubnetId
    location: location
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    vnetName
  ]
}

resource nicNameXSCS 'Microsoft.Network/networkInterfaces@2017-06-01' = [for i in range(0, xscsvmCount): {
  name: '${nicNameXSCS_var}-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: ((length(subnetId) == 0) ? json('{"id": "${resourceId('Microsoft.Network/publicIPAddresses', '${publicIpNameXSCS_var}-${i}')}"}') : json('null'))
          subnet: {
            id: selectedSubnetId
          }
          loadBalancerBackendAddressPools: ((xscsvmCount > 1) ? reference(nestedDeploymentNameLBXSCS_var, '2017-05-10').outputs.nicBackAddressPools.value : json('null'))
        }
      }
    ]
  }
  dependsOn: [
    publicIpNameXSCS
    vnetName
    nestedDeploymentNameLBXSCS
  ]
}]

resource vmNameXSCS 'Microsoft.Compute/virtualMachines@2017-12-01' = [for i in range(0, xscsvmCount): {
  name: '${vmNameXSCS_var}-${i}'
  location: location
  properties: {
    availabilitySet: {
      id: avSetNameXSCS.id
    }
    hardwareProfile: {
      vmSize: xscsvmSize
    }
    osProfile: {
      computerName: '${vmNameXSCS_var}-${i}'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: images[osType].publisher
        offer: images[osType].offer
        sku: images[osType].sku
        version: 'latest'
      }
      osDisk: {
        name: '${vmNameXSCS_var}-${i}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: [for j in range(0, sapSystemCount): {
        lun: j
        createOption: 'Empty'
        diskSizeGB: 128
      }]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${nicNameXSCS_var}-${i}')
        }
      ]
    }
  }
  dependsOn: [
    nicNameXSCS
    avSetNameXSCS
  ]
}]