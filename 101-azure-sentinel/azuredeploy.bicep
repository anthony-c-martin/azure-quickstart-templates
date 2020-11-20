param workspaceName string
param location string = resourceGroup().location

resource workspaceName_res 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: workspaceName
  location: location
  properties: {
    features: {
      immediatePurgeDataOn30Days: true
    }
    sku: {
      name: 'Free'
    }
  }
}

resource SecurityInsights_workspaceName 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'SecurityInsights(${workspaceName})'
  location: location
  properties: {
    workspaceResourceId: workspaceName_res.id
  }
  plan: {
    name: 'SecurityInsights(${workspaceName})'
    product: 'OMSGallery/SecurityInsights'
    publisher: 'Microsoft'
    promotionCode: ''
  }
}