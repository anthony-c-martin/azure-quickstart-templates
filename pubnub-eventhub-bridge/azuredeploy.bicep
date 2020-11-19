param Event_Hub_Namespace string {
  metadata: {
    description: 'A unique Namespace. It\'s suggested to replace the \'pn-\' prefix with your own unique prefix, such as your company name, and add a \'-suffix\' at the end, where the suffix is also unique.'
  }
}
param Azure_Webjob_Name string {
  metadata: {
    description: 'A unique Web Job Name. Follow the same naming conventions as for Event Hub Namespaces to ensure you have a unique, legal string.'
  }
}
param Azure_Datacenter_Location string {
  metadata: {
    description: 'Must be westus unless you ensure all components are in the same region.  See README for more information.'
  }
  default: 'westus'
}
param PubNub_Ingress_Channel string {
  metadata: {
    description: 'A channel name that the PubNub Subscriber should listen on. If you wish for the subscriber to listen on multiple channels, enter a CSV list of channels, with no spaces.'
  }
  default: 'pnInput'
}
param PubNub_Egress_Channel string {
  metadata: {
    description: 'A channel name that the PubNub Publisher should publish back out on.'
  }
  default: 'pnOutput'
}
param PubNub_Announce_Channel string {
  metadata: {
    description: 'A channel name that the PubNub Deployment script will alert on when the deployment has completed. If you don\'t intend on using this, just set this value to all caps, case-sensitive DISABLED. See below for more information on using the Provisioning Listener and the Announce channel.'
  }
  default: 'pnAnnounce'
}
param PubNub_Publish_Key string {
  metadata: {
    description: 'The PubNub Publish API Key that the PubNub component should publish against.'
  }
  default: 'demo-36'
}
param PubNub_Subscribe_Key string {
  metadata: {
    description: 'The PubNub Subscribe API Key that the PubNub component should subscribe against.'
  }
  default: 'demo-36'
}
param Azure_Service_Plan string {
  metadata: {
    description: 'Must be USWestBasic unless you ensure all components are in the same region.  See README for more information.'
  }
  default: 'USWestBasic'
}
param Azure_Ingress_Event_Hub_Name string {
  metadata: {
    description: 'The name you wish to give the Ingress (Input) Event Hub. You can accept the default, as the Event Hub name needs only to be unique within a unique Event Hub Namespace.'
  }
  default: 'infromsubscriberhub'
}
param Azure_Egress_Event_Hub_Name string {
  metadata: {
    description: 'The name you wish to give the Egress (Output) Event Hub. You can accept the default, as the Event Hub name needs only to be unique within a unique Event Hub Namespace.'
  }
  default: 'outtopnpublisher'
}
param Azure_Ingress_SAS_Policy_Name string {
  metadata: {
    description: 'The name you wish to give the Ingress (Input) Event Hub SAS Policy. You can accept the default, as the Event Hub SAS Policy name needs only to be unique within a unique Event Hub Namespace.'
  }
  default: 'infromsubscriberhub'
}
param Azure_Egress_SAS_Policy_Name string {
  metadata: {
    description: 'The name you wish to give the Egress (Output) Event Hub SAS Policy. You can accept the default, as the Event Hub SAS Policy name needs only to be unique within a unique Event Hub Namespace.'
  }
  default: 'outtopublisherhub'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var location_var = location
var sbVersion = '2015-08-01'
var ehInAuthorizationRuleResourceId = resourceId('Microsoft.EventHub/namespaces/eventhubs/authorizationRules', Event_Hub_Namespace, Azure_Ingress_Event_Hub_Name, Azure_Ingress_SAS_Policy_Name)
var ehOutAuthorizationRuleResourceId = resourceId('Microsoft.EventHub/namespaces/eventhubs/authorizationRules', Event_Hub_Namespace, Azure_Egress_Event_Hub_Name, Azure_Egress_SAS_Policy_Name)

resource Event_Hub_Namespace_res 'Microsoft.EventHub/namespaces@2015-08-01' = {
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  name: Event_Hub_Namespace
  location: Azure_Datacenter_Location
  tags: {}
  properties: {}
}

resource Event_Hub_Namespace_Azure_Ingress_Event_Hub_Name 'Microsoft.EventHub/namespaces/eventhubs@2015-08-01' = {
  name: '${Event_Hub_Namespace}/${Azure_Ingress_Event_Hub_Name}'
  location: Azure_Datacenter_Location
  properties: {
    messageRetentionInDays: 1
    partitionCount: 2
  }
}

resource Event_Hub_Namespace_Azure_Ingress_Event_Hub_Name_Azure_Ingress_SAS_Policy_Name 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2015-08-01' = {
  name: '${Event_Hub_Namespace}/${Azure_Ingress_Event_Hub_Name}/${Azure_Ingress_SAS_Policy_Name}'
  location: location_var
  properties: {
    rights: [
      'Send'
      'Listen'
    ]
  }
}

resource Event_Hub_Namespace_Azure_Egress_Event_Hub_Name 'Microsoft.EventHub/namespaces/eventhubs@2015-08-01' = {
  name: '${Event_Hub_Namespace}/${Azure_Egress_Event_Hub_Name}'
  location: location_var
  properties: {
    messageRetentionInDays: 1
    partitionCount: 2
  }
}

resource Event_Hub_Namespace_Azure_Egress_Event_Hub_Name_Azure_Egress_SAS_Policy_Name 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2015-08-01' = {
  name: '${Event_Hub_Namespace}/${Azure_Egress_Event_Hub_Name}/${Azure_Egress_SAS_Policy_Name}'
  location: location_var
  properties: {
    rights: [
      'Send'
      'Listen'
    ]
  }
}

resource Azure_Service_Plan_res 'Microsoft.Web/serverfarms@2015-08-01' = {
  sku: {
    name: 'B1'
    tier: 'Basic'
    size: 'B1'
    family: 'B'
    capacity: 1
  }
  name: Azure_Service_Plan
  location: location_var
  properties: {
    name: Azure_Service_Plan
    numberOfWorkers: 1
  }
  dependsOn: []
}

resource Azure_Webjob_Name_res 'Microsoft.Web/sites@2015-08-01' = {
  name: Azure_Webjob_Name
  location: location_var
  properties: {
    name: Azure_Webjob_Name
    hostNames: [
      '${Azure_Webjob_Name}.azurewebsites.net'
    ]
    enabledHostNames: [
      '${Azure_Webjob_Name}.azurewebsites.net'
      '${Azure_Webjob_Name}.scm.azurewebsites.net'
    ]
    hostNameSslStates: [
      {
        name: '${Azure_Webjob_Name}.azurewebsites.net'
        sslState: 0
        thumbprint: null
        ipBasedSslState: 0
      }
      {
        name: '${Azure_Webjob_Name}.scm.azurewebsites.net'
        sslState: 0
        thumbprint: null
        ipBasedSslState: 0
      }
    ]
    serverFarmId: Azure_Service_Plan_res.id
  }
}

resource Azure_Webjob_Name_web 'Microsoft.Web/sites/config@2015-08-01' = {
  name: '${Azure_Webjob_Name}/web'
  properties: {
    alwaysOn: true
  }
}

resource Microsoft_Web_sites_sourcecontrols_Azure_Webjob_Name_web 'Microsoft.Web/sites/sourcecontrols@2015-04-01' = {
  name: '${Azure_Webjob_Name}/web'
  properties: {
    RepoUrl: 'https://github.com/pubnub/azureEventHubBridge.git'
    branch: 'master'
    IsManualIntegration: true
  }
}

resource Azure_Webjob_Name_connectionstrings 'Microsoft.Web/sites/config@2015-08-01' = {
  name: '${Azure_Webjob_Name}/connectionstrings'
  properties: {
    PNSubChannel: {
      value: PubNub_Ingress_Channel
      type: 'custom'
    }
    PNPubChannel: {
      value: PubNub_Egress_Channel
      type: 'custom'
    }
    PNAnnounceChannel: {
      value: PubNub_Announce_Channel
      type: 'custom'
    }
    PNPublishKey: {
      value: PubNub_Publish_Key
      type: 'custom'
    }
    PNSubscribeKey: {
      value: PubNub_Subscribe_Key
      type: 'custom'
    }
    EHInConnectionString: {
      value: listkeys(ehInAuthorizationRuleResourceId, sbVersion).primaryConnectionString
      type: 'custom'
    }
    EHOutConnectionString: {
      value: listkeys(ehOutAuthorizationRuleResourceId, sbVersion).primaryConnectionString
      type: 'custom'
    }
  }
}