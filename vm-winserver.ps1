# Login to Azure
Connect-AzAccount

# Parameters
$rg = 'rg-vmwin'
$local = 'brazilsouth'

# Parameters for VM
$vm = 'vm-win'
$sku = 'Standard_E2s_v3'
$img = 'Win2019Datacenter'
$ip = 'ip-vm'
$nsg = 'nsg-vm'

# Parameters - Credentials
$user = 'adminuser'
$pass = ConvertTo-SecureString '@BAHia011931' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass);

#Criar Resource Group
New-AzResourceGroup -Name $rg -Location $local

# Criar Maquina Virtual
New-AzVM -Name $vm -ResourceGroupName $rg -Location $local -Credential $cred -Image $img -Size $sku -PublicIpAddressName $ip

# Selecionar NSG Criado na VM
$nsg = Get-AzNetworkSecurityGroup -Name $vm -ResourceGroupName $rg

# Liberar Porta 80
$Params = @{
    'Name' = 'allowHTTP'
    'NetworkSecurityGroup' = $nsg
    'Protocol' = 'TCP'
    'Direction' = 'Inbound'
    'Priority' = 100
    'SourceAddressPrefix' = 'Internet'
    'SourcePortRange' = '*'
    'DestinationAddressPrefix' = '*'
    'DestinationPortRange' = '80'
    'Access' = 'Allow'
}

#Adicionar Regra ao NSG
Add-AzNetworkSecurityRuleConfig @Params | Set-AzNetworkSecurityGroup

# Instalar IIS
Invoke-AzVMRunCommand -ResourceGroupName $rg -VMName $vm -CommandId 'RunPowerShellScript' -ScriptString 'Install-WindowsFeature -Name Web-Server -IncludeManagementTools'

# Listar IP
Get-AzPublicIpAddress -ResourceGroupName $rg -Name $ip | Select IpAddress

# Acessar a URL
curl= 4.201.152.32


# Alterar HTML no IIS Web Server
Set-AzVMExtension -ResourceGroupName $rg -ExtensionName "IIS" -VMName $vm -Location $local -Publisher Microsoft.Compute `
  -ExtensionType CustomScriptExtension -TypeHandlerVersion 1.8 `
  -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $(env:computername)"}'
