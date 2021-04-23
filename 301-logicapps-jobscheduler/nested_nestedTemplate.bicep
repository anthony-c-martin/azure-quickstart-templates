param resourceId_Microsoft_Logic_workflows_parameters_CreateTimerJobLogicAppName string

@minLength(1)
@description('The name of the logic app that runs timer jobs.')
param TimerJobLogicAppName string

@description('Location for all resources.')
param location string

resource TimerJobLogicAppName_resource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: TimerJobLogicAppName
  location: location
  tags: {
    displayName: 'LogicApp'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      triggers: {
        manual: {
          correlation: {
            clientTrackingId: '@triggerBody()[\'timerjobid\']'
          }
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              properties: {
                jobRecurrence: {
                  properties: {
                    count: {
                      minimum: -1
                      title: 'count (jobRecurrence)'
                      type: 'integer'
                    }
                    endTime: {
                      title: 'endTime (jobRecurrence)'
                      type: 'string'
                    }
                    frequency: {
                      enum: [
                        'second'
                        'minute'
                        'hour'
                        'day'
                        'week'
                        'month'
                      ]
                      title: 'frequency (jobRecurrence)'
                      type: 'string'
                    }
                    interval: {
                      title: 'interval (jobRecurrence)'
                      type: 'integer'
                    }
                  }
                  required: [
                    'frequency'
                    'interval'
                  ]
                  type: 'object'
                }
                jobStatus: {
                  properties: {
                    executionCount: {
                      title: 'executionCount (jobStatus)'
                      type: 'integer'
                    }
                    faultedCount: {
                      title: 'faultedCount (jobStatus)'
                      type: 'integer'
                    }
                    lastExecutionTime: {
                      title: 'lastExecutionTime (jobStatus)'
                      type: 'string'
                    }
                    nextExecutionTime: {
                      title: 'nextExecutionTime (jobStatus)'
                      type: 'string'
                    }
                  }
                  required: [
                    'nextExecutionTime'
                  ]
                  type: 'object'
                }
                startTime: {
                  type: 'string'
                }
                timerjobid: {
                  type: 'string'
                }
              }
              required: [
                'timerjobid'
                'jobRecurrence'
                'jobStatus'
              ]
              type: 'object'
            }
          }
        }
      }
      actions: {
        CreateTimerJob: {
          runAfter: {
            On_Error: [
              'Succeeded'
              'Skipped'
              'Failed'
              'TimedOut'
            ]
          }
          type: 'Workflow'
          inputs: {
            body: {
              jobRecurrence: {
                count: '@triggerBody()?[\'jobRecurrence\']?[\'count\']'
                endTime: '@triggerBody()?[\'jobRecurrence\']?[\'endTime\']'
                frequency: '@triggerBody()[\'jobRecurrence\'][\'frequency\']'
                interval: '@triggerBody()[\'jobRecurrence\'][\'interval\']'
              }
              jobStatus: {
                executionCount: '@add(1,coalesce(triggerBody()?[\'jobStatus\']?[\'executionCount\'],0))'
                faultedCount: '@variables(\'faultedCount\')'
                lastExecutionTime: '@triggerBody()?[\'jobStatus\']?[\'nextExecutionTime\']'
              }
              startTime: '@triggerBody()?[\'startTime\']'
              timerjobid: '@triggerBody()[\'timerjobid\']'
            }
            host: {
              triggerName: 'manual'
              workflow: {
                id: resourceId_Microsoft_Logic_workflows_parameters_CreateTimerJobLogicAppName
              }
            }
          }
        }
        Delay_until_nextExecutionTime: {
          runAfter: {
            Response: [
              'Succeeded'
            ]
          }
          type: 'Wait'
          inputs: {
            until: {
              timestamp: '@triggerBody()?[\'jobStatus\']?[\'nextExecutionTime\']'
            }
          }
        }
        If_CreateTimerJob_failed_and_no_next_recurrence: {
          runAfter: {
            CreateTimerJob: [
              'Failed'
            ]
          }
          else: {
            actions: {
              Create_next_job_error_failed: {
                type: 'Terminate'
                inputs: {
                  runError: {
                    message: 'Failed to create the next timer job'
                  }
                  runStatus: 'Failed'
                }
              }
            }
          }
          expression: {
            and: [
              {
                equals: [
                  '@actionOutputs(\'CreateTimerJob\')[\'statusCode\']'
                  409
                ]
              }
            ]
          }
          type: 'If'
          description: 'If CreateTimerJob fails with a 409 (conflict) then recurrence completion criteria is met'
        }
        Increment_faultedCount: {
          runAfter: {
            Job: [
              'Failed'
              'TimedOut'
            ]
          }
          type: 'IncrementVariable'
          inputs: {
            name: 'faultedCount'
            value: 1
          }
        }
        Initialize_faultedCount: {
          runAfter: {
            Delay_until_nextExecutionTime: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'faultedCount'
                type: 'Integer'
                value: '@triggerBody()?[\'jobStatus\']?[\'faultedCount\']'
              }
            ]
          }
        }
        Job: {
          actions: {
            HTTP: {
              type: 'Http'
              inputs: {
                method: 'GET'
                uri: 'https://api.chucknorris.io/jokes/random?category=dev'
              }
            }
          }
          runAfter: {
            Initialize_faultedCount: [
              'Succeeded'
            ]
          }
          type: 'Scope'
          description: 'Executes the set of actions defined for the timer job'
        }
        On_Error: {
          runAfter: {
            Increment_faultedCount: [
              'Succeeded'
            ]
          }
          type: 'Scope'
          description: 'Executes the set of actions if main job actions has fails to execute'
        }
        Response: {
          type: 'Response'
          kind: 'Http'
          inputs: {
            body: {
              jobid: '@workflow().run.name'
            }
            schema: {
              properties: {
                jobid: {
                  type: 'string'
                }
              }
              type: 'object'
            }
            statusCode: 200
          }
        }
      }
    }
  }
}