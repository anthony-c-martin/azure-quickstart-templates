@minLength(1)
@description('The email address of the owner of the service')
param publisherEmail string

@minLength(1)
@description('The name of the owner of the service')
param publisherName string

@allowed([
  'Developer'
  'Standard'
  'Premium'
])
@description('The pricing tier of this API Management service')
param sku string = 'Standard'

@description('The instance size of this API Management service.')
param skuCount int = 1

@description('Base-64 encoded Mutual authentication PFX certificate.')
@secure()
param mutualAuthenticationCertificate string

@description('Mutual authentication certificate password.')
@secure()
param certificatePassword string

@description('EventHub connection string for logger.')
@secure()
param eventHubNamespaceConnectionString string

@description('Google client secret to configure google identity.')
@secure()
param googleClientSecret string

@description('OpenId connect client secret.')
@secure()
param openIdConnectClientSecret string

@description('Tenant policy XML.')
param tenantPolicy string

@description('API policy XML.')
param apiPolicy string

@description('Operation policy XML.')
param operationPolicy string

@description('Product policy XML.')
param productPolicy string

@description('Location for all resources.')
param location string = resourceGroup().location

var apiManagementServiceName_var = 'apiservice${uniqueString(resourceGroup().id)}'

resource apiManagementServiceName 'Microsoft.ApiManagement/service@2017-03-01' = {
  name: apiManagementServiceName_var
  location: location
  tags: {}
  sku: {
    name: sku
    capacity: skuCount
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

resource apiManagementServiceName_policy 'Microsoft.ApiManagement/service/policies@2017-03-01' = {
  parent: apiManagementServiceName
  name: 'policy'
  properties: {
    policyContent: tenantPolicy
  }
}

resource apiManagementServiceName_PetStoreSwaggerImportExample 'Microsoft.ApiManagement/service/apis@2017-03-01' = {
  parent: apiManagementServiceName
  name: 'PetStoreSwaggerImportExample'
  properties: {
    contentFormat: 'SwaggerLinkJson'
    contentValue: 'http://petstore.swagger.io/v2/swagger.json'
    path: 'examplepetstore'
  }
}

resource apiManagementServiceName_exampleApi 'Microsoft.ApiManagement/service/apis@2017-03-01' = {
  parent: apiManagementServiceName
  name: 'exampleApi'
  properties: {
    displayName: 'Example API Name'
    description: 'Description for example API'
    serviceUrl: 'https://example.net'
    path: 'exampleapipath'
    protocols: [
      'https'
    ]
  }
}

resource apiManagementServiceName_exampleApi_exampleOperationsDELETE 'Microsoft.ApiManagement/service/apis/operations@2017-03-01' = {
  parent: apiManagementServiceName_exampleApi
  name: 'exampleOperationsDELETE'
  properties: {
    displayName: 'DELETE resource'
    method: 'DELETE'
    urlTemplate: '/resource'
    description: 'A demonstration of a DELETE call'
  }
}

resource apiManagementServiceName_exampleApi_exampleOperationsGET 'Microsoft.ApiManagement/service/apis/operations@2017-03-01' = {
  parent: apiManagementServiceName_exampleApi
  name: 'exampleOperationsGET'
  properties: {
    displayName: 'GET resource'
    method: 'GET'
    urlTemplate: '/resource'
    description: 'A demonstration of a GET call'
  }
}

resource apiManagementServiceName_exampleApi_exampleOperationsGET_policy 'Microsoft.ApiManagement/service/apis/operations/policies@2017-03-01' = {
  parent: apiManagementServiceName_exampleApi_exampleOperationsGET
  name: 'policy'
  properties: {
    policyContent: operationPolicy
  }
  dependsOn: [
    apiManagementServiceName
    apiManagementServiceName_exampleApi
  ]
}

resource apiManagementServiceName_exampleApiWithPolicy 'Microsoft.ApiManagement/service/apis@2017-03-01' = {
  parent: apiManagementServiceName
  name: 'exampleApiWithPolicy'
  properties: {
    displayName: 'Example API Name with Policy'
    description: 'Description for example API with policy'
    serviceUrl: 'https://exampleapiwithpolicy.net'
    path: 'exampleapiwithpolicypath'
    protocols: [
      'https'
    ]
  }
}

resource apiManagementServiceName_exampleApiWithPolicy_policy 'Microsoft.ApiManagement/service/apis/policies@2017-03-01' = {
  parent: apiManagementServiceName_exampleApiWithPolicy
  name: 'policy'
  properties: {
    policyContent: apiPolicy
  }
  dependsOn: [
    apiManagementServiceName
  ]
}

resource apiManagementServiceName_exampleProduct 'Microsoft.ApiManagement/service/products@2017-03-01' = {
  parent: apiManagementServiceName
  name: 'exampleProduct'
  properties: {
    displayName: 'Example Product Name'
    description: 'Description for example product'
    terms: 'Terms for example product'
    subscriptionRequired: true
    approvalRequired: false
    subscriptionsLimit: 1
    state: 'published'
  }
}

resource apiManagementServiceName_exampleProduct_exampleApi 'Microsoft.ApiManagement/service/products/apis@2017-03-01' = {
  parent: apiManagementServiceName_exampleProduct
  name: 'exampleApi'
  dependsOn: [
    apiManagementServiceName
    apiManagementServiceName_exampleApi
  ]
}

resource apiManagementServiceName_exampleProduct_policy 'Microsoft.ApiManagement/service/products/policies@2017-03-01' = {
  parent: apiManagementServiceName_exampleProduct
  name: 'policy'
  properties: {
    policyContent: productPolicy
  }
  dependsOn: [
    apiManagementServiceName
  ]
}

resource apiManagementServiceName_exampleUser1 'Microsoft.ApiManagement/service/users@2017-03-01' = {
  parent: apiManagementServiceName
  name: 'exampleUser1'
  properties: {
    firstName: 'ExampleFirstName1'
    lastName: 'ExampleLastName1'
    email: 'ExampleFirst1@example.com'
    state: 'active'
    note: 'note for example user 1'
  }
}

resource apiManagementServiceName_exampleUser2 'Microsoft.ApiManagement/service/users@2017-03-01' = {
  parent: apiManagementServiceName
  name: 'exampleUser2'
  properties: {
    firstName: 'ExampleFirstName2'
    lastName: 'ExampleLastName2'
    email: 'ExampleFirst2@example.com'
    state: 'active'
    note: 'note for example user 2'
  }
}

resource apiManagementServiceName_exampleUser3 'Microsoft.ApiManagement/service/users@2017-03-01' = {
  parent: apiManagementServiceName
  name: 'exampleUser3'
  properties: {
    firstName: 'ExampleFirstName3'
    lastName: 'ExampleLastName3'
    email: 'ExampleFirst3@example.com'
    state: 'active'
    note: 'note for example user 3'
  }
}

resource apiManagementServiceName_exampleproperties 'Microsoft.ApiManagement/service/properties@2017-03-01' = {
  parent: apiManagementServiceName
  name: 'exampleproperties'
  properties: {
    displayName: 'propertyExampleName'
    value: 'propertyExampleValue'
    tags: [
      'exampleTag'
    ]
  }
}

resource apiManagementServiceName_examplesubscription1 'Microsoft.ApiManagement/service/subscriptions@2017-03-01' = {
  parent: apiManagementServiceName
  name: 'examplesubscription1'
  properties: {
    productId: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/exampleServiceName/products/exampleProduct'
    userId: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/exampleServiceName/users/exampleUser1'
  }
  dependsOn: [
    apiManagementServiceName_exampleProduct
    apiManagementServiceName_exampleUser1
  ]
}

resource apiManagementServiceName_examplesubscription2 'Microsoft.ApiManagement/service/subscriptions@2017-03-01' = {
  parent: apiManagementServiceName
  name: 'examplesubscription2'
  properties: {
    productId: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/exampleServiceName/products/exampleProduct'
    userId: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/exampleServiceName/users/exampleUser3'
  }
  dependsOn: [
    apiManagementServiceName_exampleProduct
    apiManagementServiceName_exampleUser3
    apiManagementServiceName_examplesubscription1
  ]
}

resource apiManagementServiceName_exampleCertificate 'Microsoft.ApiManagement/service/certificates@2017-03-01' = {
  parent: apiManagementServiceName
  name: 'exampleCertificate'
  properties: {
    data: mutualAuthenticationCertificate
    password: certificatePassword
  }
}

resource apiManagementServiceName_exampleGroup 'Microsoft.ApiManagement/service/groups@2017-03-01' = {
  parent: apiManagementServiceName
  name: 'exampleGroup'
  properties: {
    displayName: 'Example Group Name'
    description: 'Example group description'
  }
}

resource apiManagementServiceName_exampleGroup_exampleUser3 'Microsoft.ApiManagement/service/groups/users@2017-03-01' = {
  parent: apiManagementServiceName_exampleGroup
  name: 'exampleUser3'
  dependsOn: [
    apiManagementServiceName
  ]
}

resource apiManagementServiceName_exampleOpenIdConnectProvider 'Microsoft.ApiManagement/service/openidConnectProviders@2017-03-01' = {
  parent: apiManagementServiceName
  name: 'exampleOpenIdConnectProvider'
  properties: {
    displayName: 'exampleOpenIdConnectProviderName'
    description: 'Description for example OpenId Connect provider'
    metadataEndpoint: 'https://example-openIdConnect-url.net'
    clientId: 'exampleClientId'
    clientSecret: openIdConnectClientSecret
  }
}

resource apiManagementServiceName_exampleLogger 'Microsoft.ApiManagement/service/loggers@2017-03-01' = {
  parent: apiManagementServiceName
  name: 'exampleLogger'
  properties: {
    loggerType: 'azureEventHub'
    description: 'Description for example logger'
    credentials: {
      name: 'exampleEventHubName'
      connectionString: eventHubNamespaceConnectionString
    }
  }
}

resource apiManagementServiceName_google 'Microsoft.ApiManagement/service/identityProviders@2017-03-01' = {
  parent: apiManagementServiceName
  name: 'google'
  properties: {
    clientId: 'googleClientId'
    clientSecret: googleClientSecret
  }
}