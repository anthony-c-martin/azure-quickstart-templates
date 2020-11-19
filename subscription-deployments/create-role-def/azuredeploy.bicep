targetScope = 'subscription'
param actions array {
  metadata: {
    description: 'Array of actions for the roleDefinition'
  }
  default: [
    'Microsoft.Resources/subscriptions/resourceGroups/read'
  ]
}
param notActions array {
  metadata: {
    description: 'Array of notActions for the roleDefinition'
  }
  default: []
}
param roleName string {
  metadata: {
    description: 'Friendly name of the role definition'
  }
  default: 'Custom Role - RG Reader'
}
param roleDescription string {
  metadata: {
    description: 'Detailed description of the role definition'
  }
  default: 'Subscription Level Deployment of a Role Definition'
}

var roleDefName = guid(subscription().id, string(actions), string(notActions))

resource roleDefName_resource 'Microsoft.Authorization/roleDefinitions@2018-07-01' = {
  name: roleDefName
  properties: {
    roleName: roleName
    description: roleDescription
    type: 'customRole'
    isCustom: true
    permissions: [
      {
        actions: actions
        notActions: notActions
      }
    ]
    assignableScopes: [
      subscription().id
    ]
  }
}