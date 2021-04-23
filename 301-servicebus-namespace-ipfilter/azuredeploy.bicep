@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('Name of the Authorization rule')
param ipFilterRuleName string

@allowed([
  'Reject'
  'Accept'
])
@description('IP Filter Action')
param ipFilterAction string = 'Reject'

@description('IP Mask')
param IpMask string = '10.0.1.0/32'

@allowed([
  'East US2'
  'South Central US'
])
@description('Location for Namespace')
param Location string = resourceGroup().location

resource serviceBusNamespaceName_resource 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: serviceBusNamespaceName
  location: Location
  sku: {
    name: 'Premium'
    tier: 'Premium'
  }
  properties: {}
}

resource serviceBusNamespaceName_ipFilterRuleName 'Microsoft.ServiceBus/namespaces/IPFilterRules@2018-01-01-preview' = {
  parent: serviceBusNamespaceName_resource
  name: '${ipFilterRuleName}'
  properties: {
    filterName: ipFilterRuleName
    action: ipFilterAction
    ipMask: IpMask
  }
}