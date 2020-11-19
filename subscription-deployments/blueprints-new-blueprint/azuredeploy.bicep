targetScope = 'subscription'
param blueprintName string {
  metadata: {
    description: 'The name of the blueprint definition.'
  }
  default: 'sample-blueprint'
}

resource blueprintName_resource 'Microsoft.Blueprint/blueprints@2018-11-01-preview' = {
  name: blueprintName
  properties: {
    targetScope: 'subscription'
    description: 'Blueprint with a policy assignment artifact.'
    resourceGroups: {
      sampleRg: {
        description: 'Resource group to add the assignment to.'
      }
    }
    parameters: {
      listOfResourceTypesNotAllowed: {
        type: 'array'
        metadata: {
          displayName: 'Resource types to pass to the policy assignment artifact.'
        }
        defaultValue: [
          'Citrix.Cloud/accounts'
        ]
      }
    }
  }
}

resource blueprintName_policyArtifact 'Microsoft.Blueprint/blueprints/artifacts@2018-11-01-preview' = {
  name: '${blueprintName}/policyArtifact'
  kind: 'policyAssignment'
  properties: {
    displayName: 'Blocked Resource Types policy definition'
    description: 'Block certain resource types'
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', '6c112d4e-5bc7-47ae-a041-ea2d9dccd749')
    resourceGroup: 'sampleRg'
    parameters: {
      listOfResourceTypesNotAllowed: {
        value: '[parameters(\'listOfResourceTypesNotAllowed\')]'
      }
    }
  }
  dependsOn: [
    blueprintName_resource
  ]
}