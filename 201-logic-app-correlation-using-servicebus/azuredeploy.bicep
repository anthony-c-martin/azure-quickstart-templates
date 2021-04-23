@description('The Service Bus namespace name. This value should be globally unique!')
param serviceBusNamespace string = uniqueString(resourceGroup().id, deployment().name)

@description('Name of the client Logic App')
param clientLogicApp string = 'ClientLogicApp'

@description('Name of the backend Logic App')
param backendLogicApp string = 'BackendLogicApp'

@description('Name of the transformation Logic App')
param transformationLogicApp string = 'TransformationLogicApp'

@description('The name of the topic for routing messages.')
param messageRoutingTopic string = 'messagerouting'

@description('The name of the topic subscription towards the client Logic App.')
param clientLogicAppSubscription string = 'ToClientLogicApp'

@description('The name of the topic subscription towards the backend Logic App.')
param backendLogicAppSubscription string = 'ToBackendLogicApp'

@description('The name of the topic subscription towards the transformation Logic App.')
param transformationLogicAppSubscription string = 'ToTransformationLogicApp'

@description('The name of the connection to Service Bus created for Logic Apps.')
param serviceBusConnection string = 'servicebus'

@description('Location for all resources.')
param location string = resourceGroup().location

resource backendLogicApp_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: backendLogicApp
  location: location
  tags: {}
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        'When_a_message_is_received_in_a_topic_subscription_(peek-lock)': {
          recurrence: {
            frequency: 'Second'
            interval: 30
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/@{encodeURIComponent(encodeURIComponent(\'messagerouting\'))}/subscriptions/@{encodeURIComponent(\'To${backendLogicApp}\')}/messages/head/peek'
            queries: {
              sessionId: 'Next Available'
              subscriptionType: 'Main'
            }
          }
        }
      }
      actions: {
        Complete_the_message_in_a_topic_subscription: {
          runAfter: {
            Send_message: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
              }
            }
            method: 'delete'
            path: '/@{encodeURIComponent(encodeURIComponent(\'messagerouting\'))}/subscriptions/@{encodeURIComponent(\'To${backendLogicApp}\')}/messages/complete'
            queries: {
              lockToken: '@triggerBody()?[\'LockToken\']'
              sessionId: '@triggerBody()?[\'SessionId\']'
              subscriptionType: 'Main'
            }
          }
        }
        HTTP: {
          runAfter: {}
          type: 'Http'
          inputs: {
            body: '@base64ToString(triggerBody()?[\'ContentData\'])'
            headers: {
              'Content-Type': 'application/json'
            }
            method: 'POST'
            uri: 'https://demo5633756.mockable.io/order'
          }
        }
        Send_message: {
          runAfter: {
            HTTP: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              ContentData: '@{base64(concat(\'{\',\'\n\',\'    "Content":\',body(\'HTTP\'),\',\',\'\n\',\'    "StatusCode":\',outputs(\'HTTP\')[\'statusCode\'],\'\n\',\'}\'))}'
              ContentType: 'application/json'
              Properties: {
                Source: backendLogicApp
              }
              SessionId: '@triggerBody()?[\'SessionId\']'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/@{encodeURIComponent(encodeURIComponent(\'messagerouting\'))}/messages'
            queries: {
              systemProperties: 'None'
            }
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          servicebus: {
            connectionId: serviceBusConnection_resource.id
            connectionName: 'servicebus'
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/servicebus'
          }
        }
      }
    }
  }
}

resource clientLogicApp_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: clientLogicApp
  location: location
  tags: {}
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              properties: {
                Amount: {
                  type: 'string'
                }
                Customer: {
                  type: 'string'
                }
                Product: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
      }
      actions: {
        For_each: {
          foreach: '@body(\'Get_messages_from_a_topic_subscription_(peek-lock)\')'
          actions: {
            Complete_the_message_in_a_topic_subscription: {
              runAfter: {}
              type: 'ApiConnection'
              inputs: {
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
                  }
                }
                method: 'delete'
                path: '/@{encodeURIComponent(encodeURIComponent(\'messagerouting\'))}/subscriptions/@{encodeURIComponent(\'To${clientLogicApp}\')}/messages/complete'
                queries: {
                  lockToken: '@items(\'For_each\')?[\'LockToken\']'
                  sessionId: '@items(\'For_each\')?[\'SessionId\']'
                  subscriptionType: 'Main'
                }
              }
            }
          }
          runAfter: {
            Response: [
              'Succeeded'
            ]
          }
          type: 'Foreach'
        }
        'Get_messages_from_a_topic_subscription_(peek-lock)': {
          runAfter: {
            Send_message: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/@{encodeURIComponent(encodeURIComponent(\'messagerouting\'))}/subscriptions/@{encodeURIComponent(\'To${clientLogicApp}\')}/messages/batch/peek'
            queries: {
              maxMessageCount: 1
              sessionId: '@variables(\'MyUniqueIdentifier\')'
              subscriptionType: 'Main'
            }
          }
        }
        Initialize_variable: {
          runAfter: {}
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'MyUniqueIdentifier'
                type: 'string'
                value: '@{guid()}'
              }
            ]
          }
        }
        Parse_JSON: {
          runAfter: {
            'Get_messages_from_a_topic_subscription_(peek-lock)': [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@base64ToString(body(\'Get_messages_from_a_topic_subscription_(peek-lock)\')?[0]?[\'ContentData\'])'
            schema: {
              properties: {
                Content: {
                  properties: {
                    MyBackendResponse: {
                      type: 'string'
                    }
                  }
                  type: 'object'
                }
                StatusCode: {
                  type: 'integer'
                }
              }
              type: 'object'
            }
          }
        }
        Response: {
          runAfter: {
            Parse_JSON: [
              'Succeeded'
            ]
          }
          type: 'Response'
          kind: 'Http'
          inputs: {
            body: '@body(\'Parse_JSON\')?[\'Content\']'
            statusCode: '@body(\'Parse_JSON\')?[\'StatusCode\']'
          }
        }
        Send_message: {
          runAfter: {
            Initialize_variable: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              ContentData: '@{base64(triggerBody())}'
              ContentType: 'application/json'
              Properties: {
                Source: clientLogicApp
              }
              SessionId: '@variables(\'MyUniqueIdentifier\')'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/@{encodeURIComponent(encodeURIComponent(\'messagerouting\'))}/messages'
            queries: {
              systemProperties: 'None'
            }
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          servicebus: {
            connectionId: serviceBusConnection_resource.id
            connectionName: 'servicebus'
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/servicebus'
          }
        }
      }
    }
  }
}

resource transformationLogicApp_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: transformationLogicApp
  location: location
  tags: {}
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        'When_a_message_is_received_in_a_topic_subscription_(peek-lock)': {
          recurrence: {
            frequency: 'Second'
            interval: 30
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/@{encodeURIComponent(encodeURIComponent(\'messagerouting\'))}/subscriptions/@{encodeURIComponent(\'To${transformationLogicApp}\')}/messages/head/peek'
            queries: {
              sessionId: 'Next Available'
              subscriptionType: 'Main'
            }
          }
        }
      }
      actions: {
        Complete_the_message_in_a_topic_subscription: {
          runAfter: {
            Send_message: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
              }
            }
            method: 'delete'
            path: '/@{encodeURIComponent(encodeURIComponent(\'messagerouting\'))}/subscriptions/@{encodeURIComponent(\'To${transformationLogicApp}\')}/messages/complete'
            queries: {
              lockToken: '@triggerBody()?[\'LockToken\']'
              sessionId: '@triggerBody()?[\'SessionId\']'
              subscriptionType: 'Main'
            }
          }
        }
        Compose: {
          runAfter: {
            Parse_JSON: [
              'Succeeded'
            ]
          }
          type: 'Compose'
          inputs: {
            AmountOrdered: '@{body(\'Parse_JSON\')?[\'Amount\']}'
            CustomerName: '@{body(\'Parse_JSON\')?[\'Customer\']}'
            OrderedProduct: '@{body(\'Parse_JSON\')?[\'Product\']}'
          }
        }
        Parse_JSON: {
          runAfter: {}
          type: 'ParseJson'
          inputs: {
            content: '@base64ToString(triggerBody()?[\'ContentData\'])'
            schema: {
              properties: {
                Amount: {
                  type: 'string'
                }
                Customer: {
                  type: 'string'
                }
                Product: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
        Send_message: {
          runAfter: {
            Compose: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              ContentData: '@{base64(outputs(\'Compose\'))}'
              ContentType: 'application/json'
              Properties: {
                Source: transformationLogicApp
              }
              SessionId: '@triggerBody()?[\'SessionId\']'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/@{encodeURIComponent(encodeURIComponent(\'messagerouting\'))}/messages'
            queries: {
              systemProperties: 'None'
            }
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          servicebus: {
            connectionId: serviceBusConnection_resource.id
            connectionName: 'servicebus'
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/servicebus'
          }
        }
      }
    }
  }
}

resource serviceBusNamespace_resource 'Microsoft.ServiceBus/namespaces@2017-04-01' = {
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  name: serviceBusNamespace
  location: location
  tags: {}
  properties: {
    metricId: '${subscription().subscriptionId}:router${serviceBusNamespace}'
    createdAt: '4/7/2018 12:06:43 PM'
    updatedAt: '4/7/2018 12:07:09 PM'
    serviceBusEndpoint: 'https://${serviceBusNamespace}.servicebus.windows.net:443/'
    status: 'Active'
  }
}

resource serviceBusConnection_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: serviceBusConnection
  location: location
  properties: {
    displayName: 'Router'
    customParameterValues: {}
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/${serviceBusConnection}'
    }
    parameterValues: {
      connectionString: listKeys(serviceBusNamespace_RootManageSharedAccessKey.id, '2015-08-01').primaryConnectionString
    }
  }
}

resource serviceBusNamespace_RootManageSharedAccessKey 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2017-04-01' = {
  parent: serviceBusNamespace_resource
  name: 'RootManageSharedAccessKey'
  location: location
  properties: {
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
}

resource serviceBusNamespace_messageRoutingTopic 'Microsoft.ServiceBus/namespaces/topics@2017-04-01' = {
  parent: serviceBusNamespace_resource
  name: '${messageRoutingTopic}'
  location: location
  properties: {
    defaultMessageTimeToLive: 'P14D'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    enableBatchedOperations: true
    status: 'Active'
    supportOrdering: false
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: true
    enableExpress: false
  }
}

resource serviceBusNamespace_messageRoutingTopic_backendLogicAppSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2017-04-01' = {
  parent: serviceBusNamespace_messageRoutingTopic
  name: backendLogicAppSubscription
  location: location
  properties: {
    lockDuration: 'PT30S'
    requiresSession: true
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: false
    deadLetteringOnFilterEvaluationExceptions: false
    maxDeliveryCount: 10
    status: 'Active'
    enableBatchedOperations: false
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
  }
  dependsOn: [
    serviceBusNamespace_resource
  ]
}

resource serviceBusNamespace_messageRoutingTopic_clientLogicAppSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2017-04-01' = {
  parent: serviceBusNamespace_messageRoutingTopic
  name: clientLogicAppSubscription
  location: location
  properties: {
    lockDuration: 'PT30S'
    requiresSession: true
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: false
    deadLetteringOnFilterEvaluationExceptions: false
    maxDeliveryCount: 10
    status: 'Active'
    enableBatchedOperations: false
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
  }
  dependsOn: [
    serviceBusNamespace_resource
  ]
}

resource serviceBusNamespace_messageRoutingTopic_transformationLogicAppSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2017-04-01' = {
  parent: serviceBusNamespace_messageRoutingTopic
  name: transformationLogicAppSubscription
  location: location
  properties: {
    lockDuration: 'PT30S'
    requiresSession: true
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: false
    deadLetteringOnFilterEvaluationExceptions: false
    maxDeliveryCount: 10
    status: 'Active'
    enableBatchedOperations: false
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
  }
  dependsOn: [
    serviceBusNamespace_resource
  ]
}

resource serviceBusNamespace_messageRoutingTopic_backendLogicAppSubscription_RouteToBackendLogicApp 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2017-04-01' = {
  parent: serviceBusNamespace_messageRoutingTopic_backendLogicAppSubscription
  name: 'RouteToBackendLogicApp'
  location: location
  properties: {
    action: {}
    filterType: 'SqlFilter'
    sqlFilter: {
      sqlExpression: 'Source=\'TransformationLogicApp\''
    }
  }
  dependsOn: [
    serviceBusNamespace_resource
    serviceBusNamespace_messageRoutingTopic
  ]
}

resource serviceBusNamespace_messageRoutingTopic_clientLogicAppSubscription_RouteToClientLogicApp 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2017-04-01' = {
  parent: serviceBusNamespace_messageRoutingTopic_clientLogicAppSubscription
  name: 'RouteToClientLogicApp'
  location: location
  properties: {
    action: {}
    filterType: 'SqlFilter'
    sqlFilter: {
      sqlExpression: 'Source=\'BackendLogicApp\''
    }
  }
  dependsOn: [
    serviceBusNamespace_resource
    serviceBusNamespace_messageRoutingTopic
  ]
}

resource serviceBusNamespace_messageRoutingTopic_transformationLogicAppSubscription_RouteToTransformationLogicApp 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2017-04-01' = {
  parent: serviceBusNamespace_messageRoutingTopic_transformationLogicAppSubscription
  name: 'RouteToTransformationLogicApp'
  location: location
  properties: {
    action: {}
    filterType: 'SqlFilter'
    sqlFilter: {
      sqlExpression: 'Source=\'ClientLogicApp\''
    }
  }
  dependsOn: [
    serviceBusNamespace_resource
    serviceBusNamespace_messageRoutingTopic
  ]
}