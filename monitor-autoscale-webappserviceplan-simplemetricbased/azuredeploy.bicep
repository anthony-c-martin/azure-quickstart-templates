@description('The name of the App Service plan.')
param svcPlanName string = 'SampleAppServicePlan'

@allowed([
  'Standard'
  'Premium'
])
@description('The pricing tier for the App Service plan.')
param sku string = 'Standard'

@description('The instance size of the app.')
param svcPlanSize string = 'S1'

@description('The minimum capacity.  Autoscale engine will ensure the instance count is at least this value.')
param minimumCapacity int = 2

@description('The maximum capacity.  Autoscale engine will ensure the instance count is not greater than this value.')
param maximumCapacity int = 5

@description('The default capacity.  Autoscale engine will preventively set the instance count to be this value if it can not find any metric data.')
param defaultCapacity int = 5

@description('The metric name.')
param metricName string = 'CpuPercentage'

@description('The metric upper threshold.  If the metric value is above this threshold then autoscale engine will initiate scale out action.')
param metricThresholdToScaleOut int = 60

@description('The metric lower threshold.  If the metric value is below this threshold then autoscale engine will initiate scale in action.')
param metricThresholdToScaleIn int = 20

@description('The percentage to increase the instance count when autoscale engine is initiating scale out action.')
param changePercentScaleOut int = 20

@description('The percentage to decrease the instance count when autoscale engine is initiating scale in action.')
param changePercentScaleIn int = 10

@description('A boolean to indicate whether the autoscale policy is enabled or disabled.')
param autoscaleEnabled bool

var settingName_var = '${toLower(svcPlanName)}-setting'
var targetResourceId = svcPlanName_resource.id

resource svcPlanName_resource 'Microsoft.Web/serverfarms@2015-08-01' = {
  name: svcPlanName
  location: resourceGroup().location
  sku: {
    name: svcPlanSize
    tier: sku
    capacity: 1
  }
}

resource settingName 'Microsoft.Insights/autoscalesettings@2014-04-01' = {
  name: settingName_var
  location: resourceGroup().location
  properties: {
    profiles: [
      {
        name: 'DefaultAutoscaleProfile'
        capacity: {
          minimum: minimumCapacity
          maximum: maximumCapacity
          default: defaultCapacity
        }
        rules: [
          {
            metricTrigger: {
              metricName: metricName
              metricNamespace: ''
              metricResourceUri: targetResourceId
              timeGrain: 'PT5M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: metricThresholdToScaleOut
            }
            scaleAction: {
              direction: 'Increase'
              type: 'PercentChangeCount'
              value: changePercentScaleOut
              cooldown: 'PT10M'
            }
          }
          {
            metricTrigger: {
              metricName: metricName
              metricNamespace: ''
              metricResourceUri: targetResourceId
              timeGrain: 'PT5M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: metricThresholdToScaleIn
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'PercentChangeCount'
              value: changePercentScaleIn
              cooldown: 'PT10M'
            }
          }
        ]
      }
    ]
    enabled: autoscaleEnabled
    targetResourceUri: targetResourceId
  }
}