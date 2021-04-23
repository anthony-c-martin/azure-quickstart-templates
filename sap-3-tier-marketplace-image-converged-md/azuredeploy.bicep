@minLength(3)
@maxLength(3)
@description('SAP System ID.')
param sapSystemId string

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
  'RHEL 7.2'
  'Oracle Linux 7.2'
])
@description('The type of the operating system you want to deploy.')
param osType string = 'Windows Server 2012 R2 Datacenter'

@allowed([
  'SQL'
  'HANA'
])
@description('The database type you want to use on the cluster. This information is used to create the load balancer')
param dbType string = 'SQL'

@allowed([
  'Demo'
  'Small < 30.000 SAPS'
  'Medium < 70.000 SAPS'
  'Large < 180.000 SAPS'
  'X-Large < 250.000 SAPS'
])
@description('The size of the SAP System you want to deploy.')
param sapSystemSize string = 'Small < 30.000 SAPS'

@allowed([
  'HA'
  'Not HA'
])
@description('Determines whether this is a high available deployment or not. A HA deployment contains multiple instances of single point of failures.')
param systemAvailability string = 'Not HA'

@description('Username for the Virtual Machine.')
param adminUsername string

@minLength(12)
@description('Password for the Virtual Machine.')
@secure()
param adminPassword string

@description('The id of the subnet you want to use. Leave blank if you want to create a new virtual network and subnet')
param subnetId string = ''

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/sap-3-tier-marketplace-image-converged-md/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

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
    sku: '12-SP1'
    offer: 'SLES-SAP'
    publisher: 'SUSE'
    version: 'latest'
    OSType: 'Linux'
    Plan: {}
    UsePlan: false
  }
  'SLES 12 BYOS': {
    sku: '12-SP1'
    offer: 'SLES-SAP-BYOS'
    publisher: 'SUSE'
    OSType: 'Linux'
    version: 'latest'
    Plan: {}
    UsePlan: false
  }
  'RHEL 7.2': {
    sku: '7.2'
    offer: 'RHEL'
    publisher: 'RedHat'
    version: 'latest'
    OSType: 'Linux'
    Plan: {}
    UsePlan: false
  }
  'Oracle Linux 7.2': {
    sku: '7.2'
    offer: 'Oracle-Linux'
    publisher: 'Oracle'
    version: 'latest'
    OSType: 'Linux'
    Plan: {}
    UsePlan: false
  }
}
var imageSku = images[osType].sku
var imagePublisher = images[osType].publisher
var imageOffer = images[osType].offer
var imageVersion = images[osType].version
var internalOSType = images[osType].OSType
var csExtension = {
  Windows: {
    script: '${artifactsLocation}/shared/noop.ps1${artifactsLocationSasToken}'
    scriptCall: 'powershell.exe -ExecutionPolicy bypass -File .\\shared\\noop.ps1'
  }
  Linux: {
    script: '${artifactsLocation}/shared/noop.sh${artifactsLocationSasToken}'
    scriptCall: 'sh noop.sh'
  }
}
var vmSizes = {
  Demo: {
    'Not HA': {
      clserversize: 'Standard_DS12_v2'
      clservercount: 1
      clserverdisks: [
        {
          size: 128
        }
      ]
      diserversize: 'Standard_DS2_v2'
      diservercount: 1
    }
    HA: {
      clserversize: 'Standard_DS12_v2'
      clservercount: 2
      clserverdisks: [
        {
          size: 128
        }
      ]
      diserversize: 'Standard_DS2_v2'
      diservercount: 2
    }
  }
  'Small < 30.000 SAPS': {
    'Not HA': {
      clserversize: 'Standard_DS13_v2'
      clservercount: 1
      clserverdisks: [
        {
          size: 512
        }
        {
          size: 512
        }
        {
          size: 512
        }
        {
          size: 512
        }
        {
          size: 512
        }
      ]
      diserversize: 'Standard_DS13_v2'
      diservercount: 1
    }
    HA: {
      clserversize: 'Standard_DS13_v2'
      clservercount: 2
      clserverdisks: [
        {
          size: 512
        }
        {
          size: 512
        }
        {
          size: 512
        }
        {
          size: 512
        }
        {
          size: 512
        }
      ]
      diserversize: 'Standard_DS13_v2'
      diservercount: 2
    }
  }
  'Medium < 70.000 SAPS': {
    'Not HA': {
      clserversize: 'Standard_DS14_v2'
      clservercount: 1
      clserverdisks: [
        {
          size: 512
        }
        {
          size: 512
        }
        {
          size: 512
        }
        {
          size: 512
        }
        {
          size: 512
        }
        {
          size: 512
        }
        {
          size: 512
        }
      ]
      diserversize: 'Standard_DS13_v2'
      diservercount: 4
    }
    HA: {
      clserversize: 'Standard_DS14_v2'
      clservercount: 2
      clserverdisks: [
        {
          size: 512
        }
        {
          size: 512
        }
        {
          size: 512
        }
        {
          size: 512
        }
        {
          size: 512
        }
        {
          size: 512
        }
        {
          size: 512
        }
      ]
      diserversize: 'Standard_DS13_v2'
      diservercount: 4
    }
  }
  'Large < 180.000 SAPS': {
    'Not HA': {
      clserversize: 'Standard_GS4'
      clservercount: 1
      clserverdisks: [
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 512
        }
      ]
      diserversize: 'Standard_DS14_v2'
      diservercount: 6
    }
    HA: {
      clserversize: 'Standard_GS4'
      clservercount: 2
      clserverdisks: [
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 512
        }
      ]
      diserversize: 'Standard_DS14_v2'
      diservercount: 6
    }
  }
  'X-Large < 250.000 SAPS': {
    'Not HA': {
      clserversize: 'Standard_GS5'
      clservercount: 1
      clserverdisks: [
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
      ]
      diserversize: 'Standard_DS14_v2'
      diservercount: 10
    }
    HA: {
      clserversize: 'Standard_GS5'
      clservercount: 2
      clserverdisks: [
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
        {
          size: 1023
        }
      ]
      diserversize: 'Standard_DS14_v2'
      diservercount: 10
    }
  }
}
var clvmCount = vmSizes[sapSystemSize][systemAvailability].clservercount
var clvmDataDisks = vmSizes[sapSystemSize][systemAvailability].clserverdisks
var divmCount = vmSizes[sapSystemSize][systemAvailability].diservercount
var sidlower = toLower(sapSystemId)
var vmName = sidlower
var vnetName = '${sidlower}-vnet'
var publicIPAddressType = 'Dynamic'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var subnets = {
  true: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
  false: subnetId
}
var selectedSubnetId = subnets[string((length(subnetId) == 0))]
var nestedDeploymentName = 'nestedTemplate'
var nestedDeploymentNameVNet_var = '${nestedDeploymentName}vnet'
var nestedDeploymentNamePIP_var = '${nestedDeploymentName}pip'
var nestedDeploymentNameCL_var = '${nestedDeploymentName}cl'
var nestedDeploymentNameDI_var = '${nestedDeploymentName}di'
var nestedDeploymentNameProf = '${nestedDeploymentName}prof'
var nestedDeploymentNameNIC = '${nestedDeploymentName}nic'
var nestedDeploymentNameNICCL_var = '${nestedDeploymentNameNIC}cl'
var nestedDeploymentNameNICDI_var = '${nestedDeploymentNameNIC}di'
var nestedDeploymentNameLBCL_var = '${nestedDeploymentName}lbcl'
var publicIpNameCL = '${sidlower}-pip-cl'
var avSetNameCL_var = '${sidlower}-avset-cl'
var nestedDeploymentNameNSG_var = '${nestedDeploymentNameCL_var}nsg'
var nsgNameCL = '${sidlower}-nsg'
var loadBalancerNameCL = '${sidlower}-lb-cl'
var vmNameCL = '${vmName}-cl'
var nicNameCL_var = '${sidlower}-nic-cl'
var avSetNameDI_var = '${sidlower}-avset-di'
var nicNameDI_var = '${sidlower}-nic-di'
var vmNameDI = '${vmName}-di'
var osDiskType = 'image'

module nestedDeploymentNameNSG '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/newnsg.json', parameters('_artifactsLocationSasToken'))]*/ = if (length(subnetId) == 0) {
  name: nestedDeploymentNameNSG_var
  params: {
    nsgName: nsgNameCL
    osType: internalOSType
  }
}

module nestedDeploymentNameVnet '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/newvnetnsg.json', parameters('_artifactsLocationSasToken'))]*/ = if (length(subnetId) == 0) {
  name: nestedDeploymentNameVNet_var
  params: {
    vnetName: vnetName
    addressPrefix: addressPrefix
    subnetName: subnetName
    subnetPrefix: subnetPrefix
    nsgName: nsgNameCL
  }
  dependsOn: [
    nestedDeploymentNameNSG
  ]
}

resource avSetNameCL 'Microsoft.Compute/availabilitySets@2016-04-30-preview' = {
  name: avSetNameCL_var
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 3
    platformUpdateDomainCount: 20
  }
}

module nestedDeploymentNamePIP '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/newpip.json', parameters('_artifactsLocationSasToken'))]*/ = [for i in range(0, clvmCount): {
  name: '${nestedDeploymentNamePIP_var}-${i}'
  params: {
    publicIpName: '${publicIpNameCL}-${i}'
    publicIPAddressType: publicIPAddressType
  }
}]

module nestedDeploymentNameLBCL '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/loadbalancer.json', parameters('_artifactsLocationSasToken'))]*/ = {
  name: nestedDeploymentNameLBCL_var
  params: {
    loadBalancerName: loadBalancerNameCL
    sapSystemCount: 1
    stackType: stackType
    osType: internalOSType
    createXSCS: true
    createDB: true
    dbType: dbType
    subnetId: selectedSubnetId
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    nestedDeploymentNameVnet
  ]
}

module nestedDeploymentNameNICCL '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/nic-config.json', parameters('_artifactsLocationSasToken'))]*/ = [for i in range(0, clvmCount): {
  name: '${nestedDeploymentNameNICCL_var}-${i}'
  params: {
    vnetName: vnetName
    subnetName: subnetName
    publicIpName: '${publicIpNameCL}-${i}'
    nsgName: ''
    subnetId: subnetId
  }
}]

resource nicNameCL 'Microsoft.Network/networkInterfaces@2017-06-01' = [for i in range(0, clvmCount): {
  name: '${nicNameCL_var}-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: reference('${nestedDeploymentNameNICCL_var}-${i}').outputs.selectedConfiguration.value.publicIPAddress
          subnet: reference('${nestedDeploymentNameNICCL_var}-${i}').outputs.selectedConfiguration.value.subnet
          loadBalancerBackendAddressPools: reference(nestedDeploymentNameLBCL_var).outputs.nicBackAddressPools.value
        }
      }
    ]
  }
  dependsOn: [
    nestedDeploymentNamePIP
    nestedDeploymentNameNICCL
    nestedDeploymentNameVnet
    nestedDeploymentNameLBCL
  ]
}]

module nestedDeploymentNameProf_cl '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/os-disk-parts-md.json', parameters('_artifactsLocationSasToken'))]*/ = [for i in range(0, clvmCount): {
  name: '${nestedDeploymentNameProf}-cl-${i}'
  params: {
    imageSku: imageSku
    imagePublisher: imagePublisher
    imageOffer: imageOffer
    imageVersion: imageVersion
    osDiskType: osDiskType
    osType: internalOSType
    vmName: '${vmNameCL}-${i}'
    storageType: 'Premium_LRS'
  }
}]

module nestedDeploymentNameCL '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/server-md.json', parameters('_artifactsLocationSasToken'))]*/ = [for i in range(0, clvmCount): {
  name: '${nestedDeploymentNameCL_var}-${i}'
  params: {
    imageReference: reference('${nestedDeploymentNameProf}-cl-${i}').outputs.imageReference.value
    osDisk: reference('${nestedDeploymentNameProf}-cl-${i}').outputs.osDisk.value
    osDiskType: osDiskType
    vmName: '${vmNameCL}-${i}'
    vmSize: vmSizes[sapSystemSize][systemAvailability].clserversize
    adminUsername: adminUsername
    adminPassword: adminPassword
    csExtensionScript: csExtension[internalOSType].script
    csExtensionscriptCall: csExtension[internalOSType].scriptCall
    csExtensionscriptArgs: ''
    avSetObj: {
      id: avSetNameCL.id
    }
    useAVSet: true
    nicName: '${nicNameCL_var}-${i}'
    dataDisksObj: {
      dataDisks: [for (item, j) in clvmDataDisks: {
        lun: j
        createOption: 'Empty'
        diskSizeGB: item.size
      }]
    }
    osType: internalOSType
  }
  dependsOn: [
    nicNameCL
    avSetNameCL
    nestedDeploymentNameProf_cl
  ]
}]

resource avSetNameDI 'Microsoft.Compute/availabilitySets@2017-03-30' = {
  name: avSetNameDI_var
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 3
    platformUpdateDomainCount: 20
  }
}

module nestedDeploymentNameNICDI '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/nic-config.json', parameters('_artifactsLocationSasToken'))]*/ = [for i in range(0, divmCount): {
  name: '${nestedDeploymentNameNICDI_var}-${i}'
  params: {
    vnetName: vnetName
    subnetName: subnetName
    publicIpName: ''
    nsgName: ''
    subnetId: subnetId
  }
}]

resource nicNameDI 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, divmCount): {
  name: '${nicNameDI_var}-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: reference('${nestedDeploymentNameNICDI_var}-${i}').outputs.selectedConfiguration.value.subnet
        }
      }
    ]
  }
  dependsOn: [
    nestedDeploymentNameVnet
    nestedDeploymentNameNICDI
  ]
}]

module nestedDeploymentNameProf_di '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/os-disk-parts-md.json', parameters('_artifactsLocationSasToken'))]*/ = [for i in range(0, divmCount): {
  name: '${nestedDeploymentNameProf}-di-${i}'
  params: {
    imageSku: imageSku
    imagePublisher: imagePublisher
    imageOffer: imageOffer
    imageVersion: imageVersion
    osDiskType: osDiskType
    osType: internalOSType
    vmName: '${vmNameDI}-${i}'
    storageType: 'Premium_LRS'
  }
}]

module nestedDeploymentNameDI '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/server-md.json', parameters('_artifactsLocationSasToken'))]*/ = [for i in range(0, divmCount): {
  name: '${nestedDeploymentNameDI_var}-${i}'
  params: {
    imageReference: reference('${nestedDeploymentNameProf}-di-${i}').outputs.imageReference.value
    osDisk: reference('${nestedDeploymentNameProf}-di-${i}').outputs.osDisk.value
    osDiskType: osDiskType
    vmName: '${vmNameDI}-${i}'
    vmSize: vmSizes[sapSystemSize][systemAvailability].diserversize
    adminUsername: adminUsername
    adminPassword: adminPassword
    csExtensionScript: csExtension[internalOSType].script
    csExtensionscriptCall: csExtension[internalOSType].scriptCall
    csExtensionscriptArgs: ''
    avSetObj: {
      id: avSetNameDI.id
    }
    useAVSet: true
    nicName: '${nicNameDI_var}-${i}'
    dataDisksObj: {
      dataDisks: [for j in range(0, 1): {
        lun: 0
        createOption: 'Empty'
        diskSizeGB: 128
      }]
    }
    osType: internalOSType
  }
  dependsOn: [
    nicNameDI
    avSetNameDI
    nestedDeploymentNameProf_di
  ]
}]