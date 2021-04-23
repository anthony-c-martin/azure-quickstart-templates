param nsgName string
param location string
param securityRules array
param tags object

resource nsgName_resource 'Microsoft.Network/networkSecurityGroups@2018-06-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: securityRules
  }
}