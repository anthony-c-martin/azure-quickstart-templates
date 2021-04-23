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
  'Windows'
  'Linux'
])
@description('The operating system type of the private OS image.')
param osType string

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

@description('Id of the user image.')
param userImageId string

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@secure()
param adminPassword string

@description('The id of the subnet you want to use.')
param subnetId string = ''

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/sap-3-tier-user-image-md/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

var internalOSType = osType
var csExtension = {
  Windows: {
    script: '${artifactsLocation}/shared/configureSAPVM.ps1${artifactsLocationSasToken}'
    scriptCall: 'powershell.exe -ExecutionPolicy bypass -File .\\shared\\configureSAPVM.ps1'
  }
  Linux: {
    script: '${artifactsLocation}/shared/configureSAPVM.sh${artifactsLocationSasToken}'
    scriptCall: 'sh configureSAPVM.sh'
  }
}
var vmSizes = {
  Demo: {
    'Not HA': {
      dbserversize: 'Standard_DS12_v2'
      dbservercount: 1
      dbserverdisks: [
        {
          size: 128
        }
      ]
      ascsserversize: 'Standard_DS2_v2'
      ascsservercount: 1
      diserversize: 'Standard_DS2_v2'
      diservercount: 1
    }
    HA: {
      dbserversize: 'Standard_DS12_v2'
      dbservercount: 2
      dbserverdisks: [
        {
          size: 128
        }
      ]
      ascsserversize: 'Standard_DS2_v2'
      ascsservercount: 2
      diserversize: 'Standard_DS2_v2'
      diservercount: 2
    }
  }
  'Small < 30.000 SAPS': {
    'Not HA': {
      dbserversize: 'Standard_DS13_v2'
      dbservercount: 1
      dbserverdisks: [
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
      ascsserversize: 'Standard_DS11_v2'
      ascsservercount: 1
      diserversize: 'Standard_DS13_v2'
      diservercount: 1
    }
    HA: {
      dbserversize: 'Standard_DS13_v2'
      dbservercount: 2
      dbserverdisks: [
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
      ascsserversize: 'Standard_DS11_v2'
      ascsservercount: 2
      diserversize: 'Standard_DS13_v2'
      diservercount: 2
    }
  }
  'Medium < 70.000 SAPS': {
    'Not HA': {
      dbserversize: 'Standard_DS14_v2'
      dbservercount: 1
      dbserverdisks: [
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
      ascsserversize: 'Standard_DS11_v2'
      ascsservercount: 1
      diserversize: 'Standard_DS13_v2'
      diservercount: 4
    }
    HA: {
      dbserversize: 'Standard_DS14_v2'
      dbservercount: 2
      dbserverdisks: [
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
      ascsserversize: 'Standard_DS11_v2'
      ascsservercount: 2
      diserversize: 'Standard_DS13_v2'
      diservercount: 4
    }
  }
  'Large < 180.000 SAPS': {
    'Not HA': {
      dbserversize: 'Standard_GS4'
      dbservercount: 1
      dbserverdisks: [
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
      ascsserversize: 'Standard_DS11_v2'
      ascsservercount: 1
      diserversize: 'Standard_DS14_v2'
      diservercount: 6
    }
    HA: {
      dbserversize: 'Standard_GS4'
      dbservercount: 2
      dbserverdisks: [
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
      ascsserversize: 'Standard_DS11_v2'
      ascsservercount: 2
      diserversize: 'Standard_DS14_v2'
      diservercount: 6
    }
  }
  'X-Large < 250.000 SAPS': {
    'Not HA': {
      dbserversize: 'Standard_GS5'
      dbservercount: 1
      dbserverdisks: [
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
      ascsserversize: 'Standard_DS11_v2'
      ascsservercount: 1
      diserversize: 'Standard_DS14_v2'
      diservercount: 10
    }
    HA: {
      dbserversize: 'Standard_GS5'
      dbservercount: 2
      dbserverdisks: [
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
      ascsserversize: 'Standard_DS11_v2'
      ascsservercount: 2
      diserversize: 'Standard_DS14_v2'
      diservercount: 10
    }
  }
}
var dbvmCount = vmSizes[sapSystemSize][systemAvailability].dbservercount
var dbvmDataDisks = vmSizes[sapSystemSize][systemAvailability].dbserverdisks
var ascsvmCount = vmSizes[sapSystemSize][systemAvailability].ascsservercount
var divmCount = vmSizes[sapSystemSize][systemAvailability].diservercount
var sidlower = toLower(sapSystemId)
var vmName = sidlower
var vnetName = '${sidlower}-vnet'
var subnetName = 'Subnet'
var subnets = {
  true: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
  false: subnetId
}
var selectedSubnetId = subnets[string((length(subnetId) == 0))]
var nestedDeploymentName = 'nestedTemplate'
var nestedDeploymentNameVNet_var = '${nestedDeploymentName}vnet'
var nestedDeploymentNamePIP_var = '${nestedDeploymentName}pip'
var nestedDeploymentNameASCS_var = '${nestedDeploymentName}ascs'
var nestedDeploymentNameDB_var = '${nestedDeploymentName}db'
var nestedDeploymentNameDI_var = '${nestedDeploymentName}di'
var nestedDeploymentNameProf = '${nestedDeploymentName}prof'
var nestedDeploymentNameNIC = '${nestedDeploymentName}nic'
var nestedDeploymentNameNICASCS_var = '${nestedDeploymentNameNIC}ascs'
var nestedDeploymentNameNICDB_var = '${nestedDeploymentNameNIC}db'
var nestedDeploymentNameNICDI_var = '${nestedDeploymentNameNIC}di'
var nestedDeploymentNameLBASCS_var = '${nestedDeploymentName}lbascs'
var nestedDeploymentNameLBDB_var = '${nestedDeploymentName}lbdb'
var publicIpNameASCS = '${sidlower}-pip-ascs'
var avSetNameASCS_var = '${sidlower}-avset-ascs'
var nestedDeploymentNameNSG_var = '${nestedDeploymentNameASCS_var}nsg'
var nsgName = '${sidlower}-nsg'
var loadBalancerNameASCS = '${sidlower}-lb-ascs'
var vmNameASCS = '${vmName}-ascs'
var nicNameASCS_var = '${sidlower}-nic-ascs'
var avSetNameDB_var = '${sidlower}-avset-db'
var loadBalancerNameDB = '${sidlower}-lb-db'
var nicNameDB_var = '${sidlower}-nic-db'
var vmNameDB = '${vmName}-db'
var avSetNameDI_var = '${sidlower}-avset-di'
var nicNameDI_var = '${sidlower}-nic-di'
var vmNameDI = '${vmName}-di'
var osDiskType = 'userImage'

module nestedDeploymentNameNSG '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/newnsg.json', parameters('_artifactsLocationSasToken'))]*/ = if (length(subnetId) == 0) {
  name: nestedDeploymentNameNSG_var
  params: {
    nsgName: nsgName
    osType: internalOSType
  }
}

module nestedDeploymentNameVnet '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/newvnetnsg.json', parameters('_artifactsLocationSasToken'))]*/ = if (length(subnetId) == 0) {
  name: nestedDeploymentNameVNet_var
  params: {
    vnetName: vnetName
    addressPrefix: '10.0.0.0/16'
    subnetName: subnetName
    subnetPrefix: '10.0.0.0/24'
    nsgName: nsgName
  }
  dependsOn: [
    nestedDeploymentNameNSG
  ]
}

resource avSetNameASCS 'Microsoft.Compute/availabilitySets@2016-04-30-preview' = {
  name: avSetNameASCS_var
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 3
    platformUpdateDomainCount: 20
  }
}

module nestedDeploymentNamePIP '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/newpip.json', parameters('_artifactsLocationSasToken'))]*/ = [for i in range(0, ascsvmCount): {
  name: '${nestedDeploymentNamePIP_var}-${i}'
  params: {
    publicIpName: '${publicIpNameASCS}-${i}'
    publicIPAddressType: 'Dynamic'
  }
}]

module nestedDeploymentNameLBASCS '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/loadbalancer.json', parameters('_artifactsLocationSasToken'))]*/ = {
  name: nestedDeploymentNameLBASCS_var
  params: {
    loadBalancerName: loadBalancerNameASCS
    sapSystemCount: 1
    stackType: stackType
    osType: internalOSType
    createXSCS: true
    createDB: false
    subnetId: selectedSubnetId
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    nestedDeploymentNameVnet
  ]
}

module nestedDeploymentNameNICASCS '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/nic-config.json', parameters('_artifactsLocationSasToken'))]*/ = [for i in range(0, ascsvmCount): {
  name: '${nestedDeploymentNameNICASCS_var}-${i}'
  params: {
    vnetName: vnetName
    subnetName: subnetName
    publicIpName: '${publicIpNameASCS}-${i}'
    subnetId: subnetId
  }
}]

resource nicNameASCS 'Microsoft.Network/networkInterfaces@2017-06-01' = [for i in range(0, ascsvmCount): {
  name: '${nicNameASCS_var}-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: reference('${nestedDeploymentNameNICASCS_var}-${i}').outputs.selectedConfiguration.value.publicIPAddress
          subnet: reference('${nestedDeploymentNameNICASCS_var}-${i}').outputs.selectedConfiguration.value.subnet
          loadBalancerBackendAddressPools: reference(nestedDeploymentNameLBASCS_var).outputs.nicBackAddressPools.value
        }
      }
    ]
  }
  dependsOn: [
    nestedDeploymentNamePIP
    nestedDeploymentNameNICASCS
    nestedDeploymentNameVnet
    nestedDeploymentNameLBASCS
  ]
}]

module nestedDeploymentNameProf_ascs '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/os-disk-parts-md.json', parameters('_artifactsLocationSasToken'))]*/ = [for i in range(0, ascsvmCount): {
  name: '${nestedDeploymentNameProf}-ascs-${i}'
  params: {
    imageSku: ''
    imagePublisher: ''
    imageOffer: ''
    imageVersion: ''
    osDiskType: osDiskType
    osType: internalOSType
    vmName: '${vmNameASCS}-${i}'
    storageType: 'Premium_LRS'
    managedDiskId: userImageId
  }
}]

module nestedDeploymentNameASCS '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/server-md.json', parameters('_artifactsLocationSasToken'))]*/ = [for i in range(0, ascsvmCount): {
  name: '${nestedDeploymentNameASCS_var}-${i}'
  params: {
    imageReference: reference('${nestedDeploymentNameProf}-ascs-${i}').outputs.imageReference.value
    osDisk: reference('${nestedDeploymentNameProf}-ascs-${i}').outputs.osDisk.value
    osDiskType: osDiskType
    vmName: '${vmNameASCS}-${i}'
    vmSize: vmSizes[sapSystemSize][systemAvailability].ascsserversize
    adminUsername: adminUsername
    adminPassword: adminPassword
    csExtensionScript: csExtension[internalOSType].script
    csExtensionscriptCall: csExtension[internalOSType].scriptCall
    csExtensionscriptArgs: ''
    avSetObj: {
      id: avSetNameASCS.id
    }
    useAVSet: true
    nicName: '${nicNameASCS_var}-${i}'
    dataDisksObj: {
      dataDisks: [
        {
          lun: 0
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
    }
    osType: internalOSType
  }
  dependsOn: [
    nicNameASCS
    avSetNameASCS
    nestedDeploymentNameProf_ascs
  ]
}]

resource avSetNameDB 'Microsoft.Compute/availabilitySets@2016-04-30-preview' = {
  name: avSetNameDB_var
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 3
    platformUpdateDomainCount: 20
  }
}

module nestedDeploymentNameLBDB '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/loadbalancer.json', parameters('_artifactsLocationSasToken'))]*/ = {
  name: nestedDeploymentNameLBDB_var
  params: {
    loadBalancerName: loadBalancerNameDB
    sapSystemCount: 1
    stackType: stackType
    osType: internalOSType
    createXSCS: false
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

module nestedDeploymentNameNICDB '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/nic-config.json', parameters('_artifactsLocationSasToken'))]*/ = [for i in range(0, dbvmCount): {
  name: '${nestedDeploymentNameNICDB_var}-${i}'
  params: {
    vnetName: vnetName
    subnetName: subnetName
    publicIpName: ''
    subnetId: subnetId
  }
}]

resource nicNameDB 'Microsoft.Network/networkInterfaces@2017-06-01' = [for i in range(0, dbvmCount): {
  name: '${nicNameDB_var}-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: reference('${nestedDeploymentNameNICDB_var}-${i}').outputs.selectedConfiguration.value.subnet
          loadBalancerBackendAddressPools: reference(nestedDeploymentNameLBDB_var).outputs.nicBackAddressPools.value
        }
      }
    ]
  }
  dependsOn: [
    nestedDeploymentNameVnet
    nestedDeploymentNameLBDB
    nestedDeploymentNameNICDB
  ]
}]

module nestedDeploymentNameProf_db '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/os-disk-parts-md.json', parameters('_artifactsLocationSasToken'))]*/ = [for i in range(0, dbvmCount): {
  name: '${nestedDeploymentNameProf}-db-${i}'
  params: {
    imageSku: ''
    imagePublisher: ''
    imageOffer: ''
    imageVersion: ''
    osDiskType: osDiskType
    osType: internalOSType
    sidlower: sidlower
    vmName: '${vmNameDB}-${i}'
    storageType: 'Premium_LRS'
    managedDiskId: userImageId
  }
}]

module nestedDeploymentNameDB '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/server-md.json', parameters('_artifactsLocationSasToken'))]*/ = [for i in range(0, dbvmCount): {
  name: '${nestedDeploymentNameDB_var}-${i}'
  params: {
    imageReference: reference('${nestedDeploymentNameProf}-db-${i}').outputs.imageReference.value
    osDisk: reference('${nestedDeploymentNameProf}-db-${i}').outputs.osDisk.value
    osDiskType: osDiskType
    vmName: '${vmNameDB}-${i}'
    vmSize: vmSizes[sapSystemSize][systemAvailability].dbserversize
    adminUsername: adminUsername
    adminPassword: adminPassword
    csExtensionScript: csExtension[internalOSType].script
    csExtensionscriptCall: csExtension[internalOSType].scriptCall
    csExtensionscriptArgs: ''
    avSetObj: {
      id: avSetNameDB.id
    }
    useAVSet: true
    nicName: '${nicNameDB_var}-${i}'
    dataDisksObj: {
      dataDisks: [for (item, j) in dbvmDataDisks: {
        lun: j
        createOption: 'Empty'
        diskSizeGB: item.size
      }]
    }
    osType: internalOSType
  }
  dependsOn: [
    nicNameDB
    avSetNameDB
    nestedDeploymentNameProf_db
  ]
}]

resource avSetNameDI 'Microsoft.Compute/availabilitySets@2016-04-30-preview' = {
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
    subnetId: subnetId
  }
}]

resource nicNameDI 'Microsoft.Network/networkInterfaces@2017-06-01' = [for i in range(0, divmCount): {
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
    imageSku: ''
    imagePublisher: ''
    imageOffer: ''
    imageVersion: ''
    osDiskType: osDiskType
    osType: internalOSType
    sidlower: sidlower
    vmName: '${vmNameDI}-${i}'
    storageType: 'Premium_LRS'
    managedDiskId: userImageId
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
      dataDisks: [
        {
          lun: 0
          createOption: 'Empty'
          diskSizeGB: 128
        }
      ]
    }
    osType: internalOSType
  }
  dependsOn: [
    nicNameDI
    avSetNameDI
    nestedDeploymentNameProf_di
  ]
}]