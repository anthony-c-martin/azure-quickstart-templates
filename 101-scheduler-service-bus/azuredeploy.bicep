@description('The suffix to add to resource names that require global uniqueness.')
param serviceBusNamespaceName string

@description('The location in which the Service Bus and Azure Scheduler resources should be deployed.')
param location string = resourceGroup().location

@description('The name of the queue that should have the messages automatically posted to it. The queue will be created by the template deployment if it doesn\'t already exist.')
param queueName string = 'autoposted'

@description('The contents of the message to post to the queue.')
param messageContents string = 'mymessage'

@description('The frequency at which the message should be posted to the queue.')
param postRecurrence object = {
  interval: 1
  frequency: 'Minute'
}

var serviceBusNamespaceName_var = serviceBusNamespaceName
var queueSendOnlyKeyName = 'Scheduler'
var schedulerJobCollectionName_var = 'QueuePoster'
var schedulerJobName = 'PostMessage'

resource serviceBusNamespaceName_resource 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: serviceBusNamespaceName_var
  location: location
  properties: {}
}

resource serviceBusNamespaceName_queueName 'Microsoft.ServiceBus/namespaces/queues@2017-04-01' = {
  parent: serviceBusNamespaceName_resource
  name: '${queueName}'
}

resource serviceBusNamespaceName_queueName_queueSendOnlyKeyName 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2017-04-01' = {
  parent: serviceBusNamespaceName_queueName
  name: queueSendOnlyKeyName
  properties: {
    rights: [
      'Send'
    ]
  }
}

resource schedulerJobCollectionName 'Microsoft.Scheduler/jobCollections@2016-03-01' = {
  name: schedulerJobCollectionName_var
  location: location
  properties: {
    sku: {
      name: 'Standard'
    }
  }
}

resource schedulerJobCollectionName_schedulerJobName 'Microsoft.Scheduler/jobCollections/jobs@2016-03-01' = {
  parent: schedulerJobCollectionName
  name: '${schedulerJobName}'
  properties: {
    state: 'Enabled'
    action: {
      type: 'ServiceBusQueue'
      serviceBusQueueMessage: {
        namespace: serviceBusNamespaceName_var
        queueName: queueName
        transportType: 'AMQP'
        authentication: {
          sasKey: listKeys(queueSendOnlyKeyName, '2017-04-01').primaryKey
          sasKeyName: listKeys(queueSendOnlyKeyName, '2017-04-01').keyName
          type: 'SharedAccessKey'
        }
        message: messageContents
      }
    }
    recurrence: postRecurrence
  }
  dependsOn: [
    serviceBusNamespaceName_queueName_queueSendOnlyKeyName
  ]
}