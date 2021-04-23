@description('The name of the dashboard')
param dashboardName string = resourceGroup().name

@description('The location of the resources.')
param location string = resourceGroup().location

resource SHARED_DASHBOARD_dashboardName 'Microsoft.Portal/dashboards@2019-01-01-preview' = {
  name: 'SHARED-DASHBOARD-${dashboardName}'
  location: location
  tags: {
    'hidden-title': dashboardName
  }
  properties: {
    lenses: {
      '0': {
        order: 0
        parts: {
          '0': {
            position: {
              x: 0
              y: 0
              colSpan: 4
              rowSpan: 6
            }
            metadata: {
              inputs: [
                {
                  name: 'resourceGroup'
                  isOptional: true
                }
                {
                  name: 'id'
                  value: resourceGroup().id
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/ResourceGroupMapPinnedPart'
            }
          }
          '1': {
            position: {
              x: 4
              y: 0
              rowSpan: 3
              colSpan: 4
            }
            metadata: {
              inputs: []
              type: 'Extension[azure]/HubsExtension/PartType/MarkdownPart'
              settings: {
                content: {
                  settings: {
                    content: '__Customizations__\n\nUse this dashboard to create and share the operational views of services critical to the application performing. To customize simply pin components to the dashboard and then publish when you\'re done. Others will see your changes when you publish and share the dashboard.\n\nYou can customize this text too. It supports plain text, __Markdown__, and even limited HTML like images <img width=\'10\' src=\'https://portal.azure.com/favicon.ico\'/> and <a href=\'https://azure.microsoft.com\' target=\'_blank\'>links</a> that open in a new tab.\n'
                    title: 'Operations'
                    subtitle: resourceGroup().name
                  }
                }
              }
            }
          }
        }
      }
    }
    metadata: {
      model: {
        timeRange: {
          value: {
            relative: {
              duration: 24
              timeUnit: 1
            }
          }
          type: 'MsPortalFx.Composition.Configuration.ValueTypes.TimeRange'
        }
      }
    }
  }
}