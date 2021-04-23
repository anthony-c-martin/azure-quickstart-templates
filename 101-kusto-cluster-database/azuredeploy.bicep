@description('Name of the cluster to create')
param clusters_kustocluster_name string = 'kusto${uniqueString(resourceGroup().id)}'

@description('Name of the database to create')
param databases_kustodb_name string = 'kustodb'

@description('Location for all resources.')
param location string = resourceGroup().location

resource clusters_kustocluster_name_databases_kustodb_name 'Microsoft.Kusto/clusters/databases@2020-06-14' = {
  parent: clusters_kustocluster_name_resource
  name: '${databases_kustodb_name}'
  location: location
  properties: {
    softDeletePeriodInDays: 365
    hotCachePeriodInDays: 31
  }
}

resource clusters_kustocluster_name_resource 'Microsoft.Kusto/clusters@2020-06-14' = {
  name: clusters_kustocluster_name
  sku: {
    name: 'Standard_D13_v2'
    tier: 'Standard'
    capacity: 2
  }
  location: location
  tags: {
    'Created By': 'GitHub quickstart template'
  }
}