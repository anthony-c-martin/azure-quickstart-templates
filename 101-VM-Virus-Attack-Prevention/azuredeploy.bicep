@description('this will be the location for artifacts')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-VM-Virus-Attack-Prevention'

@description('this will be the sas key to access artifacts')
@secure()
param artifactsLocationSasToken string = ''

@allowed([
  'East US'
  'West Europe'
  'Southeast Asia'
  'Australia Southeast'
])
@description('your resources will be created in this location')
param location string = 'East US'

@allowed([
  'Free'
  'Standalone'
  'PerNode'
])
@description('this will be you SKU for OMS')
param omsSku string = 'PerNode'

@description('this will be name of the VNET')
param vNetName string = 'virus-attack-vnet'

@description('this will be address space for VNET')
param vNetAddressSpace string = '10.1.0.0/16'

@description('this will be name of the subnet')
param subnetName string = 'subnet-01'

@description('this will be address space for subnet')
param subnetAddressSpace string = '10.1.0.0/24'

@description('this will be prefix used for NSG')
param nsgNamePrefix string = 'virus-attack'

@allowed([
  'dynamic'
  'static'
])
@description('this will be the type of public IP address used for the VM name')
param pipAddressType string = 'dynamic'

@description('this will be the prefix used for the VM name')
param vmNamePrefix string = 'vm'

@description('this will be the user name of the VMs deployed')
param adminUserName string

@description('this will be the password of the user created on the user')
@secure()
param adminUserPassword string

var omsWorkspaceName = 'Virus-Attack-${substring(uniqueString(resourceGroup().id), 0, 5)}'
var omsSolutions = [
  'Security'
  'AzureActivity'
  'AntiMalware'
]
var tags = {
  scenario: 'Vm-Virus-Attack-Prevention'
}
var subnets = [
  {
    name: subnetName
    properties: {
      addressPrefix: subnetAddressSpace
    }
  }
]
var nsgName = '${nsgNamePrefix}-nsg'
var nsgSecurityRules = [
  {
    name: 'allow-inbound-rdp'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '3389'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 1000
      direction: 'Inbound'
    }
  }
]
var vmNames_var = [
  '${vmNamePrefix}-without-ep'
  '${vmNamePrefix}-with-ep'
]
var omsTemplateUri = '${artifactsLocation}/nested/microsoft.loganalytics/workspaces.json${artifactsLocationSasToken}'
var vnetTemplateUri = '${artifactsLocation}/nested/microsoft.network/virtualnetworks.json${artifactsLocationSasToken}'
var nsgTemplateUri = '${artifactsLocation}/nested/microsoft.network/nsg.json${artifactsLocationSasToken}'
var pipTemplateUri = '${artifactsLocation}/nested/microsoft.network/publicipaddress.json${artifactsLocationSasToken}'
var nicTemplateUri = '${artifactsLocation}/nested/microsoft.network/nic-with-pip.json${artifactsLocationSasToken}'
var vmTemplateUri = '${artifactsLocation}/nested/microsoft.compute/vm.windows.json${artifactsLocationSasToken}'

module deploy_virus_attack_oms_resource '?' /*TODO: replace with correct path to [variables('omsTemplateUri')]*/ = {
  name: 'deploy-virus-attack-oms-resource'
  params: {
    omsWorkspaceName: omsWorkspaceName
    omsSolutionsName: omsSolutions
    sku: omsSku
    location: location
    tags: tags
  }
}

module vnetName_resource '?' /*TODO: replace with correct path to [variables('vnetTemplateUri')]*/ = {
  name: '${vNetName}--resource'
  params: {
    vnetName: vNetName
    addressPrefix: vNetAddressSpace
    subnets: subnets
    location: location
    tags: tags
  }
}

module nsgName_resource '?' /*TODO: replace with correct path to [variables('nsgTemplateUri')]*/ = {
  name: '${nsgName}--resource'
  params: {
    nsgName: nsgName
    securityRules: nsgSecurityRules
    location: location
    tags: tags
  }
}

module vmNames_pip_resource '?' /*TODO: replace with correct path to [variables('pipTemplateUri')]*/ = [for i in range(0, 2): {
  name: '${vmNames_var[i]}-pip-resource'
  params: {
    publicIPAddressName: '${vmNames_var[i]}-pip'
    publicIPAddressType: pipAddressType
    dnsNameForPublicIP: '${vmNames_var[i]}${uniqueString(resourceGroup().id, 'pip')}-pip'
    location: location
    tags: tags
  }
}]

module vmNames_nic_resource '?' /*TODO: replace with correct path to [variables('nicTemplateUri')]*/ = [for i in range(0, 2): {
  name: '${vmNames_var[i]}-nic-resource'
  params: {
    nicName: '${vmNames_var[i]}-nic'
    publicIPAddressId: resourceId('Microsoft.Network/publicIPAddresses', '${vmNames_var[i]}-pip')
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vNetName, subnets[0].name)
    location: location
    nsgId: resourceId('Microsoft.Network/networkSecurityGroups', nsgName)
    tags: tags
  }
  dependsOn: [
    vmNames_pip_resource
    nsgName_resource
    vnetName_resource
  ]
}]

module vmNames '?' /*TODO: replace with correct path to [variables('vmTemplateUri')]*/ = [for i in range(0, 2): {
  name: concat(vmNames_var[i])
  params: {
    vmName: concat(vmNames_var[i])
    adminUsername: adminUserName
    adminPassword: adminUserPassword
    nicId: resourceId('Microsoft.Network/networkInterfaces', '${vmNames_var[i]}-nic')
    location: location
    tags: tags
  }
  dependsOn: [
    vmNames_nic_resource
  ]
}]

resource vmNames_OMSExtension 'Microsoft.Compute/virtualMachines/extensions@2017-12-01' = [for i in range(0, 2): {
  name: '${vmNames_var[i]}/OMSExtension'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference('deploy-virus-attack-oms-resource').outputs.workspaceId.value
    }
    protectedSettings: {
      workspaceKey: reference('deploy-virus-attack-oms-resource').outputs.workspaceKey.value
    }
  }
  dependsOn: [
    concat(vmNames_var[i])
    deploy_virus_attack_oms_resource
  ]
}]

resource vmNames_1_malware 'Microsoft.Compute/virtualMachines/extensions@2017-12-01' = [for i in range(0, 1): {
  name: '${vmNames_var[(i + 1)]}/malware'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'IaaSAntimalware'
    typeHandlerVersion: '1.1'
    autoUpgradeMinorVersion: true
    settings: {
      AntimalwareEnabled: 'true'
      Exclusions: {
        Paths: ''
        Extensions: ''
        Processes: 'taskmgr.exe'
      }
      RealtimeProtectionEnabled: 'true'
      ScheduledScanSettings: {
        isEnabled: 'true'
        scanType: 'Quick'
        day: '7'
        time: '120'
      }
    }
    protectedSettings: null
  }
  dependsOn: [
    vmNames_OMSExtension
  ]
}]