param clusterName string {
  metadata: {
    description: 'Name for the Event Hub cluster.'
  }
}
param namespaceName string {
  metadata: {
    description: 'Name for the Namespace to be created in cluster.'
  }
}
param location string {
  metadata: {
    description: 'Specifies the Azure location for all resources.'
  }
  default: resourceGroup().location
}

resource clusterName_resource 'Microsoft.EventHub/clusters@2018-01-01-preview' = {
  name: clusterName
  location: location
  sku: {
    name: 'Dedicated'
    capacity: 1
  }
}

resource namespaceName_resource 'Microsoft.EventHub/namespaces@2018-01-01-preview' = {
  name: namespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 1
  }
  properties: {
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
    clusterArmId: clusterName_resource.id
  }
  dependsOn: [
    clusterName_resource
  ]
}