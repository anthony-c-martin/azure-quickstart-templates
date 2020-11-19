param svcPlanName string {
  metadata: {
    description: 'The name of the App Service plan.'
  }
  default: 'SampleAppServicePlan'
}
param sku string {
  allowed: [
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'The pricing tier for the App Service plan.'
  }
  default: 'Standard'
}
param svcPlanSize string {
  metadata: {
    description: 'The instance size of the app.'
  }
  default: 'S1'
}
param minimumCapacity int {
  metadata: {
    description: 'The minimum capacity.  Autoscale engine will ensure the instance count is at least this value.'
  }
  default: 2
}
param maximumCapacity int {
  metadata: {
    description: 'The maximum capacity.  Autoscale engine will ensure the instance count is not greater than this value.'
  }
  default: 5
}
param defaultCapacity int {
  metadata: {
    description: 'The default capacity.  Autoscale engine will preventively set the instance count to be this value if it can not find any metric data.'
  }
  default: 5
}
param metricName string {
  metadata: {
    description: 'The metric name.'
  }
  default: 'CpuPercentage'
}
param metricThresholdToScaleOut int {
  metadata: {
    description: 'The metric upper threshold.  If the metric value is above this threshold then autoscale engine will initiate scale out action.'
  }
  default: 60
}
param metricThresholdToScaleIn int {
  metadata: {
    description: 'The metric lower threshold.  If the metric value is below this threshold then autoscale engine will initiate scale in action.'
  }
  default: 20
}
param changePercentScaleOut int {
  metadata: {
    description: 'The percentage to increase the instance count when autoscale engine is initiating scale out action.'
  }
  default: 20
}
param changePercentScaleIn int {
  metadata: {
    description: 'The percentage to decrease the instance count when autoscale engine is initiating scale in action.'
  }
  default: 10
}
param autoscaleEnabled bool {
  metadata: {
    description: 'A boolean to indicate whether the autoscale policy is enabled or disabled.'
  }
}

var settingName_var = '${toLower(svcPlanName)}-setting'
var targetResourceId = svcPlanName_res.id

resource svcPlanName_res 'Microsoft.Web/serverfarms@2015-08-01' = {
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