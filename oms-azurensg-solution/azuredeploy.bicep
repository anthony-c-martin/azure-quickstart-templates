param workspaceName string {
  metadata: {
    description: 'Specify the workspace name'
  }
}
param workspaceLocation string {
  metadata: {
    description: 'Specify the workspace region'
  }
}

var omsSolutions = {
  customSolution: {
    name: 'Azure Network Security Group Analytics'
    solutionName: 'AzureNSGAnalytics[${workspaceName}]'
    publisher: 'Microsoft'
    displayName: 'Azure Network Security Group Analytics'
    description: 'Gain insight into your Azure Network Security Group logs'
    author: 'Microsoft'
  }
}

resource workspaceName_resource 'Microsoft.OperationalInsights/workspaces@2015-11-01-preview' = {
  name: workspaceName
  location: workspaceLocation
}

resource workspaceName_Azure_Network_Security_Group_Analytics 'Microsoft.OperationalInsights/workspaces/views@2015-11-01-preview' = {
  name: '${workspaceName}/Azure Network Security Group Analytics'
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
            title: 'Network Security Group Blocked Flows'
            newGroup: true
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Rules with blocked flows'
            Subtitle: ''
          }
          LineChart: {
            Query: 'AzureDiagnostics | where ResourceType == "NETWORKSECURITYGROUPS" and Category == "NetworkSecurityGroupRuleCounter" and type_s == "block" | summarize AggregatedValue = sum(matchedConnections_d) by ruleName_s , bin(TimeGenerated, 1h)| where AggregatedValue >0 |render timechart'
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
            Query: 'AzureDiagnostics | where ResourceType == "NETWORKSECURITYGROUPS" and Category == "NetworkSecurityGroupRuleCounter" and type_s == "block" | summarize AggregatedValue = sum(matchedConnections_d) by ruleName_s | where AggregatedValue > 0'
            HideGraph: false
            enableSparklines: true
            ColumnsTitle: {
              Name: 'Rule'
              Value: 'Blocked Flows Last Hour'
            }
            Color: '#0072c6'
            operation: 'Last Sample'
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
            tabGroupId: '1528570627308'
          }
          Header: {
            Title: 'MAC Addresses with Blocked Flows'
            Subtitle: ''
          }
          LineChart: {
            Query: 'AzureDiagnostics | where ResourceType == "NETWORKSECURITYGROUPS" and Category == "NetworkSecurityGroupRuleCounter" and type_s == "block" | summarize AggregatedValue = sum(matchedConnections_d) by subnetPrefix_s, bin(TimeGenerated, 1h)| render timechart'
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
            Query: 'AzureDiagnostics | where ResourceType == "NETWORKSECURITYGROUPS" and Category == "NetworkSecurityGroupRuleCounter" and type_s == "block" | summarize AggregatedValue = sum(matchedConnections_d) by subnetPrefix_s'
            HideGraph: false
            enableSparklines: true
            operation: 'Last Sample'
            ColumnsTitle: {
              Name: 'MAC Address'
              Value: 'Blocked Flows Last Hour'
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
            NavigationQuery: 'search in (AzureDiagnostics) ResourceType == "NETWORKSECURITYGROUPS" and Category == "NetworkSecurityGroupRuleCounter" and {selected item} | sort by TimeGenerated desc'
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
            title: 'Network Security Group Allowed Flows'
            newGroup: true
            icon: ''
            useIcon: false
            tabGroupId: '1528570627315'
          }
          Header: {
            Title: 'Rules with Allowed Flows'
            Subtitle: ''
          }
          LineChart: {
            Query: 'AzureDiagnostics | where ResourceType == "NETWORKSECURITYGROUPS" and Category == "NetworkSecurityGroupRuleCounter" and type_s == "allow" | summarize AggregatedValue = sum(matchedConnections_d) by ruleName_s, bin(TimeGenerated, 1h) | where AggregatedValue > 0| render timechart'
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
            Query: 'AzureDiagnostics | where ResourceType == "NETWORKSECURITYGROUPS" and Category == "NetworkSecurityGroupRuleCounter" and type_s == "allow" | summarize AggregatedValue = sum(matchedConnections_d) by ruleName_s| where AggregatedValue > 0'
            HideGraph: false
            enableSparklines: true
            operation: 'Last Sample'
            ColumnsTitle: {
              Name: 'Rule'
              Value: 'Allowed Flows Last Hour'
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
            NavigationQuery: 'search in (AzureDiagnostics) ResourceType == "NETWORKSECURITYGROUPS" and Category == "NetworkSecurityGroupRuleCounter" and {selected item} | sort by TimeGenerated desc'
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
            title: ' '
            newGroup: false
            icon: ''
            useIcon: false
            tabGroupId: '1528570627318'
          }
          Header: {
            Title: 'MAC Addresses with Allowed Flows'
            Subtitle: ''
          }
          LineChart: {
            Query: 'AzureDiagnostics | where ResourceType == "NETWORKSECURITYGROUPS" and Category == "NetworkSecurityGroupRuleCounter" and type_s == "allow" | summarize AggregatedValue = sum(matchedConnections_d) by subnetPrefix_s, bin(TimeGenerated, 1h) | render timechart'
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
            Query: 'AzureDiagnostics | where ResourceType == "NETWORKSECURITYGROUPS" and Category == "NetworkSecurityGroupRuleCounter" and type_s == "block" | summarize AggregatedValue = sum(matchedConnections_d) by subnetPrefix_s'
            HideGraph: false
            enableSparklines: true
            operation: 'Last Sample'
            ColumnsTitle: {
              Name: 'MAC Address'
              Value: 'Allowed Flows Last Hour'
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
            NavigationQuery: 'search in (AzureDiagnostics) ResourceType == "NETWORKSECURITYGROUPS" and Category == "NetworkSecurityGroupRuleCounter" and {selected item} | sort by TimeGenerated desc'
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
            title: 'Recommended Searches'
            newGroup: true
            preselectedFilters: 'Type, Computer'
            renderMode: 'grid'
            tabGroupId: '1528570627320'
          }
          queries: [
            {
              query: 'AzureDiagnostics | where ResourceType == "NETWORKSECURITYGROUPS" and Category == "NetworkSecurityGroupEvent" | sort by TimeGenerated desc'
              displayName: 'Azure Network Security Group Events'
            }
            {
              query: 'AzureDiagnostics | where ResourceType == "NETWORKSECURITYGROUPS" and Category == "NetworkSecurityGroupRuleCounter" | sort by TimeGenerated desc'
              displayName: 'Azure Network Security Group Counter Events'
            }
            {
              query: 'AzureDiagnostics | where ResourceType == "NETWORKSECURITYGROUPS" and Category == "NetworkSecurityGroupEvent" and ruleName_s !in ((union * | where Category == "NetworkSecurityGroupRuleCounter" and matchedConnections_d > 0 | distinct ruleName_s)) | summarize arg_max(TimeGenerated, *) by ruleName_s | sort by TimeGenerated desc | project TimeGenerated, ruleName_s, type_s, direction_s'
              displayName: 'Azure Network Security Group Rules Not Matching Any Flows'
            }
            {
              query: 'AzureDiagnostics | where ResourceType == "NETWORKSECURITYGROUPS" and Category == "NetworkSecurityGroupEvent" and ruleName_s in ((union * | where Category == "NetworkSecurityGroupRuleCounter" and matchedConnections_d > 0 | distinct ruleName_s)) | summarize arg_max(TimeGenerated, *) by ruleName_s | sort by TimeGenerated desc | project TimeGenerated, ruleName_s, type_s, direction_s'
              displayName: 'Azure Network Security Group Rules Matching Flows'
            }
          ]
        }
      }
    ]
    Filters: []
    OverviewTile: {
      Id: 'LineChartBuilderTile'
      Type: 'OverviewTile'
      Version: 2
      Configuration: {
        LineChart: {
          Query: 'AzureDiagnostics | where ResourceType == "NETWORKSECURITYGROUPS" and Category == "NetworkSecurityGroupRuleCounter" | summarize AggregatedValue = sum(matchedConnections_d) by type_s | where AggregatedValue > 0'
          yAxis: {
            isLogarithmic: false
            units: {
              baseUnitType: ''
              baseUnit: ''
              displayUnit: ''
            }
            customLabel: ''
          }
        }
        Advanced: {
          DataFlowVerification: {
            Enabled: true
            Query: 'AzureDiagnostics | where ResourceType == "NETWORKSECURITYGROUPS" | sort by TimeGenerated desc'
            Message: 'Learn how to configure solution: http://go.microsoft.com/fwlink/?linkid=839623'
            Diagnostics: {
              Query: ''
            }
          }
        }
      }
    }
  }
  dependsOn: [
    workspaceName_resource
  ]
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
    workspaceName_resource
    resourceId('Microsoft.OperationalInsights/workspaces/views', workspaceName, omsSolutions.customSolution.Name)
  ]
}