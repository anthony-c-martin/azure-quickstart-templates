param publisherEmail string {
  minLength: 1
  metadata: {
    description: 'The email address of the owner of the service'
  }
}
param publisherName string {
  minLength: 1
  metadata: {
    description: 'The name of the owner of the service'
  }
}
param sku string {
  allowed: [
    'Developer'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'The pricing tier of this API Management service'
  }
  default: 'Standard'
}
param skuCount int {
  metadata: {
    description: 'The instance size of this API Management service.'
  }
  default: 1
}
param mutualAuthenticationCertificate string {
  metadata: {
    description: 'Base-64 encoded Mutual authentication PFX certificate.'
  }
  secure: true
}
param certificatePassword string {
  metadata: {
    description: 'Mutual authentication certificate password.'
  }
  secure: true
}
param eventHubNamespaceConnectionString string {
  metadata: {
    description: 'EventHub connection string for logger.'
  }
  secure: true
}
param googleClientSecret string {
  metadata: {
    description: 'Google client secret to configure google identity.'
  }
  secure: true
}
param openIdConnectClientSecret string {
  metadata: {
    description: 'OpenId connect client secret.'
  }
  secure: true
}
param tenantPolicy string {
  metadata: {
    description: 'Tenant policy XML.'
  }
}
param apiPolicy string {
  metadata: {
    description: 'API policy XML.'
  }
}
param operationPolicy string {
  metadata: {
    description: 'Operation policy XML.'
  }
}
param productPolicy string {
  metadata: {
    description: 'Product policy XML.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

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
  name: '${apiManagementServiceName_var}/policy'
  properties: {
    policyContent: tenantPolicy
  }
  dependsOn: [
    apiManagementServiceName
  ]
}

resource apiManagementServiceName_PetStoreSwaggerImportExample 'Microsoft.ApiManagement/service/apis@2017-03-01' = {
  name: '${apiManagementServiceName_var}/PetStoreSwaggerImportExample'
  properties: {
    contentFormat: 'SwaggerLinkJson'
    contentValue: 'http://petstore.swagger.io/v2/swagger.json'
    path: 'examplepetstore'
  }
  dependsOn: [
    apiManagementServiceName
  ]
}

resource apiManagementServiceName_exampleApi 'Microsoft.ApiManagement/service/apis@2017-03-01' = {
  name: '${apiManagementServiceName_var}/exampleApi'
  properties: {
    displayName: 'Example API Name'
    description: 'Description for example API'
    serviceUrl: 'https://example.net'
    path: 'exampleapipath'
    protocols: [
      'HTTPS'
    ]
  }
  dependsOn: [
    apiManagementServiceName
  ]
}

resource apiManagementServiceName_exampleApi_exampleOperationsDELETE 'Microsoft.ApiManagement/service/apis/operations@2017-03-01' = {
  name: '${apiManagementServiceName_var}/exampleApi/exampleOperationsDELETE'
  properties: {
    displayName: 'DELETE resource'
    method: 'DELETE'
    urlTemplate: '/resource'
    description: 'A demonstration of a DELETE call'
  }
  dependsOn: [
    apiManagementServiceName_exampleApi
  ]
}

resource apiManagementServiceName_exampleApi_exampleOperationsGET 'Microsoft.ApiManagement/service/apis/operations@2017-03-01' = {
  name: '${apiManagementServiceName_var}/exampleApi/exampleOperationsGET'
  properties: {
    displayName: 'GET resource'
    method: 'GET'
    urlTemplate: '/resource'
    description: 'A demonstration of a GET call'
  }
  dependsOn: [
    apiManagementServiceName_exampleApi
  ]
}

resource apiManagementServiceName_exampleApi_exampleOperationsGET_policy 'Microsoft.ApiManagement/service/apis/operations/policies@2017-03-01' = {
  name: '${'${apiManagementServiceName_var}/exampleApi'}/exampleOperationsGET/policy'
  properties: {
    policyContent: operationPolicy
  }
  dependsOn: [
    apiManagementServiceName
    apiManagementServiceName_exampleApi
    'Microsoft.ApiManagement/service/${apiManagementServiceName_var}/apis/exampleApi/operations/exampleOperationsGET'
  ]
}

resource apiManagementServiceName_exampleApiWithPolicy 'Microsoft.ApiManagement/service/apis@2017-03-01' = {
  name: '${apiManagementServiceName_var}/exampleApiWithPolicy'
  properties: {
    displayName: 'Example API Name with Policy'
    description: 'Description for example API with policy'
    serviceUrl: 'https://exampleapiwithpolicy.net'
    path: 'exampleapiwithpolicypath'
    protocols: [
      'HTTPS'
    ]
  }
  dependsOn: [
    apiManagementServiceName
  ]
}

resource apiManagementServiceName_exampleApiWithPolicy_policy 'Microsoft.ApiManagement/service/apis/policies@2017-03-01' = {
  name: '${apiManagementServiceName_var}/exampleApiWithPolicy/policy'
  properties: {
    policyContent: apiPolicy
  }
  dependsOn: [
    apiManagementServiceName
    apiManagementServiceName_exampleApiWithPolicy
  ]
}

resource apiManagementServiceName_exampleProduct 'Microsoft.ApiManagement/service/products@2017-03-01' = {
  name: '${apiManagementServiceName_var}/exampleProduct'
  properties: {
    displayName: 'Example Product Name'
    description: 'Description for example product'
    terms: 'Terms for example product'
    subscriptionRequired: true
    approvalRequired: false
    subscriptionsLimit: 1
    state: 'published'
  }
  dependsOn: [
    apiManagementServiceName
  ]
}

resource apiManagementServiceName_exampleProduct_exampleApi 'Microsoft.ApiManagement/service/products/apis@2017-03-01' = {
  name: '${apiManagementServiceName_var}/exampleProduct/exampleApi'
  dependsOn: [
    apiManagementServiceName
    apiManagementServiceName_exampleApi
    apiManagementServiceName_exampleProduct
  ]
}

resource apiManagementServiceName_exampleProduct_policy 'Microsoft.ApiManagement/service/products/policies@2017-03-01' = {
  name: '${apiManagementServiceName_var}/exampleProduct/policy'
  properties: {
    policyContent: productPolicy
  }
  dependsOn: [
    apiManagementServiceName
    apiManagementServiceName_exampleProduct
  ]
}

resource apiManagementServiceName_exampleUser1 'Microsoft.ApiManagement/service/users@2017-03-01' = {
  name: '${apiManagementServiceName_var}/exampleUser1'
  properties: {
    firstName: 'ExampleFirstName1'
    lastName: 'ExampleLastName1'
    email: 'ExampleFirst1@example.com'
    state: 'active'
    note: 'note for example user 1'
  }
  dependsOn: [
    apiManagementServiceName
  ]
}

resource apiManagementServiceName_exampleUser2 'Microsoft.ApiManagement/service/users@2017-03-01' = {
  name: '${apiManagementServiceName_var}/exampleUser2'
  properties: {
    firstName: 'ExampleFirstName2'
    lastName: 'ExampleLastName2'
    email: 'ExampleFirst2@example.com'
    state: 'active'
    note: 'note for example user 2'
  }
  dependsOn: [
    apiManagementServiceName
  ]
}

resource apiManagementServiceName_exampleUser3 'Microsoft.ApiManagement/service/users@2017-03-01' = {
  name: '${apiManagementServiceName_var}/exampleUser3'
  properties: {
    firstName: 'ExampleFirstName3'
    lastName: 'ExampleLastName3'
    email: 'ExampleFirst3@example.com'
    state: 'active'
    note: 'note for example user 3'
  }
  dependsOn: [
    apiManagementServiceName
  ]
}

resource apiManagementServiceName_exampleproperties 'Microsoft.ApiManagement/service/properties@2017-03-01' = {
  name: '${apiManagementServiceName_var}/exampleproperties'
  properties: {
    displayName: 'propertyExampleName'
    value: 'propertyExampleValue'
    tags: [
      'exampleTag'
    ]
  }
  dependsOn: [
    apiManagementServiceName
  ]
}

resource apiManagementServiceName_examplesubscription1 'Microsoft.ApiManagement/service/subscriptions@2017-03-01' = {
  name: '${apiManagementServiceName_var}/examplesubscription1'
  properties: {
    productId: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/exampleServiceName/products/exampleProduct'
    userId: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/exampleServiceName/users/exampleUser1'
  }
  dependsOn: [
    apiManagementServiceName
    apiManagementServiceName_exampleProduct
    apiManagementServiceName_exampleUser1
  ]
}

resource apiManagementServiceName_examplesubscription2 'Microsoft.ApiManagement/service/subscriptions@2017-03-01' = {
  name: '${apiManagementServiceName_var}/examplesubscription2'
  properties: {
    productId: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/exampleServiceName/products/exampleProduct'
    userId: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/exampleServiceName/users/exampleUser3'
  }
  dependsOn: [
    apiManagementServiceName
    apiManagementServiceName_exampleProduct
    apiManagementServiceName_exampleUser3
    apiManagementServiceName_examplesubscription1
  ]
}

resource apiManagementServiceName_exampleCertificate 'Microsoft.ApiManagement/service/certificates@2017-03-01' = {
  name: '${apiManagementServiceName_var}/exampleCertificate'
  properties: {
    data: mutualAuthenticationCertificate
    password: certificatePassword
  }
  dependsOn: [
    apiManagementServiceName
  ]
}

resource apiManagementServiceName_exampleGroup 'Microsoft.ApiManagement/service/groups@2017-03-01' = {
  name: '${apiManagementServiceName_var}/exampleGroup'
  properties: {
    displayName: 'Example Group Name'
    description: 'Example group description'
  }
  dependsOn: [
    apiManagementServiceName
  ]
}

resource apiManagementServiceName_exampleGroup_exampleUser3 'Microsoft.ApiManagement/service/groups/users@2017-03-01' = {
  name: '${apiManagementServiceName_var}/exampleGroup/exampleUser3'
  dependsOn: [
    apiManagementServiceName
    apiManagementServiceName_exampleGroup
  ]
}

resource apiManagementServiceName_exampleOpenIdConnectProvider 'Microsoft.ApiManagement/service/openidConnectProviders@2017-03-01' = {
  name: '${apiManagementServiceName_var}/exampleOpenIdConnectProvider'
  properties: {
    displayName: 'exampleOpenIdConnectProviderName'
    description: 'Description for example OpenId Connect provider'
    metadataEndpoint: 'https://example-openIdConnect-url.net'
    clientId: 'exampleClientId'
    clientSecret: openIdConnectClientSecret
  }
  dependsOn: [
    apiManagementServiceName
  ]
}

resource apiManagementServiceName_exampleLogger 'Microsoft.ApiManagement/service/loggers@2017-03-01' = {
  name: '${apiManagementServiceName_var}/exampleLogger'
  properties: {
    loggerType: 'azureEventHub'
    description: 'Description for example logger'
    credentials: {
      name: 'exampleEventHubName'
      connectionString: eventHubNamespaceConnectionString
    }
  }
  dependsOn: [
    apiManagementServiceName
  ]
}

resource apiManagementServiceName_google 'Microsoft.ApiManagement/service/identityProviders@2017-03-01' = {
  name: '${apiManagementServiceName_var}/google'
  properties: {
    clientId: 'googleClientId'
    clientSecret: googleClientSecret
  }
  dependsOn: [
    apiManagementServiceName
  ]
}