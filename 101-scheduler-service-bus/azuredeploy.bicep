param serviceBusNamespaceName string {
  metadata: {
    description: 'The suffix to add to resource names that require global uniqueness.'
  }
}
param location string {
  metadata: {
    description: 'The location in which the Service Bus and Azure Scheduler resources should be deployed.'
  }
  default: resourceGroup().location
}
param queueName string {
  metadata: {
    description: 'The name of the queue that should have the messages automatically posted to it. The queue will be created by the template deployment if it doesn\'t already exist.'
  }
  default: 'autoposted'
}
param messageContents string {
  metadata: {
    description: 'The contents of the message to post to the queue.'
  }
  default: 'mymessage'
}
param postRecurrence object {
  metadata: {
    description: 'The frequency at which the message should be posted to the queue.'
  }
  default: {
    interval: 1
    frequency: 'Minute'
  }
}

var serviceBusNamespaceName_variable = serviceBusNamespaceName
var queueSendOnlyKeyName = 'Scheduler'
var schedulerJobCollectionName = 'QueuePoster'
var schedulerJobName = 'PostMessage'

resource serviceBusNamespaceName_resource 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: serviceBusNamespaceName_variable
  location: location
  properties: {}
}

resource serviceBusNamespaceName_queueName 'Microsoft.ServiceBus/namespaces/queues@2017-04-01' = {
  name: '${serviceBusNamespaceName_variable}/${queueName}'
  dependsOn: [
    serviceBusNamespaceName_resource
  ]
}

resource serviceBusNamespaceName_queueName_queueSendOnlyKeyName 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2017-04-01' = {
  name: '${serviceBusNamespaceName_variable}/${queueName}/${queueSendOnlyKeyName}'
  properties: {
    rights: [
      'Send'
    ]
  }
  dependsOn: [
    serviceBusNamespaceName_queueName
  ]
}

resource schedulerJobCollectionName_resource 'Microsoft.Scheduler/jobCollections@2016-03-01' = {
  name: schedulerJobCollectionName
  location: location
  properties: {
    sku: {
      name: 'Standard'
    }
  }
}

resource schedulerJobCollectionName_schedulerJobName 'Microsoft.Scheduler/jobCollections/jobs@2016-03-01' = {
  name: '${schedulerJobCollectionName}/${schedulerJobName}'
  properties: {
    state: 'Enabled'
    action: {
      type: 'ServiceBusQueue'
      serviceBusQueueMessage: {
        namespace: serviceBusNamespaceName_variable
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
    schedulerJobCollectionName_resource
    serviceBusNamespaceName_queueName_queueSendOnlyKeyName
  ]
}