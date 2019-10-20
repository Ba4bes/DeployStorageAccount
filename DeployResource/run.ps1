using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$AzContext = Get-AzContext -ErrorAction SilentlyContinue
if (-not $AzContext.Subscription.Id) {
    Throw ("Managed identity is not enabled for this app or it has not been granted access to any Azure resources. Please see https://docs.microsoft.com/en-us/azure/app-service/overview-managed-identity for additional details.")
}

$Prefix = $request.Query.Prefix
if ([string]::IsNullOrEmpty($Prefix)){
    $Prefix = "FA"
}
$random= (Get-Random).ToString()
$Parameters = @{
    "storageAccountPrefix" = $Prefix
}

$Template = "$PWD\DeployResource\Azuredeploy.json"
$ResourceGroupName = "$Prefix$Random"
New-AzResourceGroup -Name  $ResourceGroupName -Location 'West Europe'
$DeploymentParameters = @{
    Name ="Function$Random"
    ResourceGroupName = $ResourceGroupName
    TemplateFile = $Template
    TemplateParameterObject = $Parameters
}
$Deployment = New-AzResourceGroupDeployment @DeploymentParameters -Verbose

$Body = "Your new StorageAccount is $($Deployment.Outputs.storageAccount.Value)"
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value (@{
    StatusCode  = "ok"
    ContentType = "text/html"
    Body        = $Body
})
