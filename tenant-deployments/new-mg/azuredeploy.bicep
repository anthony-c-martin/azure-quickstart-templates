targetScope = 'tenant'
param mgName string = 'mg-${uniqueString(newGuid())}'

resource mgName_res 'Microsoft.Management/managementGroups@2020-02-01' = {
  name: mgName
  properties: {}
}