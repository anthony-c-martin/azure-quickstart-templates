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

var apiManagementServiceName = 'apiservice${uniqueString(resourceGroup().id)}'

resource apiManagementServiceName_resource 'Microsoft.ApiManagement/service@2017-03-01' = {
  name: apiManagementServiceName
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
  name: '${apiManagementServiceName}/policy'
  properties: {
    policyContent: tenantPolicy
  }
  dependsOn: [
    apiManagementServiceName_resource
  ]
}

resource apiManagementServiceName_PetStoreSwaggerImportExample 'Microsoft.ApiManagement/service/apis@2017-03-01' = {
  name: '${apiManagementServiceName}/PetStoreSwaggerImportExample'
  properties: {
    contentFormat: 'SwaggerLinkJson'
    contentValue: 'http://petstore.swagger.io/v2/swagger.json'
    path: 'examplepetstore'
  }
  dependsOn: [
    apiManagementServiceName_resource
  ]
}

resource apiManagementServiceName_exampleApi 'Microsoft.ApiManagement/service/apis@2017-03-01' = {
  name: '${apiManagementServiceName}/exampleApi'
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
    apiManagementServiceName_resource
  ]
}

resource apiManagementServiceName_exampleApi_exampleOperationsDELETE 'Microsoft.ApiManagement/service/apis/operations@2017-03-01' = {
  name: '${apiManagementServiceName}/exampleApi/exampleOperationsDELETE'
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
  name: '${apiManagementServiceName}/exampleApi/exampleOperationsGET'
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
  name: '${'${apiManagementServiceName}/exampleApi'}/exampleOperationsGET/policy'
  properties: {
    policyContent: operationPolicy
  }
  dependsOn: [
    apiManagementServiceName_resource
    apiManagementServiceName_exampleApi
    'Microsoft.ApiManagement/service/${apiManagementServiceName}/apis/exampleApi/operations/exampleOperationsGET'
  ]
}

resource apiManagementServiceName_exampleApiWithPolicy 'Microsoft.ApiManagement/service/apis@2017-03-01' = {
  name: '${apiManagementServiceName}/exampleApiWithPolicy'
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
    apiManagementServiceName_resource
  ]
}

resource apiManagementServiceName_exampleApiWithPolicy_policy 'Microsoft.ApiManagement/service/apis/policies@2017-03-01' = {
  name: '${apiManagementServiceName}/exampleApiWithPolicy/policy'
  properties: {
    policyContent: apiPolicy
  }
  dependsOn: [
    apiManagementServiceName_resource
    apiManagementServiceName_exampleApiWithPolicy
  ]
}

resource apiManagementServiceName_exampleProduct 'Microsoft.ApiManagement/service/products@2017-03-01' = {
  name: '${apiManagementServiceName}/exampleProduct'
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
    apiManagementServiceName_resource
  ]
}

resource apiManagementServiceName_exampleProduct_exampleApi 'Microsoft.ApiManagement/service/products/apis@2017-03-01' = {
  name: '${apiManagementServiceName}/exampleProduct/exampleApi'
  dependsOn: [
    apiManagementServiceName_resource
    apiManagementServiceName_exampleApi
    apiManagementServiceName_exampleProduct
  ]
}

resource apiManagementServiceName_exampleProduct_policy 'Microsoft.ApiManagement/service/products/policies@2017-03-01' = {
  name: '${apiManagementServiceName}/exampleProduct/policy'
  properties: {
    policyContent: productPolicy
  }
  dependsOn: [
    apiManagementServiceName_resource
    apiManagementServiceName_exampleProduct
  ]
}

resource apiManagementServiceName_exampleUser1 'Microsoft.ApiManagement/service/users@2017-03-01' = {
  name: '${apiManagementServiceName}/exampleUser1'
  properties: {
    firstName: 'ExampleFirstName1'
    lastName: 'ExampleLastName1'
    email: 'ExampleFirst1@example.com'
    state: 'active'
    note: 'note for example user 1'
  }
  dependsOn: [
    apiManagementServiceName_resource
  ]
}

resource apiManagementServiceName_exampleUser2 'Microsoft.ApiManagement/service/users@2017-03-01' = {
  name: '${apiManagementServiceName}/exampleUser2'
  properties: {
    firstName: 'ExampleFirstName2'
    lastName: 'ExampleLastName2'
    email: 'ExampleFirst2@example.com'
    state: 'active'
    note: 'note for example user 2'
  }
  dependsOn: [
    apiManagementServiceName_resource
  ]
}

resource apiManagementServiceName_exampleUser3 'Microsoft.ApiManagement/service/users@2017-03-01' = {
  name: '${apiManagementServiceName}/exampleUser3'
  properties: {
    firstName: 'ExampleFirstName3'
    lastName: 'ExampleLastName3'
    email: 'ExampleFirst3@example.com'
    state: 'active'
    note: 'note for example user 3'
  }
  dependsOn: [
    apiManagementServiceName_resource
  ]
}

resource apiManagementServiceName_exampleproperties 'Microsoft.ApiManagement/service/properties@2017-03-01' = {
  name: '${apiManagementServiceName}/exampleproperties'
  properties: {
    displayName: 'propertyExampleName'
    value: 'propertyExampleValue'
    tags: [
      'exampleTag'
    ]
  }
  dependsOn: [
    apiManagementServiceName_resource
  ]
}

resource apiManagementServiceName_examplesubscription1 'Microsoft.ApiManagement/service/subscriptions@2017-03-01' = {
  name: '${apiManagementServiceName}/examplesubscription1'
  properties: {
    productId: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/exampleServiceName/products/exampleProduct'
    userId: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/exampleServiceName/users/exampleUser1'
  }
  dependsOn: [
    apiManagementServiceName_resource
    apiManagementServiceName_exampleProduct
    apiManagementServiceName_exampleUser1
  ]
}

resource apiManagementServiceName_examplesubscription2 'Microsoft.ApiManagement/service/subscriptions@2017-03-01' = {
  name: '${apiManagementServiceName}/examplesubscription2'
  properties: {
    productId: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/exampleServiceName/products/exampleProduct'
    userId: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/exampleServiceName/users/exampleUser3'
  }
  dependsOn: [
    apiManagementServiceName_resource
    apiManagementServiceName_exampleProduct
    apiManagementServiceName_exampleUser3
    apiManagementServiceName_examplesubscription1
  ]
}

resource apiManagementServiceName_exampleCertificate 'Microsoft.ApiManagement/service/certificates@2017-03-01' = {
  name: '${apiManagementServiceName}/exampleCertificate'
  properties: {
    data: mutualAuthenticationCertificate
    password: certificatePassword
  }
  dependsOn: [
    apiManagementServiceName_resource
  ]
}

resource apiManagementServiceName_exampleGroup 'Microsoft.ApiManagement/service/groups@2017-03-01' = {
  name: '${apiManagementServiceName}/exampleGroup'
  properties: {
    displayName: 'Example Group Name'
    description: 'Example group description'
  }
  dependsOn: [
    apiManagementServiceName_resource
  ]
}

resource apiManagementServiceName_exampleGroup_exampleUser3 'Microsoft.ApiManagement/service/groups/users@2017-03-01' = {
  name: '${apiManagementServiceName}/exampleGroup/exampleUser3'
  dependsOn: [
    apiManagementServiceName_resource
    apiManagementServiceName_exampleGroup
  ]
}

resource apiManagementServiceName_exampleOpenIdConnectProvider 'Microsoft.ApiManagement/service/openidConnectProviders@2017-03-01' = {
  name: '${apiManagementServiceName}/exampleOpenIdConnectProvider'
  properties: {
    displayName: 'exampleOpenIdConnectProviderName'
    description: 'Description for example OpenId Connect provider'
    metadataEndpoint: 'https://example-openIdConnect-url.net'
    clientId: 'exampleClientId'
    clientSecret: openIdConnectClientSecret
  }
  dependsOn: [
    apiManagementServiceName_resource
  ]
}

resource apiManagementServiceName_exampleLogger 'Microsoft.ApiManagement/service/loggers@2017-03-01' = {
  name: '${apiManagementServiceName}/exampleLogger'
  properties: {
    loggerType: 'azureEventHub'
    description: 'Description for example logger'
    credentials: {
      name: 'exampleEventHubName'
      connectionString: eventHubNamespaceConnectionString
    }
  }
  dependsOn: [
    apiManagementServiceName_resource
  ]
}

resource apiManagementServiceName_google 'Microsoft.ApiManagement/service/identityProviders@2017-03-01' = {
  name: '${apiManagementServiceName}/google'
  properties: {
    clientId: 'googleClientId'
    clientSecret: googleClientSecret
  }
  dependsOn: [
    apiManagementServiceName_resource
  ]
}