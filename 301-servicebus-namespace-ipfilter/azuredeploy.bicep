param serviceBusNamespaceName string {
  metadata: {
    description: 'Name of the Service Bus namespace'
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
  default: 'Reject'
}
param IpMask string {
  metadata: {
    description: 'IP Mask'
  }
  default: '10.0.1.0/32'
}
param Location string {
  allowed: [
    'East US2'
    'South Central US'
  ]
  metadata: {
    description: 'Location for Namespace'
  }
  default: resourceGroup().location
}

resource serviceBusNamespaceName_res 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: serviceBusNamespaceName
  location: Location
  sku: {
    name: 'Premium'
    tier: 'Premium'
  }
  properties: {}
}

resource serviceBusNamespaceName_ipFilterRuleName 'Microsoft.ServiceBus/namespaces/IPFilterRules@2018-01-01-preview' = {
  name: '${serviceBusNamespaceName}/${ipFilterRuleName}'
  properties: {
    filterName: ipFilterRuleName
    action: ipFilterAction
    ipMask: IpMask
  }
}