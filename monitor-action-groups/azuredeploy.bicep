param actionGroupName string {
  metadata: {
    description: 'Unique name (within the Resource Group) for the Action group.'
  }
}
param actionGroupShortName string {
  metadata: {
    description: 'Short name (maximum 12 characters) for the Action group.'
  }
}
param emailReceivers array {
  metadata: {
    description: 'The list of email receivers that are part of this action group.'
  }
  default: []
}
param smsReceivers array {
  metadata: {
    description: 'The list of SMS receivers that are part of this action group.'
  }
  default: []
}
param webhookReceivers array {
  metadata: {
    description: 'The list of webhook receivers that are part of this action group.'
  }
  default: []
}
param itsmReceivers array {
  metadata: {
    description: 'The list of ITSM receivers that are part of this action group'
  }
  default: []
}
param azureAppPushReceivers array {
  metadata: {
    description: 'The list of AzureAppPush receivers that are part of this action group'
  }
  default: []
}
param automationRunbookReceivers array {
  metadata: {
    description: 'The list of AutomationRunbook receivers that are part of this action group.'
  }
  default: []
}
param voiceReceivers array {
  metadata: {
    description: 'The list of voice receivers that are part of this action group.'
  }
  default: []
}
param logicAppReceivers array {
  metadata: {
    description: 'The list of logic app receivers that are part of this action group.'
  }
  default: []
}
param azureFunctionReceivers array {
  metadata: {
    description: 'The list of azure function receivers that are part of this action group.'
  }
  default: []
}
param armRoleReceivers array {
  metadata: {
    description: 'The list of ARM role receivers that are part of this action group. Roles are Azure RBAC roles and only built-in roles are supported.'
  }
  default: []
}

resource actionGroupName_res 'Microsoft.Insights/actionGroups@2019-06-01' = {
  name: actionGroupName
  location: 'Global'
  properties: {
    groupShortName: actionGroupShortName
    enabled: true
    emailReceivers: emailReceivers
    smsReceivers: smsReceivers
    webhookReceivers: webhookReceivers
    itsmReceivers: itsmReceivers
    azureAppPushReceivers: azureAppPushReceivers
    automationRunbookReceivers: automationRunbookReceivers
    voiceReceivers: voiceReceivers
    logicAppReceivers: logicAppReceivers
    azureFunctionReceivers: azureFunctionReceivers
    armRoleReceivers: armRoleReceivers
  }
}

output actionGroupId string = actionGroupName_res.id