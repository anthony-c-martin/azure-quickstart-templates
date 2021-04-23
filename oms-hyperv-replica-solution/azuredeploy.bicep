@description('The name of your OMS Log Analytics workspace.')
param workspaceName string

@allowed([
  'East US'
  'West Europe'
  'Southeast Asia'
  'Australia Southeast'
  'West Central US'
])
@description('The region of your OMS Log Analytics workspace.')
param workspaceRegion string = 'West Europe'

@description('The name of the Automation account to use.  If this account exists, check the pricing tier and tags to make sure they match the exisitng account.')
param automationAccountName string

@allowed([
  'Japan East'
  'East US 2'
  'West Europe'
  'Southeast Asia'
  'South Central US'
  'UK South'
  'West Central US'
  'North Europe'
  'Canada Central'
  'Australia Southeast'
])
@description('The region the Automaiton account is located in.')
param automationRegion string = 'West Europe'

@allowed([
  'Free'
  'Basic'
])
@description('The pricing tier for the Automation account.')
param automationPricingTier string = 'Free'

@description('The username for the Account That Has Access To The On-Premises servers.')
param onPremisesRunAsUserName string

@description('The password for the Account That Has Access To The On-Premises servers.')
@secure()
param onPremisesRunAsPassword string

@description('The Work Space ID for your OMS workspace.')
param workSpaceID string

@description('The Work Space Primary Key for your OMS workspace.')
@secure()
param workSpacePrimaryKey string

@description('The base URI where artifacts required by this template are located.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/oms-hyperv-replica-solution/'

@description('The sasToken required to access _artifactsLocation.')
@secure()
param artifactsSasToken string = ''

var automation = {
  Asset: {
    omsHypervReplicaRunNumber: {
      name: 'omsHypervReplicaRunNumber'
      type: 'int'
      value: '1'
      description: 'This variable keeps track of the Hyper-V run number.'
    }
    omsHypervReplicaRunAsAccount: {
      name: 'omsHypervReplicaRunAsAccount'
      description: 'This runbook publishes Hyper-V replica statistics to OMS.'
    }
  }
  runbook: {
    publishOmsHyperVReplica: {
      name: 'Publish-omsHyperVReplica'
      type: 'Script'
      description: 'This runbook publishes Hyper-V replica statistics to OMS.'
    }
  }
  module: {
    OMSDataInjection: {
      name: 'OMSDataInjection'
      description: 'This runbook publishes Hyper-V replica statistics to OMS.'
    }
  }
  connection: {
    OMSDataInjection: {
      name: 'omsHypervReplicaOMSConnection'
      description: 'This connection stores the details for the Hybrid Runbook workers to inject the data into OMS.'
      type: 'OMSWorkSpace'
    }
  }
}
var solution = {
  Name: 'hypervReplica [${workspaceName}]'
  DisplayName: 'Hyper-V Replica Monitoring'
  Version: '1.0.0.0'
  Publisher: 'bentaylor.work'
  Product: 'bentaylorworkHypervReplica'
  PromotionCode: ''
  Description: 'Hyper-V Replication Monitoring Through OMS'
  Author: 'ben@bentaylor.work'
}

resource workspaceName_resource 'Microsoft.OperationalInsights/workspaces@2015-11-01-preview' = {
  name: workspaceName
  location: workspaceRegion
}

resource workspaceName_solution_Name 'Microsoft.OperationalInsights/workspaces/views@2015-11-01-preview' = {
  parent: workspaceName_resource
  name: '${solution.Name}'
  location: workspaceRegion
  properties: {
    Id: solution.Name
    Name: solution.Name
    Author: solution.Author
    DisplayName: solution.DisplayName
    Description: solution.Description
    Source: 'Local'
    Dashboard: [
      {
        Id: 'SingleQueryDonutBuilderBladeV1'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Current Hyper-V Replica Results By Status'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Number At Each Status'
            Subtitle: ''
          }
          Donut: {
            Query: 'Type=hyperVReplica_CL runNumber_d IN { Type=hyperVReplica_CL | measure max(runNumber_d) by runNumber_d | sort runNumber_d DESC | top 1 } | measure count() by state_s'
            CenterLegend: {
              Text: 'Total'
              Operation: 'Sum'
              ArcsToSelect: []
            }
            Options: {
              colors: [
                '#00188f'
                '#0072c6'
                '#00bcf2'
              ]
              valueColorMapping: []
            }
          }
          List: {
            Query: 'Type=hyperVReplica_CL runNumber_d IN { Type=hyperVReplica_CL | measure max(runNumber_d) by runNumber_d | sort runNumber_d DESC | top 1 } | measure count() by state_s'
            HideGraph: true
            enableSparklines: false
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'Replica Status'
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
                  threshold: '5'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '10'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: '{selected item}'
          }
        }
      }
      {
        Id: 'NumberTileListBuilderBlade'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Current Failed Hyper-V Replicas By Computer'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Tile: {
            Query: 'Type=hyperVReplica_CL NOT(state_s:"Replicating") runNumber_d IN { Type=hyperVReplica_CL | measure max(runNumber_d) by runNumber_d | sort runNumber_d DESC | top 1 }'
            Legend: 'Number Of VMs With Broken Replication'
          }
          List: {
            Query: 'Type=hyperVReplica_CL NOT(state_s:"Replicating") runNumber_d IN { Type=hyperVReplica_CL | measure max(runNumber_d) by runNumber_d | sort runNumber_d DESC | top 1 } | Measure count() by primaryServer_s'
            HideGraph: false
            enableSparklines: false
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'Computer'
              Value: 'Count Of Broken Replicas'
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
                  threshold: '0'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '2'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: '{selected item}'
          }
        }
      }
      {
        Id: 'LineChartBuilderBlade'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Hyper-V Replica - Replication Size'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Average Replica Size'
            Subtitle: ''
          }
          LineChart: {
            Query: 'Type=hyperVReplica_CL  | EXTEND div(AverageReplicationSize_d,1048576 ) AS AverageReplicationSize_MB | measure avg(AverageReplicationSize_MB) Interval 1HOUR'
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
          List: {
            Query: 'Type=hyperVReplica_CL state_s:"Replicating" | EXTEND div(AverageReplicationSize_d,1048576 ) AS AverageReplicationSize_MB | measure avg(AverageReplicationSize_MB) by name_s'
            HideGraph: false
            enableSparklines: false
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'VM Name'
              Value: 'AVG Replica Size'
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
                  threshold: '30'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '50'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: '{selected item}'
          }
        }
      }
      {
        Id: 'NumberTileListBuilderBlade'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Computers Actively Being Monitored'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Tile: {
            Legend: ''
            Query: 'Type=hyperVReplica_CL runNumber_d IN { Type=hyperVReplica_CL | measure max(runNumber_d) by runNumber_d | sort runNumber_d DESC | top 1 } | Dedup primaryServer_s | Select primaryServer_s'
          }
          List: {
            Query: 'Type=hyperVReplica_CL runNumber_d IN { Type=hyperVReplica_CL | measure max(runNumber_d) by runNumber_d | sort runNumber_d DESC | top 1 } | Dedup primaryServer_s | Select primaryServer_s'
            HideGraph: false
            enableSparklines: false
            ColumnsTitle: {
              Name: 'Computer'
              Value: ''
            }
            Color: '#0072c6'
            operation: 'Summary'
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
            NavigationQuery: '{selected item}'
          }
        }
      }
      {
        Id: 'NotableQueriesBuilderBlade'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'List of queries'
            newGroup: false
            preselectedFilters: 'Type, Computer'
            renderMode: 'grid'
          }
          queries: [
            {
              query: 'Type=hyperVReplica_CL runNumber_d IN { Type=hyperVReplica_CL | measure max(runNumber_d) by runNumber_d | sort runNumber_d DESC | top 1 } | measure count() by state_s'
              displayName: 'Number At Each Status'
            }
            {
              query: 'Type=hyperVReplica_CL runNumber_d IN { Type=hyperVReplica_CL | measure max(runNumber_d) by runNumber_d | sort runNumber_d DESC | top 1 }'
              displayName: 'Latest Hyper-V Replica Information'
            }
            {
              query: 'Type=hyperVReplica_CL'
              displayName: 'All Hyper-V Replica Data'
            }
            {
              query: 'Type=hyperVReplica_CL NOT(state_s:"Replicating") runNumber_d IN { Type=hyperVReplica_CL | measure max(runNumber_d) by runNumber_d | sort runNumber_d DESC | top 1 } | Measure count() by primaryServer_s'
              displayName: 'Current Broken Replicas By Server'
            }
            {
              query: 'Type=hyperVReplica_CL state_s="Replicating" runNumber_d IN { Type=hyperVReplica_CL | measure max(runNumber_d) by runNumber_d | sort runNumber_d DESC | top 1 } | Measure count() by primaryServer_s'
              displayName: 'Current Successful Replicas By Server'
            }
            {
              query: 'Type=hyperVReplica_CL LastReplicationTime_t<NOW-24HOURS runNumber_d IN { Type=hyperVReplica_CL | measure max(runNumber_d) by runNumber_d | sort runNumber_d DESC | top 1 } | Select name_s, LastReplicationTime_t | Sort LastReplicationTime_t asc'
              displayName: 'Last Time VM Successfully Replicated (Older Than 24 Hours)'
            }
            {
              query: 'Type=hyperVReplica_CL runNumber_d IN { Type=hyperVReplica_CL | measure max(runNumber_d) by runNumber_d | sort runNumber_d DESC | top 1 } | Dedup primaryServer_s | Select primaryServer_s'
              displayName: 'Computers Being Actively Monitored'
            }
            {
              query: 'Type=hyperVReplica_CL  | EXTEND div(AverageReplicationSize_d,1048576 ) AS AverageReplicationSize_MB | measure avg(AverageReplicationSize_MB) Interval 1HOUR'
              displayName: 'Average Replication Size'
            }
            {
              query: 'Type=hyperVReplica_CL state_s:"Replicating" | EXTEND div(AverageReplicationSize_d,1048576 ) AS AverageReplicationSize_MB | measure avg(AverageReplicationSize_MB) by name_s'
              displayName: 'Average Replication Size by VM'
            }
          ]
        }
      }
      {
        Id: 'InformationBlade'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            Title: ''
            NewGroup: false
            Color: '#0072c6'
          }
          Header: {
            Image: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAztJREFUeNrUmktoE1EUhqexKj4zJWoaqIpVaVGxKr6ogsaNbhS0YKkKFeKmriwFEaXYnY+FYjeCbmtRRBeuXIlLMe1CXGlduBOt0rS1FaF2/A+ciWMy0yT3njvN/PBtMuHc8899zJ1zp8ZxHEtAKXAE7AdNYBOwGVKO+QQ+gDfgFfii23CNhoHV4CyzWzHGEBgEA2BUKQIZqJAG0A+mHTn9AvfB2krzqeTPi8AVMOWYE92UPrBY2kAzeOeEp/fcZsncYmWMsjaQBdut8LSN22zTnQMXwYwzf5rhHJSGUJdTPeoKyjNoGT0JnoIFCt1/GXwOuNYIbirE/APawbNyhlATmNS4W4fm6NW0Rlxa/baWmsQLwROwXGMC2orXSmkpeMw55lVooAe0aK4gcUMG3NWpJ8hAA+gVWAJtRXPlqpdzLTJwlbvJpAFbID7leK3QwCpwXughFDdsgNTJOecN0A9LhIKbHkIW59rpNdAhuA2wQ+gB0hnXQBLsiqCBnaCeDKTpxUYwcDwkA5TzYTLQKryTDGMOuDoQ44eDFcEhRNpCBtYJB42HaGC9O4klVRuwl1opPNdIa2KaG7dK7nSdgXZWxCwzskOYwPmtxISBuPEQxj9pnAx8NRC4LiQDo2RgJMI98DHGtUpppbgXvNSbMEAv9af5NTKKaicDtK/+ZmCNNi0qpyRpCH3nKnHUNOROYtIj4eDTXP9JMzfAlHAbg966UEKwXE71m70+NSH67bdgFTvhrQv9AA+E7sw98Nbnd/rtjlAbDznn/ypzKc2KnKuDc1TmWgXiT3KuRZU5Oq+6LrQ6BGlWIH6f5TlbK9zM9YNhzQaOKV4rR8M8RD23q7ibG0FOo4snwA6fuC18TVWU08Zyy+snwHNLrbxu8ZJ5F7zkIXUUdNP+XTEelddPgRfFAzZ4wmXAbBUcblAOF1QP+TJVcMSU0T2lPA7G5iH5HLctcsy6AWRDTD7LbYoedNeCS2DcYOK0SnVzW+In9S5JcEtzSfRL/DbHrigfnY896C2LPvQ4B/b4PBRLiZ7KdJg9wLvhMaUCqdDnNgkqtIJ9oBlspqITWMYvSj/5pWnE+ve5zev8hkxDfwUYAP0NkvYTPlJVAAAAAElFTkSuQmCC'
            Label: 'Hyper-V Replica'
            Link: {
              Label: 'More info'
              Url: 'https://www.bentaylor.work'
            }
          }
          List: [
            {
              Title: 'Solution Overview'
              Content: 'This solution helps you manage Hyper-V replica. It give you visibility of the current replication state. It only shows data from the primary replica host.\n\n#### Components\n* Azure Automation\n* OMS Custom View\n\n#### Contributors\n* Ben Taylor - www.bentaylor.work'
            }
          ]
        }
      }
    ]
    OverviewTile: {
      Id: 'SingleQueryDonutBuilderTileV1'
      Type: 'OverviewTile'
      Version: 0
      Configuration: {
        Donut: {
          Query: 'Type=hyperVReplica_CL runNumber_d IN { Type=hyperVReplica_CL | measure max(runNumber_d) by runNumber_d | sort runNumber_d DESC | top 1 } | measure count() by state_s'
          CenterLegend: {
            Text: 'Total'
            Operation: 'Sum'
            ArcsToSelect: []
          }
          Options: {
            colors: [
              '#00188f'
              '#0072c6'
              '#00bcf2'
            ]
            valueColorMapping: []
          }
        }
        Advanced: {
          DataFlowVerification: {
            Enabled: true
            Query: 'Type=hyperVReplica_CL'
            Message: 'Please check the runbook that injests the Hyper-V replica data for errors.'
          }
        }
      }
    }
  }
}

resource automationAccountName_resource 'Microsoft.Automation/automationAccounts@2015-10-31' = {
  name: automationAccountName
  location: automationRegion
  tags: {}
  properties: {
    sku: {
      name: automationPricingTier
    }
  }
  dependsOn: []
}

resource automationAccountName_automation_runbook_publishOmsHyperVReplica_name 'Microsoft.Automation/automationAccounts/runbooks@2015-10-31' = {
  parent: automationAccountName_resource
  name: '${automation.runbook.publishOmsHyperVReplica.name}'
  location: automationRegion
  tags: {}
  properties: {
    runbookType: automation.runbook.publishOmsHyperVReplica.type
    logProgress: false
    logVerbose: false
    description: automation.runbook.publishOmsHyperVReplica.description
    publishContentLink: {
      uri: '${artifactsLocation}scripts/${automation.runbook.publishOmsHyperVReplica.name}.ps1${artifactsSasToken}'
      version: '1.0.0.0'
    }
  }
}

resource automationAccountName_automation_Asset_omsHypervReplicaRunNumber_name 'microsoft.automation/automationAccounts/variables@2015-10-31' = {
  parent: automationAccountName_resource
  name: '${automation.Asset.omsHypervReplicaRunNumber.name}'
  location: automationRegion
  tags: {}
  properties: {
    description: automation.Asset.omsHypervReplicaRunNumber.description
    isEncrypted: false
    type: automation.Asset.omsHypervReplicaRunNumber.type
    value: automation.Asset.omsHypervReplicaRunNumber.value
  }
}

resource automationAccountName_automation_Asset_omsHypervReplicaRunAsAccount_name 'microsoft.automation/automationAccounts/credentials@2015-10-31' = {
  parent: automationAccountName_resource
  name: '${automation.Asset.omsHypervReplicaRunAsAccount.name}'
  location: automationRegion
  tags: {}
  properties: {
    userName: onPremisesRunAsUserName
    password: onPremisesRunAsPassword
    description: automation.Asset.omsHypervReplicaRunAsAccount.description
  }
}

resource automationAccountName_automation_module_OMSDataInjection_name 'microsoft.automation/automationAccounts/modules@2015-10-31' = {
  parent: automationAccountName_resource
  name: '${automation.module.OMSDataInjection.name}'
  location: automationRegion
  tags: {}
  properties: {
    contentLink: {
      uri: '${artifactsLocation}assets/${automation.module.OMSDataInjection.name}.zip${artifactsSasToken}'
    }
  }
}

resource automationAccountName_automation_connection_OMSDataInjection_name 'microsoft.automation/automationAccounts/connections@2015-10-31' = {
  parent: automationAccountName_resource
  name: '${automation.connection.OMSDataInjection.name}'
  location: automationRegion
  tags: {}
  properties: {
    name: automation.connection.OMSDataInjection.name
    description: automation.connection.OMSDataInjection.description
    isGlobal: false
    connectionType: {
      name: automation.connection.OMSDataInjection.type
    }
    fieldDefinitionValues: {
      OMSWorkspaceId: workSpaceID
      PrimaryKey: workSpacePrimaryKey
    }
  }
  dependsOn: [
    automationAccountName_automation_module_OMSDataInjection_name
  ]
}

resource solution_Name 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: solution.Name
  location: workspaceRegion
  tags: {}
  plan: {
    name: solution.Name
    publisher: solution.Publisher
    promotionCode: solution.PromotionCode
    product: solution.Product
  }
  properties: {
    workspaceResourceId: workspaceName_resource.id
    referencedResources: [
      automationAccountName_resource.id
      automationAccountName_automation_module_OMSDataInjection_name.id
    ]
    containedResources: [
      automationAccountName_automation_runbook_publishOmsHyperVReplica_name.id
      automationAccountName_automation_Asset_omsHypervReplicaRunAsAccount_name.id
      automationAccountName_automation_Asset_omsHypervReplicaRunNumber_name.id
      automationAccountName_automation_connection_OMSDataInjection_name.id
      workspaceName_solution_Name.id
    ]
  }
}