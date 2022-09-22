function Get-AllAlertsWithDeletedResources {
    [CmdletBinding()]
    param(
    )
    Begin {
        [array]$allSubscriptions = Get-AzSubscription -WarningAction SilentlyContinue -Verbose
    }
    Process {
        foreach ($item in $allSubscriptions) {
            Select-AzSubscription $item -WarningAction SilentlyContinue | Set-AzContext | Out-Null
            Write-Verbose "Getting all MetricAlertRule from subscription: '$($item.Name)'"
            $rules = Get-AzMetricAlertRuleV2 -WarningAction SilentlyContinue -Verbose
            if ($rules) {
                [array]$allRules += @{
                    Name  = $item.Name
                    Id    = $item.Id
                    Rules = $rules
                }
            }
        }
        foreach ($item in $allRules) {
            Write-Verbose "Number of MetricAlertRule: '$(($item.Rules).Count)' in subscription: '$($item.Name)'"
            Select-AzSubscription $item.Id -WarningAction SilentlyContinue | Set-AzContext | Out-Null
            foreach ($rule in $item.Rules) {
                $deletedScopes = @()
                $scopeCount = ($rule.Scopes).Count
                foreach ($scope in $rule.Scopes) {
                    $testResource = Get-AzResource -ResourceId $scope -Verbose -WarningAction SilentlyContinue
                    if ($null -eq $testResource) {
                        [array]$deletedScopes += $scope
                    }
                }
                if ($deletedScopes) {
                    if(($deletedScopes.Count) -eq $scopeCount){
                        Write-Verbose "Found possible rule for deletion. Rule Id: '$($rule.Id)' Number of Scopes: '$scopeCount' Number of deleted resources: '$(($deletedScopes).Count)'"
                        [array]$rulesToRemove += @{
                            Id = $rule.Id
                            DeletedScopes = $deletedScopes
                            Delete = $true
                        }
                    } else {
                        [array]$rulesToRemove += @{
                            Id = $rule.Id
                            DeletedScopes = $deletedScopes
                        }
                    }
                }
            }
        }
    }
    End {
        return $rulesToRemove
    }
}

 

$rulesWithDeletedResources = Get-AllAlertsWithDeletedResources -Verbose