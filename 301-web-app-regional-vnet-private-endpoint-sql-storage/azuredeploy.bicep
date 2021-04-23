@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/301-web-app-regional-vnet-private-endpoint-sql-storage/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

@description('deployment location')
param location string = resourceGroup().location

@description('unique web app name')
param webAppName string = 'web-app-${uniqueString(subscription().id, resourceGroup().id)}'

@description('Azure SQL DB administrator login name')
param sqlAdministratorLoginName string

@description('Azure SQL DB administrator password')
@secure()
param sqlAdministratorLoginPassword string

@description('JSON object describing virtual networks & subnets')
param vNets array

var suffix = substring(replace(guid(resourceGroup().id), '-', ''), 0, 6)
var appName = '${webAppName}-${suffix}'
var storagePrivateDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'
var sqlPrivateDnsZoneName = 'privatelink${environment().suffixes.sqlServerHostname}'
var sqlDatabaseName = 'mydb01'
var storageContainerName = 'mycontainer'
var storageGroupType = 'blob'
var sqlGroupType = 'sqlServer'
var vnetNestedTemplateUri = uri(artifactsLocation, 'nestedtemplates/vnets.json${artifactsLocationSasToken}')
var vnetPeeringNestedTemplateUri = uri(artifactsLocation, 'nestedtemplates/vnet_peering.json${artifactsLocationSasToken}')
var appServicePlanNestedTemplateUri = uri(artifactsLocation, 'nestedtemplates/app_svc_plan.json${artifactsLocationSasToken}')
var appNestedTemplateUri = uri(artifactsLocation, 'nestedtemplates/app.json${artifactsLocationSasToken}')
var sqlNestedTemplateUri = uri(artifactsLocation, 'nestedtemplates/sqldb.json${artifactsLocationSasToken}')
var privateLinkNestedTemplateUri = uri(artifactsLocation, 'nestedtemplates/private_link.json${artifactsLocationSasToken}')
var storageNestedTemplateUri = uri(artifactsLocation, 'nestedtemplates/storage.json${artifactsLocationSasToken}')
var privateDnsNestedTemplateUri = uri(artifactsLocation, 'nestedtemplates/private_dns.json${artifactsLocationSasToken}')
var privateDnsRecordNestedTemplateUri = uri(artifactsLocation, 'nestedtemplates/dns_record.json${artifactsLocationSasToken}')
var privateLinkIpConfigsNestedTemplateUri = uri(artifactsLocation, 'nestedtemplates/private_link_ipconfigs.json${artifactsLocationSasToken}')
var privateLinkIpConfigsHelperNestedTemplateUri = uri(artifactsLocation, 'nestedtemplates/private_link_ipconfigs_helper.json${artifactsLocationSasToken}')

module linkedTemplate_vnet '?' /*TODO: replace with correct path to [variables('vnetNestedTemplateUri')]*/ = [for (item, i) in vNets: {
  name: 'linkedTemplate-vnet-${i}'
  params: {
    suffix: suffix
    location: location
    vNets: item
  }
}]

module linkedTemplate_peerings '?' /*TODO: replace with correct path to [variables('vnetPeeringNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-peerings'
  params: {
    suffix: suffix
    location: location
    vNets: vNets
  }
  dependsOn: [
    linkedTemplate_vnet
  ]
}

module linkedTemplate_app_svc_plan '?' /*TODO: replace with correct path to [variables('appServicePlanNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-app-svc-plan'
  params: {
    suffix: suffix
    location: location
    serverFarmSku: {
      Tier: 'Standard'
      Name: 'S1'
    }
  }
  dependsOn: [
    linkedTemplate_vnet
  ]
}

module linkedTemplate_app '?' /*TODO: replace with correct path to [variables('appNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-app'
  params: {
    location: location
    hostingPlanName: linkedTemplate_app_svc_plan.properties.outputs.serverFarmName.value
    subnet: reference(resourceId('Microsoft.Resources/deployments', 'linkedTemplate-vnet-1')).outputs.subnetResourceIds.value[0].id
    appName: appName
    ipAddressRestriction: [
      '0.0.0.0/32'
    ]
  }
}

module linkedTemplate_sqldb '?' /*TODO: replace with correct path to [variables('sqlNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-sqldb'
  params: {
    suffix: suffix
    location: location
    sqlAdministratorLogin: sqlAdministratorLoginName
    sqlAdministratorLoginPassword: sqlAdministratorLoginPassword
    databaseName: sqlDatabaseName
  }
  dependsOn: [
    linkedTemplate_vnet
  ]
}

module linkedTemplate_sqldb_private_link '?' /*TODO: replace with correct path to [variables('privateLinkNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-sqldb-private-link'
  params: {
    suffix: suffix
    location: location
    resourceType: 'Microsoft.Sql/servers'
    resourceName: linkedTemplate_sqldb.properties.outputs.sqlServerName.value
    groupType: sqlGroupType
    subnet: reference(resourceId('Microsoft.Resources/deployments', 'linkedTemplate-vnet-0')).outputs.subnetResourceIds.value[0].id
  }
}

module linkedTemplate_storage '?' /*TODO: replace with correct path to [variables('storageNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-storage'
  params: {
    suffix: suffix
    location: location
    containerName: storageContainerName
    defaultNetworkAccessAction: 'Deny'
  }
  dependsOn: [
    linkedTemplate_vnet
  ]
}

module linkedTemplate_storage_private_link '?' /*TODO: replace with correct path to [variables('privateLinkNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-storage-private-link'
  params: {
    suffix: suffix
    location: location
    resourceType: 'Microsoft.Storage/storageAccounts'
    resourceName: linkedTemplate_storage.properties.outputs.storageAccountName.value
    groupType: storageGroupType
    subnet: reference(resourceId('Microsoft.Resources/deployments', 'linkedTemplate-vnet-0')).outputs.subnetResourceIds.value[0].id
  }
}

module linkedTemplate_storage_private_dns_spoke_link '?' /*TODO: replace with correct path to [variables('privateDnsNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-storage-private-dns-spoke-link'
  params: {
    privateDnsZoneName: storagePrivateDnsZoneName
    virtualNetworkName: reference(resourceId('Microsoft.Resources/deployments', 'linkedTemplate-vnet-1')).outputs.virtualNetworkName.value
  }
  dependsOn: [
    linkedTemplate_storage_private_link
  ]
}

module linkedTemplate_storage_private_dns_hub_link '?' /*TODO: replace with correct path to [variables('privateDnsNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-storage-private-dns-hub-link'
  params: {
    privateDnsZoneName: storagePrivateDnsZoneName
    virtualNetworkName: reference(resourceId('Microsoft.Resources/deployments', 'linkedTemplate-vnet-0')).outputs.virtualNetworkName.value
  }
  dependsOn: [
    linkedTemplate_storage_private_link
    linkedTemplate_storage_private_dns_spoke_link
  ]
}

module linkedTemplate_storage_private_link_ipconfigs '?' /*TODO: replace with correct path to [variables('privateLinkIpConfigsNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-storage-private-link-ipconfigs'
  params: {
    privateDnsZoneName: storagePrivateDnsZoneName
    privateLinkNicResource: linkedTemplate_storage_private_link.properties.outputs.privateLinkNicResource.value
    privateDnsRecordTemplateUri: privateDnsRecordNestedTemplateUri
    privateLinkNicIpConfigTemplateUri: privateLinkIpConfigsHelperNestedTemplateUri
  }
  dependsOn: [
    linkedTemplate_storage_private_dns_hub_link
  ]
}

module linkedTemplate_sqldb_private_dns_spoke_link '?' /*TODO: replace with correct path to [variables('privateDnsNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-sqldb-private-dns-spoke-link'
  params: {
    privateDnsZoneName: sqlPrivateDnsZoneName
    virtualNetworkName: reference(resourceId('Microsoft.Resources/deployments', 'linkedTemplate-vnet-1')).outputs.virtualNetworkName.value
  }
  dependsOn: [
    linkedTemplate_sqldb_private_link
  ]
}

module linkedTemplate_sqldb_private_dns_hub_link '?' /*TODO: replace with correct path to [variables('privateDnsNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-sqldb-private-dns-hub-link'
  params: {
    privateDnsZoneName: sqlPrivateDnsZoneName
    virtualNetworkName: reference(resourceId('Microsoft.Resources/deployments', 'linkedTemplate-vnet-0')).outputs.virtualNetworkName.value
  }
  dependsOn: [
    linkedTemplate_sqldb_private_link
    linkedTemplate_sqldb_private_dns_spoke_link
  ]
}

module linkedTemplate_sqldb_private_link_ipconfigs '?' /*TODO: replace with correct path to [variables('privateLinkIpConfigsNestedTemplateUri')]*/ = {
  name: 'linkedTemplate-sqldb-private-link-ipconfigs'
  params: {
    privateDnsZoneName: sqlPrivateDnsZoneName
    privateLinkNicResource: linkedTemplate_sqldb_private_link.properties.outputs.privateLinkNicResource.value
    privateDnsRecordTemplateUri: privateDnsRecordNestedTemplateUri
    privateLinkNicIpConfigTemplateUri: privateLinkIpConfigsHelperNestedTemplateUri
  }
  dependsOn: [
    linkedTemplate_sqldb_private_dns_hub_link
  ]
}