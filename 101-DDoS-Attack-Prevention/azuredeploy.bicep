@description('this will be the location for artifacts')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-DDoS-Attack-Prevention/'

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
param location string

@allowed([
  'Free'
  'Standalone'
  'PerNode'
])
@description('this will be you SKU for OMS')
param omsSku string = 'PerNode'

@description('this will be name of the VNET')
param vNetName string = 'ddos-attack-vnet'

@description('this will be address space for VNET')
param vNetAddressSpace string = '10.1.0.0/16'

@description('this will be name of the subnet')
param subnetName string = 'subnet-01'

@description('this will be address space for subnet')
param subnetAddressSpace string = '10.1.0.0/24'

@description('this will be prefix used for NSG')
param nsgNamePrefix string = 'ddos-attack'

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

@description('attack email alerts will be sent to this email id')
param emailToSendAlertsTo string = 'dummy@contoso.com'

var omsWorkspaceName = 'DDOS-Attack-${uniqueString(resourceGroup().id)}'
var omsSolutions = [
  'Security'
  'AzureActivity'
  'AntiMalware'
]
var tags = {
  scenario: 'Vm-DDOS-Attack-Prevention'
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
    name: 'allow-inbound-http'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '80'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 1000
      direction: 'Inbound'
    }
  }
  {
    name: 'allow-inbound-rdp'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '3389'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 2000
      direction: 'Inbound'
    }
  }
]
var vmName = '${vmNamePrefix}-with-ddos'
var omsTemplateUri = concat(uri(artifactsLocation, 'nested/microsoft.loganalytics/workspaces.json'), artifactsLocationSasToken)
var vnetTemplateUri = concat(uri(artifactsLocation, 'nested/microsoft.network/virtualnetworks.json'), artifactsLocationSasToken)
var nsgTemplateUri = concat(uri(artifactsLocation, 'nested/microsoft.network/nsg.json'), artifactsLocationSasToken)
var pipTemplateUri = concat(uri(artifactsLocation, 'nested/microsoft.network/publicipaddress.json'), artifactsLocationSasToken)
var nicTemplateUri = concat(uri(artifactsLocation, 'nested/microsoft.network/nic-with-pip.json'), artifactsLocationSasToken)
var vmTemplateUri = concat(uri(artifactsLocation, 'nested/microsoft.compute/vm.windows.json'), artifactsLocationSasToken)
var dscScriptUri = concat(uri(artifactsLocation, 'DSC/DesiredStateConfig.ps1.zip'), artifactsLocationSasToken)

module deploy_ddos_attack_oms_resource 'nested/microsoft.loganalytics/workspaces.bicep' = {
  name: 'deploy-ddos-attack-oms-resource'
  params: {
    omsWorkspaceName: omsWorkspaceName
    omsSolutionsName: omsSolutions
    sku: omsSku
    location: location
    tags: tags
  }
}

module vnetName_resource 'nested/microsoft.network/virtualnetworks.bicep' = {
  name: '${vNetName}--resource'
  params: {
    vnetName: vNetName
    addressPrefix: vNetAddressSpace
    subnets: subnets
    location: location
    tags: tags
  }
}

module nsgName_resource 'nested/microsoft.network/nsg.bicep' = {
  name: '${nsgName}--resource'
  params: {
    nsgName: nsgName
    securityRules: nsgSecurityRules
    location: location
    tags: tags
  }
}

module vmName_pip_resource 'nested/microsoft.network/publicipaddress.bicep' = {
  name: '${vmName}-pip-resource'
  params: {
    publicIPAddressName: '${vmName}-pip'
    publicIPAddressType: pipAddressType
    dnsNameForPublicIP: '${vmName}${uniqueString(resourceGroup().id, 'pip')}-pip'
    location: location
    tags: tags
  }
}

module vmName_nic_resource 'nested/microsoft.network/nic-with-pip.bicep' = {
  name: '${vmName}-nic-resource'
  params: {
    nicName: '${vmName}-nic'
    publicIPAddressId: resourceId('Microsoft.Network/publicIPAddresses', '${vmName}-pip')
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vNetName, subnets[0].name)
    location: location
    nsgId: resourceId('Microsoft.Network/networkSecurityGroups', nsgName)
    tags: tags
  }
  dependsOn: [
    vmName_pip_resource
    nsgName_resource
    vnetName_resource
  ]
}

module deploy_vmName_resource 'nested/microsoft.compute/vm.windows.bicep' = {
  name: 'deploy-${vmName}-resource'
  params: {
    vmName: concat(vmName)
    adminUsername: adminUserName
    adminPassword: adminUserPassword
    nicId: resourceId('Microsoft.Network/networkInterfaces', '${vmName}-nic')
    location: location
    tags: tags
  }
  dependsOn: [
    vmName_nic_resource
  ]
}

resource vmName_OMSExtension 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = {
  name: '${vmName}/OMSExtension'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference('deploy-ddos-attack-oms-resource').outputs.workspaceId.value
    }
    protectedSettings: {
      workspaceKey: reference('deploy-ddos-attack-oms-resource').outputs.workspaceKey.value
    }
  }
  dependsOn: [
    deploy_vmName_resource
    deploy_ddos_attack_oms_resource
  ]
}

resource vmName_DSCExtension 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = {
  name: '${vmName}/DSCExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      configuration: {
        url: dscScriptUri
        script: 'DesiredStateConfig.ps1'
        function: 'Main'
      }
      configurationArguments: {
        MachineName: vmName
      }
    }
    protectedSettings: {}
  }
  dependsOn: [
    deploy_vmName_resource
    deploy_ddos_attack_oms_resource
  ]
}

resource DDoS_attack_metric_alert_rule 'microsoft.insights/alertrules@2016-03-01' = {
  name: 'DDoS-attack-metric-alert-rule'
  location: location
  properties: {
    name: 'DDoS attack alert'
    description: 'Under DDoS attack alert'
    isEnabled: true
    condition: {
      'odata.type': 'Microsoft.Azure.Management.Insights.Models.ThresholdRuleCondition'
      dataSource: {
        'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleMetricDataSource'
        resourceUri: reference('${vmName}-pip-resource').outputs.publicIPResourceId.value
        metricNamespace: null
        metricName: 'IfUnderDDoSAttack'
      }
      operator: 'GreaterThanOrEqual'
      threshold: 1
      windowSize: 'PT5M'
    }
    actions: [
      {
        'odata.type': 'Microsoft.Azure.Management.Insights.Models.RuleEmailAction'
        sendToServiceOwners: true
        customEmails: [
          emailToSendAlertsTo
        ]
      }
    ]
  }
  dependsOn: [
    vmName_pip_resource
  ]
}