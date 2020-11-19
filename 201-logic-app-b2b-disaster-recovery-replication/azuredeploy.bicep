param AS2_DR_LogicApp_Name string = 'as2-dr'
param Edifact_DR_LogicApp_Name string = 'edifact-dr'
param X12_DR_LogicApp_Name string = 'x12-dr'
param DR_LogicApp_Location string {
  allowed: [
    resourceGroup().location
    'eastasia'
    'southeastasia'
    'centralus'
    'eastus'
    'eastus2'
    'westus'
    'northcentralus'
    'southcentralus'
    'northeurope'
    'westeurope'
    'japanwest'
    'japaneast'
    'brazilsouth'
    'australiaeast'
    'australiasoutheast'
    'southindia'
    'centralindia'
    'westindia'
    'canadacentral'
    'canadaeast'
    'westcentralus'
    'westus2'
  ]
  metadata: {
    description: 'Location of the Logic App.'
  }
  default: resourceGroup().location
}
param Primary_IntegrationAccountResourceGroup string = 'primary-rg'
param Primary_IntegrationAccountName string {
  metadata: {
    description: 'Integration Account Name'
  }
  default: 'primary-ia'
}
param Secondary_IntegrationAccountName string {
  metadata: {
    description: 'Integration Account Name'
  }
  default: 'secondary-ia'
}
param AS2_Primary_Connection_Name string = 'as2-primary'
param AS2_Primary_Connection_DisplayName string = 'as2-primary'
param AS2_Secondary_Connection_Name string = 'as2-secondary'
param AS2_Secondary_Connection_DisplayName string = 'as2-secondary'
param Edifact_Primary_Connection_Name string = 'edifact-primary'
param Edifact_Primary_Connection_DisplayName string = 'edifact-primary'
param Edifact_Secondary_Connection_Name string = 'edifact-secondary'
param Edifact_Secondary_Connection_DisplayName string = 'edifact-secondary'
param X12_Primary_Connection_Name string = 'x12-primary'
param X12_Primary_Connection_DisplayName string = 'x12-primary'
param X12_Secondary_Connection_Name string = 'x12-secondary'
param X12_Secondary_Connection_DisplayName string = 'x12-secondary'

resource AS2_DR_LogicApp_Name_resource 'Microsoft.Logic/workflows@2016-06-01' = {
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        Add_or_update_MIC_contents: {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            body: '@triggerBody()'
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'as2-secondary\'][\'connectionId\']'
              }
            }
            method: 'put'
            path: '/createOrUpdateMicValues'
          }
        }
      }
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        When_a_MIC_value_is_created: {
          recurrence: {
            frequency: 'Minute'
            interval: 1
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'as2-primary\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/triggers/onCreatedMicValues'
          }
        }
      }
      contentVersion: '1.0.0.0'
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          'as2-primary': {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${DR_LogicApp_Location}/managedApis/as2'
            connectionId: AS2_Primary_Connection_Name_resource.id
            connectionName: AS2_Primary_Connection_Name
          }
          'as2-secondary': {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${DR_LogicApp_Location}/managedApis/as2'
            connectionId: AS2_Secondary_Connection_Name_resource.id
            connectionName: AS2_Secondary_Connection_Name
          }
        }
      }
    }
  }
  name: AS2_DR_LogicApp_Name
  location: DR_LogicApp_Location
  dependsOn: [
    AS2_Primary_Connection_Name_resource
    AS2_Secondary_Connection_Name_resource
  ]
}

resource Edifact_DR_LogicApp_Name_resource 'Microsoft.Logic/workflows@2016-06-01' = {
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        Add_or_update_control_numbers: {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            body: '@triggerBody()'
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'edifact-secondary\'][\'connectionId\']'
              }
            }
            method: 'put'
            path: '/controlnumbers'
          }
        }
      }
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        When_a_control_number_is_modified: {
          recurrence: {
            frequency: 'Minute'
            interval: 1
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'edifact-primary\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/triggers/onmodifiedcontrolnumber'
          }
        }
      }
      contentVersion: '1.0.0.0'
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          'edifact-primary': {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${DR_LogicApp_Location}/managedApis/edifact'
            connectionId: Edifact_Primary_Connection_Name_resource.id
            connectionName: Edifact_Primary_Connection_Name
          }
          'edifact-secondary': {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${DR_LogicApp_Location}/managedApis/edifact'
            connectionId: Edifact_Secondary_Connection_Name_resource.id
            connectionName: Edifact_Secondary_Connection_Name
          }
        }
      }
    }
  }
  name: Edifact_DR_LogicApp_Name
  location: DR_LogicApp_Location
  dependsOn: [
    Edifact_Primary_Connection_Name_resource
    Edifact_Secondary_Connection_Name_resource
  ]
}

resource X12_DR_LogicApp_Name_resource 'Microsoft.Logic/workflows@2016-06-01' = {
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        Add_or_update_control_numbers: {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            body: '@triggerBody()'
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'x12-secondary\'][\'connectionId\']'
              }
            }
            method: 'put'
            path: '/controlNumbers'
          }
        }
      }
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        When_a_control_number_is_modified: {
          recurrence: {
            frequency: 'Minute'
            interval: 1
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'x12-primary\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/triggers/onModifiedControlNumber'
          }
        }
      }
      contentVersion: '1.0.0.0'
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          'x12-secondary': {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${DR_LogicApp_Location}/managedApis/x12'
            connectionId: X12_Secondary_Connection_Name_resource.id
            connectionName: X12_Secondary_Connection_Name
          }
          'x12-primary': {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${DR_LogicApp_Location}/managedApis/x12'
            connectionId: X12_Primary_Connection_Name_resource.id
            connectionName: X12_Primary_Connection_Name
          }
        }
      }
    }
  }
  name: X12_DR_LogicApp_Name
  location: DR_LogicApp_Location
  dependsOn: [
    X12_Primary_Connection_Name_resource
    X12_Secondary_Connection_Name_resource
  ]
}

resource AS2_Primary_Connection_Name_resource 'MICROSOFT.WEB/CONNECTIONS@2016-06-01' = {
  name: AS2_Primary_Connection_Name
  location: DR_LogicApp_Location
  properties: {
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${DR_LogicApp_Location}/managedApis/as2'
    }
    displayName: AS2_Primary_Connection_DisplayName
    parameterValues: {
      integrationAccountId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${Primary_IntegrationAccountResourceGroup}/providers/Microsoft.Logic/integrationaccounts/${Primary_IntegrationAccountName}'
      integrationAccountUrl: listCallbackURL('/subscriptions/${subscription().subscriptionId}/resourceGroups/${Primary_IntegrationAccountResourceGroup}/providers/Microsoft.Logic/integrationaccounts/${Primary_IntegrationAccountName}', '2016-06-01').value
    }
  }
}

resource AS2_Secondary_Connection_Name_resource 'MICROSOFT.WEB/CONNECTIONS@2016-06-01' = {
  name: AS2_Secondary_Connection_Name
  location: DR_LogicApp_Location
  properties: {
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${DR_LogicApp_Location}/managedApis/as2'
    }
    displayName: AS2_Secondary_Connection_DisplayName
    parameterValues: {
      integrationAccountId: resourceId('Microsoft.Logic/integrationaccounts', Secondary_IntegrationAccountName)
      integrationAccountUrl: listCallbackURL(resourceId('Microsoft.Logic/integrationaccounts', Secondary_IntegrationAccountName), '2016-06-01').value
    }
  }
}

resource Edifact_Primary_Connection_Name_resource 'MICROSOFT.WEB/CONNECTIONS@2016-06-01' = {
  name: Edifact_Primary_Connection_Name
  location: DR_LogicApp_Location
  properties: {
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${DR_LogicApp_Location}/managedApis/edifact'
    }
    displayName: Edifact_Primary_Connection_DisplayName
    parameterValues: {
      integrationAccountId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${Primary_IntegrationAccountResourceGroup}/providers/Microsoft.Logic/integrationaccounts/${Primary_IntegrationAccountName}'
      integrationAccountUrl: listCallbackURL('/subscriptions/${subscription().subscriptionId}/resourceGroups/${Primary_IntegrationAccountResourceGroup}/providers/Microsoft.Logic/integrationaccounts/${Primary_IntegrationAccountName}', '2016-06-01').value
    }
  }
}

resource Edifact_Secondary_Connection_Name_resource 'MICROSOFT.WEB/CONNECTIONS@2016-06-01' = {
  name: Edifact_Secondary_Connection_Name
  location: DR_LogicApp_Location
  properties: {
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${DR_LogicApp_Location}/managedApis/edifact'
    }
    displayName: Edifact_Secondary_Connection_DisplayName
    parameterValues: {
      integrationAccountId: resourceId('Microsoft.Logic/integrationaccounts', Secondary_IntegrationAccountName)
      integrationAccountUrl: listCallbackURL(resourceId('Microsoft.Logic/integrationaccounts', Secondary_IntegrationAccountName), '2016-06-01').value
    }
  }
}

resource X12_Primary_Connection_Name_resource 'MICROSOFT.WEB/CONNECTIONS@2016-06-01' = {
  name: X12_Primary_Connection_Name
  location: DR_LogicApp_Location
  properties: {
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${DR_LogicApp_Location}/managedApis/x12'
    }
    displayName: X12_Primary_Connection_DisplayName
    parameterValues: {
      integrationAccountId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${Primary_IntegrationAccountResourceGroup}/providers/Microsoft.Logic/integrationaccounts/${Primary_IntegrationAccountName}'
      integrationAccountUrl: listCallbackURL('/subscriptions/${subscription().subscriptionId}/resourceGroups/${Primary_IntegrationAccountResourceGroup}/providers/Microsoft.Logic/integrationaccounts/${Primary_IntegrationAccountName}', '2016-06-01').value
    }
  }
}

resource X12_Secondary_Connection_Name_resource 'MICROSOFT.WEB/CONNECTIONS@2016-06-01' = {
  name: X12_Secondary_Connection_Name
  location: DR_LogicApp_Location
  properties: {
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${DR_LogicApp_Location}/managedApis/x12'
    }
    displayName: X12_Secondary_Connection_DisplayName
    parameterValues: {
      integrationAccountId: resourceId('Microsoft.Logic/integrationaccounts', Secondary_IntegrationAccountName)
      integrationAccountUrl: listCallbackURL(resourceId('Microsoft.Logic/integrationaccounts', Secondary_IntegrationAccountName), '2016-06-01').value
    }
  }
}