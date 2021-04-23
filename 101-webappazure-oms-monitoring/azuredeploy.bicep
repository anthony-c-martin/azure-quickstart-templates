@description('Specify the workspace name')
param workspaceName string = ''

@description('Specify the workspace region')
param workspaceLocation string = ''

var omsSolutions = {
  customSolution: {
    name: 'Azure Web Apps Analytics'
    solutionName: 'AzureWebAppsAnalytics[${workspaceName}]'
    publisher: 'Microsoft'
    displayName: 'Azure Web Apps Analytics'
    description: 'Identify and troubleshoot issues across your Azure Web Apps'
    author: 'Microsoft'
  }
}

resource workspaceName_resource 'Microsoft.OperationalInsights/workspaces@2015-11-01-preview' = {
  name: workspaceName
  location: workspaceLocation
}

resource workspaceName_Azure_Web_Apps_Analytics 'Microsoft.OperationalInsights/workspaces/views@2015-11-01-preview' = {
  parent: workspaceName_resource
  name: 'Azure Web Apps Analytics'
  location: workspaceLocation
  properties: {
    Name: omsSolutions.customSolution.name
    Author: omsSolutions.customSolution.author
    Source: 'Local'
    Version: 2
    Dashboard: [
      {
        Id: 'LineChartBuilderBlade'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Azure Web Apps'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Web Apps Request Trends'
            Subtitle: ''
          }
          LineChart: {
            Query: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SITES/" and (MetricName == "Requests" or MetricName startswith_cs "Http") | summarize AggregatedValue = avg(Average) by MetricName, bin(TimeGenerated, 1h)| sort by TimeGenerated | render timechart'
            yAxis: {
              isLogarithmic: false
              units: {
                baseUnitType: ''
                baseUnit: ''
                displayUnit: ''
              }
              customLabel: ''
            }
            NavigationSelect: {}
          }
          List: {
            Query: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SITES/" and (MetricName == "Requests" or MetricName startswith_cs "Http") | summarize AggregatedValue = avg(Average) by MetricName'
            HideGraph: false
            enableSparklines: true
            ColumnsTitle: {
              Name: 'WEB REQUEST'
              Value: 'Count'
            }
            Color: '#002050'
            thresholds: {
              isEnabled: false
              values: [
                {
                  name: 'Normal'
                  threshold: 'Default'
                  color: '#009e49'
                  isDefault: true
                }
                {
                  name: 'Warning'
                  threshold: '60'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '90'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: 'search {selected item} | sort by TimeGenerated desc'
            NavigationSelect: {
              NavigationQuery: 'search {selected item} | sort by TimeGenerated desc'
            }
          }
        }
      }
      {
        Id: 'LineChartBuilderBlade'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: ''
            newGroup: false
            icon: ''
            useIcon: false
            tabGroupId: 1526326597101
          }
          Header: {
            Title: 'Web Apps Response Time'
            Subtitle: ''
          }
          LineChart: {
            Query: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SITES/" and MetricName == "AverageResponseTime" | summarize AggregatedValue = avg(Average) by Resource, bin(TimeGenerated, 1h) | sort by TimeGenerated | render timechart'
            yAxis: {
              isLogarithmic: false
              units: {
                baseUnitType: 'TimeRange'
                baseUnit: 'Seconds'
                displayUnit: 'AUTO'
              }
              customLabel: ''
            }
            NavigationSelect: {}
          }
          List: {
            Query: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SITES/" and MetricName == "AverageResponseTime" | summarize AggregatedValue = avg(Average) by Resource'
            HideGraph: false
            enableSparklines: true
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'WEB APP NAME'
              Value: 'RESPONSE TIME'
            }
            Color: '#dd5900'
            thresholds: {
              isEnabled: true
              values: [
                {
                  name: 'Normal'
                  threshold: 'Default'
                  color: '#009e49'
                  isDefault: true
                }
                {
                  name: 'Warning'
                  threshold: '0.7'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '1'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SITES/" and MetricName == "AverageResponseTime" and {selected item} | summarize AggregatedValue = avg(Average) by bin(TimeGenerated, 1h), Resource | sort by TimeGenerated desc | render timechart'
            NavigationSelect: {}
          }
        }
      }
      {
        Id: 'LineChartBuilderBlade'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: ''
            newGroup: false
            icon: 'data:image/jpeg;base64,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'
            useIcon: false
            tabGroupId: 1526326597190
          }
          Header: {
            Title: 'Web Apps Traffic'
            Subtitle: ''
          }
          LineChart: {
            Query: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SITES/" and (MetricName == "BytesSent" or "BytesReceived") | summarize AggregatedValue = sum(Average) by Resource, bin(TimeGenerated, 1h)| sort by TimeGenerated | render timechart'
            yAxis: {
              isLogarithmic: false
              units: {
                baseUnitType: 'Bits'
                baseUnit: 'Bytes'
                displayUnit: 'AUTO'
              }
              customLabel: ''
            }
            NavigationSelect: {}
          }
          List: {
            Query: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SITES/" and (MetricName == "BytesSent" or "BytesReceived") | summarize AggregatedValue = sum(Average) by Resource'
            HideGraph: false
            enableSparklines: true
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'WEB APP NAME'
              Value: 'TRAFFIC(BYTE)'
            }
            Color: '#007233'
            thresholds: {
              isEnabled: false
              values: [
                {
                  name: 'Normal'
                  threshold: 'Default'
                  color: '#009e49'
                  isDefault: true
                }
                {
                  name: 'Warning'
                  threshold: '60'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '90'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SITES/" and (MetricName == "BytesSent" or "BytesReceived") and {selected item} | summarize AggregatedValue = sum(Average) by bin(TimeGenerated, 1h), MetricName | sort by TimeGenerated desc | render barchart'
            NavigationSelect: {}
          }
        }
      }
      {
        Id: 'NumberTileListBuilderBlade'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Azure App Service Plans'
            newGroup: true
            icon: ''
            useIcon: false
            tabGroupId: 1526326597234
          }
          Tile: {
            Query: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SERVERFARMS/" and MetricName == "CpuPercentage" | summarize AggregatedValue = avg(Average) by Resource | where AggregatedValue > 80| count '
            Legend: 'App Service Plans with CPU utilization > 80%'
            NavigationSelect: {}
          }
          List: {
            Query: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SERVERFARMS/" and MetricName == "CpuPercentage" | summarize AggregatedValue = avg(Average) by Resource'
            HideGraph: false
            enableSparklines: true
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'APP SERVICE PLAN'
              Value: 'CPU (%)'
            }
            Color: '#0072c6'
            thresholds: {
              isEnabled: true
              values: [
                {
                  name: 'Normal'
                  threshold: 'Default'
                  color: '#009e49'
                  isDefault: true
                }
                {
                  name: 'Warning'
                  threshold: '60'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '80'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SERVERFARMS/" and MetricName == "CpuPercentage" and {selected item} | summarize AggregatedValue = avg(Average) by Resource'
            NavigationSelect: {}
          }
        }
      }
      {
        Id: 'NumberTileListBuilderBlade'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: ''
            newGroup: false
            icon: ''
            useIcon: false
            tabGroupId: 1526326597234
          }
          Tile: {
            Query: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SERVERFARMS/" and MetricName == "MemoryPercentage" | summarize AggregatedValue = avg(Average) by Resource | where AggregatedValue > 80\r\n| count'
            Legend: 'App Service Plan with memory utilization > 80%'
            NavigationSelect: {}
          }
          List: {
            Query: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SERVERFARMS/" and MetricName == "MemoryPercentage" | summarize AggregatedValue = avg(Average) by Resource\r\n'
            HideGraph: false
            enableSparklines: true
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'App Service Plan'
              Value: 'Memory (%)'
            }
            Color: '#0072c6'
            thresholds: {
              isEnabled: true
              values: [
                {
                  name: 'Normal'
                  threshold: 'Default'
                  color: '#009e49'
                  isDefault: true
                }
                {
                  name: 'Warning'
                  threshold: '60'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '80'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SERVERFARMS/" and MetricName == "MemoryPercentage" and {selected item} | summarize AggregatedValue = avg(Average) by Resource\r\n'
            NavigationSelect: {}
          }
        }
      }
      {
        Id: 'NumberTileListBuilderBlade'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Azure Web Apps Actiivity Logs'
            newGroup: true
            icon: ''
            useIcon: false
            tabGroupId: 1526326597243
          }
          Tile: {
            Query: 'AzureActivity | where ResourceProvider == "Azure Web Sites" | summarize AggregatedValue = count() by OperationName\r\n| count '
            Legend: 'Azure Web Apps Activity Audit'
            NavigationSelect: {}
          }
          List: {
            Query: 'AzureActivity | where ResourceProvider == "Azure Web Sites" | summarize AggregatedValue = count() by OperationName\r\n'
            HideGraph: false
            enableSparklines: false
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'Operation Name'
              Value: 'Count'
            }
            Color: '#0072c6'
            thresholds: {
              isEnabled: false
              values: [
                {
                  name: 'Normal'
                  threshold: 'Default'
                  color: '#009e49'
                  isDefault: true
                }
                {
                  name: 'Warning'
                  threshold: '60'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '90'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: 'search {selected item}'
            NavigationSelect: {}
          }
        }
      }
      {
        Id: 'NotableQueriesBuilderBlade'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'List of popular Azure Web Apps search queries'
            newGroup: false
            preselectedFilters: 'Type, Computer'
            renderMode: 'grid'
            tabGroupId: 1526326597246
          }
          queries: [
            {
              query: 'AzureMetrics | where ResourceProvider == "MICROSOFT.WEB" | sort by TimeGenerated desc'
              displayName: 'All Azure Web Apps Data'
            }
            {
              query: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SITES/" | summarize AggregatedValue = count() by MetricName | sort by AggregatedValue desc'
              displayName: 'List of all Azure Web Apps Performance Metrics'
            }
            {
              query: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SERVERFARMS/" | summarize AggregatedValue = count() by MetricName | sort by AggregatedValue desc'
              displayName: 'List of all Azure App Service Plan Performance Metrics'
            }
            {
              query: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SITES/" and MetricName == "AverageResponseTime" | summarize AggregatedValue = avg(Average) by bin(TimeGenerated, 5m), Resource | sort by TimeGenerated desc'
              displayName: 'Alert on High Web Apps Response Time'
            }
            {
              query: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SERVERFARMS/" and MetricName == "CpuPercentage" | summarize AggregatedValue = avg(Average) by bin(TimeGenerated, 5m), Resource | sort by TimeGenerated desc'
              displayName: 'Alert on App Service Plans with High CPU Utilization'
            }
            {
              query: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SERVERFARMS/" and MetricName == "MemoryPercentage" | summarize AggregatedValue = avg(Average) by bin(TimeGenerated, 5m), Resource | sort by TimeGenerated desc'
              displayName: 'Alert on App Service Plans with High Memory Utilization'
            }
          ]
        }
      }
    ]
    Filters: []
    OverviewTile: {
      Id: 'SingleNumberBuilderTile'
      Type: 'OverviewTile'
      Version: 2
      Configuration: {
        Tile: {
          Legend: 'Azure Web Apps Count'
          Query: 'search in (AzureMetrics) isnotempty(ResourceId) and "/MICROSOFT.WEB/SITES/" | summarize AggregatedValue = count() by Resource\r\n| count '
        }
        Advanced: {
          DataFlowVerification: {
            Enabled: true
            Query: 'AzureMetrics | where ResourceProvider == "MICROSOFT.WEB" | sort by TimeGenerated desc\r\n'
            Message: ' Ensure that you have run the script below to onboard your Azure PaaS Resources to send data to OMS.\n https://aka.ms/azurepaasonboarding'
          }
        }
      }
    }
  }
}

resource workspaceName_omsSolutions_customSolution_solutionName 'Microsoft.OperationalInsights/workspaces/Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: '${workspaceName}/${omsSolutions.customSolution.solutionName}'
  location: workspaceLocation
  plan: {
    name: omsSolutions.customSolution.solutionName
    product: omsSolutions.customSolution.name
    publisher: omsSolutions.customSolution.publisher
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: workspaceName_resource.id
    referencedResources: []
    containedResources: [
      resourceId('Microsoft.OperationalInsights/workspaces/views/', workspaceName, omsSolutions.customSolution.name)
    ]
  }
  dependsOn: [
    resourceId('Microsoft.OperationalInsights/workspaces/views', workspaceName, omsSolutions.customSolution.name)
  ]
}