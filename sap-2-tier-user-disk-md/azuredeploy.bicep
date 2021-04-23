@minLength(3)
@maxLength(3)
@description('SAP System ID.')
param sapSystemId string

@allowed([
  'Windows'
  'Linux'
])
@description('The type of the operating system you want to deploy.')
param osType string

@allowed([
  'Small < 2.000 SAPS'
  'Medium < 9.000 SAPS'
  'Large < 18.000 SAPS'
  'X-Large < 40.000 SAPS'
])
@description('The size of the SAP System you want to deploy.')
param sapSystemSize string = 'Small < 2.000 SAPS'

@description('Id of the OS managed disk.')
param userDiskId string

@description('The id of the subnet you want to use.')
param subnetId string = ''

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/sap-2-tier-user-disk-md/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

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
  'Small < 2.000 SAPS': {
    size: 'Standard_DS11_v2'
    disks: [
      {
        size: 512
      }
      {
        size: 512
      }
      {
        size: 128
      }
    ]
    scriptArgs: ' -DBDataLUNS \'0,1\' -DBLogLUNS \'2\''
  }
  'Medium < 9.000 SAPS': {
    size: 'Standard_DS13_v2'
    disks: [
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
        size: 128
      }
    ]
    scriptArgs: ' -DBDataLUNS \'0,1,2\' -DBLogLUNS \'3\''
  }
  'Large < 18.000 SAPS': {
    size: 'Standard_DS14_v2'
    disks: [
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
    scriptArgs: ' -DBDataLUNS \'0,1,2\' -DBLogLUNS \'3\''
  }
  'X-Large < 40.000 SAPS': {
    size: 'Standard_GS5'
    disks: [
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
    scriptArgs: ' -DBDataLUNS \'0,1,2,3\' -DBLogLUNS \'4\''
  }
}
var dataDiskSizes = vmSizes[sapSystemSize].disks
var internalOsType = osType
var sidlower = toLower(sapSystemId)
var vmName = '${sidlower}-servercs'
var vnetName = '${sidlower}-vnet'
var publicIpName = '${sidlower}-pip'
var nicName_var = '${sidlower}-nic'
var nsgName = '${sidlower}-nsg-cs'
var subnetName = 'Subnet'
var nestedDeploymentName_var = 'nestedTemplate'
var nestedDeploymentNameProf_var = '${nestedDeploymentName_var}prof'
var nestedDeploymentNameVnet_var = '${nestedDeploymentName_var}vnet'
var nestedDeploymentNameNSG_var = '${nestedDeploymentName_var}nsg'
var nestedDeploymentNameNIC_var = '${nestedDeploymentName_var}nic'
var nestedDeploymentNamePIP_var = '${nestedDeploymentName_var}pip'
var osDiskType = 'osdisk'

module nestedDeploymentNameNSG '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/newnsg.json', parameters('_artifactsLocationSasToken'))]*/ = if (length(subnetId) == 0) {
  name: nestedDeploymentNameNSG_var
  params: {
    nsgName: nsgName
    osType: internalOsType
  }
}

module nestedDeploymentNameVnet '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/newvnetnsg.json', parameters('_artifactsLocationSasToken'))]*/ = if (length(subnetId) == 0) {
  name: nestedDeploymentNameVnet_var
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

module nestedDeploymentNameNIC '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/nic-config.json', parameters('_artifactsLocationSasToken'))]*/ = {
  name: nestedDeploymentNameNIC_var
  params: {
    vnetName: vnetName
    subnetName: subnetName
    publicIpName: publicIpName
    subnetId: subnetId
  }
}

module nestedDeploymentNameProf '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/os-disk-parts-md.json', parameters('_artifactsLocationSasToken'))]*/ = {
  name: nestedDeploymentNameProf_var
  params: {
    imageSku: ''
    imagePublisher: ''
    imageOffer: ''
    imageVersion: ''
    osDiskType: osDiskType
    osType: internalOsType
    vmName: vmName
    storageType: 'Premium_LRS'
    managedDiskId: userDiskId
  }
}

module nestedDeploymentNamePIP '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/newpip.json', parameters('_artifactsLocationSasToken'))]*/ = if (length(subnetId) == 0) {
  name: nestedDeploymentNamePIP_var
  params: {
    publicIpName: publicIpName
    publicIPAddressType: 'Dynamic'
  }
}

resource nicName 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: reference(nestedDeploymentNameNIC_var).outputs.selectedConfiguration.value.publicIPAddress
          subnet: reference(nestedDeploymentNameNIC_var).outputs.selectedConfiguration.value.subnet
        }
      }
    ]
  }
  dependsOn: [
    nestedDeploymentNameVnet
    nestedDeploymentNameNIC
    nestedDeploymentNamePIP
  ]
}

module nestedDeploymentName '?' /*TODO: replace with correct path to [concat(parameters('_artifactsLocation'), '/shared/server-md.json', parameters('_artifactsLocationSasToken'))]*/ = {
  name: nestedDeploymentName_var
  params: {
    imageReference: reference(nestedDeploymentNameProf_var).outputs.osDisk.value
    osDisk: reference(nestedDeploymentNameProf_var).outputs.osDisk.value
    osDiskType: osDiskType
    vmName: vmName
    vmSize: vmSizes[sapSystemSize].size
    adminUsername: ''
    adminPassword: ''
    csExtensionScript: csExtension[internalOsType].script
    csExtensionscriptCall: csExtension[internalOsType].scriptCall
    csExtensionscriptArgs: ''
    avSetObj: {
      id: ''
    }
    useAVSet: false
    nicName: nicName_var
    dataDisksObj: {
      dataDisks: [for (item, j) in dataDiskSizes: {
        lun: j
        createOption: 'Empty'
        diskSizeGB: item.size
      }]
    }
    osType: internalOsType
  }
  dependsOn: [
    nestedDeploymentNameProf
    nicName
  ]
}