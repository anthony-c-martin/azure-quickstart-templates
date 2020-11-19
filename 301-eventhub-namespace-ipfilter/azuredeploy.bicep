param eventhubNamespaceName string {
  metadata: {
    description: 'Name of the Event Hubs namespace'
  }
}
param ipFilterRuleName string {
  metadata: {
    description: 'Name of the Authorization rule'
  }
}
param ipFilterAction string {
  allowed: [
    'Reject'
    'Accept'
  ]
  metadata: {
    description: 'IP Filter Action'
  }
  default: 'Accept'
}
param IpMask string {
  metadata: {
    description: 'IP Mask'
  }
  default: '10.0.1.0/32'
}
param location string {
  metadata: {
    description: 'Location for Namespace'
  }
  default: resourceGroup().location
}

resource eventhubNamespaceName_res 'Microsoft.EventHub/namespaces@2018-01-01-preview' = {
  name: eventhubNamespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {}
}

resource eventhubNamespaceName_ipFilterRuleName 'Microsoft.EventHub/namespaces/IPFilterRules@2018-01-01-preview' = {
  name: '${eventhubNamespaceName}/${ipFilterRuleName}'
  properties: {
    FilterName: ipFilterRuleName
    Action: ipFilterAction
    IpMask: IpMask
  }
}