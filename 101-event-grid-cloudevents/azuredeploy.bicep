@description('The region where resources are deployed')
param location string = resourceGroup().location

@description('Name of Logic App')
param logicAppName string = 'logicapp-${uniqueString(resourceGroup().id)}'

@description('Name of Event Grid Topic')
param eventGridTopicName string = 'eventgridtopic-${uniqueString(resourceGroup().id)}'

@description('Name of Event Grid Subscription')
param eventGridSubscriptionName string = 'eventgridsubscription-${uniqueString(resourceGroup().id)}'

@description('Comma delimited list of filters for Event Grid Subscription. Default value is \'All\' and other event types depend on how Event Grid Topic defines')
param eventGridSubscriptionIncludedEventTypes string = 'All'

var logicApp = {
  name: logicAppName
  resourceId: resourceId('Microsoft.Logic/workflows', logicAppName)
  location: location
  triggerId: resourceId('Microsoft.Logic/workflows/triggers', logicAppName, 'manual')
}
var eventGridTopic = {
  name: eventGridTopicName
  resourceId: resourceId('Microsoft.EventGrid/topics', eventGridTopicName)
  location: location
}
var eventGridSubscription = {
  name: eventGridSubscriptionName
  location: location
  filter: {
    includedEventTypes: split(eventGridSubscriptionIncludedEventTypes, ',')
  }
}
var tags = {
  projectUrl: 'https://github.com/Azure/azure-quickstart-templates'
  repositoryUrl: 'https://github.com/Azure/azure-quickstart-templates'
  license: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/LICENSE'
}

resource logicApp_name 'Microsoft.Logic/workflows@2017-07-01' = {
  name: logicApp.name
  location: logicApp.location
  tags: tags
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {}
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            method: 'POST'
            schema: {}
          }
        }
      }
      actions: {}
      outputs: {}
    }
  }
}

resource eventGridTopic_name 'Microsoft.EventGrid/topics@2018-05-01-preview' = {
  name: eventGridTopic.name
  location: eventGridTopic.location
  tags: tags
  properties: {
    inputSchema: 'CloudEventV01Schema'
  }
}

resource eventGridSubscription_name 'Microsoft.EventGrid/eventSubscriptions@2018-05-01-preview' = {
  name: eventGridSubscription.name
  location: eventGridSubscription.location
  tags: tags
  properties: {
    eventDeliverySchema: 'CloudEventV01Schema'
    destination: {
      endpointType: 'Webhook'
      properties: {
        endpointUrl: listCallbackUrl(logicApp.triggerId, '2017-07-01').value
      }
    }
    filter: {
      includedEventTypes: eventGridSubscription.filter.includedEventTypes
      isSubjectCaseSensitive: false
    }
  }
  scope: eventGridTopic_name
  dependsOn: [
    logicApp_name
    eventGridTopic_name
  ]
}

output eventGridTopicEndpointUrl string = reference(eventGridTopic.name).endpoint
output eventGridTopicSasKey string = listKeys(eventGridTopic.resourceId, '2018-05-01-preview').key1