targetScope = 'subscription'

@description('Array of actions for the roleDefinition')
param actions array = [
  'Microsoft.Resources/subscriptions/resourceGroups/read'
]

@description('Array of notActions for the roleDefinition')
param notActions array = []

@description('Friendly name of the role definition')
param roleName string = 'Custom Role - RG Reader'

@description('Detailed description of the role definition')
param roleDescription string = 'Subscription Level Deployment of a Role Definition'

var roleDefName_var = guid(subscription().id, string(actions), string(notActions))

resource roleDefName 'Microsoft.Authorization/roleDefinitions@2018-07-01' = {
  name: roleDefName_var
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