param clusters_kustocluster_name string {
  metadata: {
    description: 'Name of the cluster to create'
  }
  default: 'kusto${uniqueString(resourceGroup().id)}'
}
param databases_kustodb_name string {
  metadata: {
    description: 'Name of the database to create'
  }
  default: 'kustodb'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource clusters_kustocluster_name_databases_kustodb_name 'Microsoft.Kusto/clusters/databases@2020-06-14' = {
  name: '${clusters_kustocluster_name}/${databases_kustodb_name}'
  location: location
  properties: {
    softDeletePeriodInDays: 365
    hotCachePeriodInDays: 31
  }
  dependsOn: [
    clusters_kustocluster_name_resource
  ]
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