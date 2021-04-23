@description('The location for the script resource.')
param location string = resourceGroup().location

@description('forceUpdateTag property, used to force the execution of the script resource when no other properties have changed.')
param newGuid string = newGuid()

@minLength(6)
@maxLength(64)
@description('Passphrase used when generating the key pair.')
param passPhrase string

@description('The name of the keyVault to store the keys in.')
param vaultName string

@description('The name of the secret in keyVault to store the keys in.')
param secretName string = 'privateKey'

@description('The resourceGroup for the keyVault.')
param vaultResourceGroup string = resourceGroup().name

@description('The subscriptionId for the keyVault.')
param vaultSubscriptionId string = subscription().subscriptionId

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var scriptName_var = 'createKeys'
var identityName_var = 'scratch'
var roleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
var roleDefinitionName_var = guid(identityName.id, roleDefinitionId, resourceGroup().id)

resource identityName 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName_var
  location: location
}

resource roleDefinitionName 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: roleDefinitionName_var
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: reference(identityName_var).principalId
    scope: resourceGroup().id
    principalType: 'ServicePrincipal'
  }
}

resource scriptName 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: scriptName_var
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityName.id}': {}
    }
  }
  kind: 'AzureCLI'
  properties: {
    forceUpdateTag: newGuid
    azCliVersion: '2.0.80'
    timeout: 'PT30M'
    retentionInterval: 'P1D'
    cleanupPreference: 'OnSuccess'
    arguments: passPhrase
    primaryScriptUri: uri(artifactsLocation, 'new-key.sh${artifactsLocationSasToken}')
  }
  dependsOn: [
    roleDefinitionName
  ]
}

module storeSshKeys './nested_storeSshKeys.bicep' = {
  name: 'storeSshKeys'
  scope: resourceGroup(vaultSubscriptionId, vaultResourceGroup)
  params: {
    keys: reference(scriptName_var).outputs.keyinfo
    vaultName: vaultName
    secretName: secretName
  }
}

output outputs string = reference(scriptName_var).outputs.keyinfo.publicKey
output status object = reference(scriptName_var).status