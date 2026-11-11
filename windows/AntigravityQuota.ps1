# Antigravity Quota Monitor - Windows WPF GUI
# Cross-platform popup for Antigravity AI Model Quotas

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CoreEngine = Join-Path (Split-Path -Parent $ScriptDir) "core\quota_engine.js"
$CacheFile = Join-Path $env:TEMP "antigravity_quota_cache.json"

function Get-QuotaData([switch]$Force) {
    if (-not $Force -and (Test-Path $CacheFile)) {
        try {
            $cached = Get-Content $CacheFile -Raw | ConvertFrom-Json
            $elapsed = ((Get-Date) - [datetime]$cached.timestamp_dt).TotalSeconds
            if ($elapsed -lt 60) {
                return $cached
            }
        } catch {}
    }

    try {
        $json = & node $CoreEngine 2>$null
        if ($LASTEXITCODE -eq 0 -and $json) {
            $data = $json | ConvertFrom-Json
            $data | Add-Member -NotePropertyName "timestamp_dt" -NotePropertyValue (Get-Date).ToString("o") -Force
            $data | ConvertTo-Json -Depth 10 | Set-Content $CacheFile
            return $data
        }
    } catch {}

    if (Test-Path $CacheFile) {
        return (Get-Content $CacheFile -Raw | ConvertFrom-Json)
    }
    return $null
}

function Show-QuotaWindow([switch]$Force) {
    $quota = Get-QuotaData -Force:$Force
    if (-not $quota) {
        [System.Windows.MessageBox]::Show("Não foi possível obter dados da cota do Antigravity. Verifique se o Antigravity está aberto.", "Antigravity Quota", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Antigravity Model Quota" Width="460" SizeToContent="Height"
        WindowStartupLocation="CenterScreen" WindowStyle="SingleBorderWindow"
        ResizeMode="NoResize" Background="#1E1E24" Foreground="#FFFFFF"
        Topmost="True">
    <Window.Resources>
        <Style TargetType="TextBlock">
            <Setter Property="FontFamily" Value="Segoe UI, -apple-system, sans-serif"/>
        </Style>
    </Window.Resources>
    <Grid Margin="20,16,20,18">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Subtitle Info (Monochrome, no colored emojis) -->
        <StackPanel Grid.Row="0" Margin="0,0,0,16">
            <TextBlock Text="$($quota.account) • Plano $($quota.plan)" FontSize="13" FontWeight="SemiBold" Foreground="#E0E0E0"/>
            <TextBlock Text="Atualizado às $($quota.updated_at) • Cache 60s" FontSize="11" Foreground="#9E9EA8" Margin="0,3,0,0"/>
        </StackPanel>

        <!-- Groups Container -->
        <StackPanel x:Name="GroupsPanel" Grid.Row="2"/>

        <!-- Footer Buttons (Monochrome clean buttons) -->
        <Grid Grid.Row="3" Margin="0,18,0,0">
            <Button x:Name="BtnRefresh" Content="Atualizar" Width="85" Height="30" HorizontalAlignment="Left"
                    Background="#2A2A35" Foreground="#E0E0E0" BorderBrush="#3D3D4E" Cursor="Hand"/>
            <Button x:Name="BtnClose" Content="Fechar" Width="85" Height="30" HorizontalAlignment="Right"
                    Background="#2A2A35" Foreground="#FFFFFF" BorderBrush="#3D3D4E" IsCancel="True" Cursor="Hand"/>
        </Grid>
    </Grid>
</Window>
"@

    $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
    $window = [System.Windows.Markup.XamlReader]::Load($reader)

    $groupsPanel = $window.FindName("GroupsPanel")
    $btnRefresh = $window.FindName("BtnRefresh")
    $btnClose = $window.FindName("BtnClose")

    $btnClose.add_Click({ $window.Close() })
    $btnRefresh.add_Click({
        $window.Close()
        Show-QuotaWindow -Force
    })

    foreach ($g in $quota.groups) {
        $gHeader = [System.Windows.Controls.TextBlock]::new()
        $gHeader.Text = $g.name.ToUpper()
        $gHeader.FontSize = 10
        $gHeader.FontWeight = [System.Windows.FontWeights]::Bold
        $gHeader.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A1A1AA")
        $gHeader.Margin = [System.Windows.Thickness]::new(0, 10, 0, 4)
        $groupsPanel.Children.Add($gHeader) | Out-Null

        $card = [System.Windows.Controls.Border]::new()
        $card.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#282830")
        $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#383844")
        $card.BorderThickness = [System.Windows.Thickness]::new(1)
        $card.CornerRadius = [System.Windows.CornerRadius]::new(8)
        $card.Padding = [System.Windows.Thickness]::new(14, 10, 14, 12)
        $card.Margin = [System.Windows.Thickness]::new(0, 0, 0, 6)

        $cardStack = [System.Windows.Controls.StackPanel]::new()
        $card.Child = $cardStack

        $bIdx = 0
        foreach ($b in $g.buckets) {
            if ($bIdx -gt 0) {
                $sep = [System.Windows.Controls.Separator]::new()
                $sep.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#383844")
                $sep.Margin = [System.Windows.Thickness]::new(0, 8, 0, 8)
                $cardStack.Children.Add($sep) | Out-Null
            }

            $row = [System.Windows.Controls.Grid]::new()
            $col1 = [System.Windows.Controls.ColumnDefinition]::new()
            $col2 = [System.Windows.Controls.ColumnDefinition]::new()
            $col2.Width = [System.Windows.GridLength]::Auto
            $row.ColumnDefinitions.Add($col1)
            $row.ColumnDefinitions.Add($col2)

            $bName = [System.Windows.Controls.TextBlock]::new()
            $bName.Text = $b.name
            $bName.FontSize = 12
            $bName.Foreground = [System.Windows.Media.Brushes]::White
            [System.Windows.Controls.Grid]::SetColumn($bName, 0)
            $row.Children.Add($bName) | Out-Null

            $resetStr = if ($b.reset_in) { " • $($b.reset_in)" } else { "" }
            $bVal = [System.Windows.Controls.TextBlock]::new()
            $bVal.Text = "$($b.remaining_pct)%$resetStr"
            $bVal.FontSize = 12
            $bVal.FontWeight = [System.Windows.FontWeights]::SemiBold

            $colorHex = "#34C759"
            if ($b.remaining_pct -le 20) { $colorHex = "#FF3B30" }
            elseif ($b.remaining_pct -le 50) { $colorHex = "#FF9500" }

            $bVal.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($colorHex)
            [System.Windows.Controls.Grid]::SetColumn($bVal, 1)
            $row.Children.Add($bVal) | Out-Null
            $cardStack.Children.Add($row) | Out-Null

            # Progress Bar
            $pBar = [System.Windows.Controls.ProgressBar]::new()
            $pBar.Height = 6
            $pBar.Minimum = 0
            $pBar.Maximum = 100
            $pBar.Value = $b.remaining_pct
            $pBar.Margin = [System.Windows.Thickness]::new(0, 6, 0, 2)
            $pBar.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3A3A46")
            $pBar.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($colorHex)
            $pBar.BorderThickness = [System.Windows.Thickness]::new(0)
            $cardStack.Children.Add($pBar) | Out-Null

            $bIdx++
        }

        $groupsPanel.Children.Add($card) | Out-Null
    }

    $window.ShowDialog() | Out-Null
}

Show-QuotaWindow
