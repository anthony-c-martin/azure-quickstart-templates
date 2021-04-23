@description('Name of the Event Hubs namespace')
param eventhubNamespaceName string

@description('Name of the Authorization rule')
param ipFilterRuleName string

@allowed([
  'Reject'
  'Accept'
])
@description('IP Filter Action')
param ipFilterAction string = 'Accept'

@description('IP Mask')
param IpMask string = '10.0.1.0/32'

@description('Location for Namespace')
param location string = resourceGroup().location

resource eventhubNamespaceName_resource 'Microsoft.EventHub/namespaces@2018-01-01-preview' = {
  name: eventhubNamespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {}
}

resource eventhubNamespaceName_ipFilterRuleName 'Microsoft.EventHub/namespaces/IPFilterRules@2018-01-01-preview' = {
  parent: eventhubNamespaceName_resource
  name: '${ipFilterRuleName}'
  properties: {
    filterName: ipFilterRuleName
    action: ipFilterAction
    ipMask: IpMask
  }
}