param name string {
  minLength: 2
  maxLength: 60
  metadata: {
    description: 'Service name must only contain lowercase letters, digits or dashes, cannot use dash as the first two or last one characters, cannot contain consecutive dashes, and is limited between 2 and 60 characters in length.'
  }
}
param sku string {
  allowed: [
    'free'
    'basic'
    'standard'
    'standard2'
    'standard3'
    'storage_optimized_l1'
    'storage_optimized_l2'
  ]
  metadata: {
    description: 'The pricing tier of the search service you want to create (for example, basic or standard).'
  }
  default: 'standard'
}
param replicaCount int {
  minValue: 1
  maxValue: 12
  metadata: {
    description: 'Replicas distribute search workloads across the service. You need at least two replicas to support high availability of query workloads (not applicable to the free tier).'
  }
  default: 1
}
param partitionCount int {
  allowed: [
    1
    2
    3
    4
    6
    12
  ]
  metadata: {
    description: 'Partitions allow for scaling of document count as well as faster indexing by sharding your index over multiple search units.'
  }
  default: 1
}
param hostingMode string {
  allowed: [
    'default'
    'highDensity'
  ]
  metadata: {
    description: 'Applicable only for SKUs set to standard3. You can set this property to enable a single, high density partition that allows up to 1000 indexes, which is much higher than the maximum indexes allowed for any other SKU.'
  }
  default: 'default'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource name_resource 'Microsoft.Search/searchServices@2020-03-13' = {
  name: name
  location: location
  sku: {
    name: toLower(sku)
  }
  properties: {
    replicaCount: replicaCount
    partitionCount: partitionCount
    hostingMode: hostingMode
  }
}