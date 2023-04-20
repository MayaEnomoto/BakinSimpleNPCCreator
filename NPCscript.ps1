.".\NpcCompletions.ps1"

# �J�����g�f�B���N�g���ɂ���e���v���[�g�t�@�C����CSV�t�@�C���̃p�X���w�肵�܂�
$currentDirectory = Get-Location
$auth_key_file_path = Join-Path $currentDirectory "auth_key.dat"

Add-Type -AssemblyName System.Windows.Forms

# �|�b�v�A�b�v��\������֐�
function ShowPopup($message) {
    [System.Windows.Forms.MessageBox]::Show($message)
}

# �t�@�C���ǂݍ��݃_�C�A���O��\������֐�
function OpenFileDialog($title, $filter) {
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = $title
    $openFileDialog.Filter = $filter

    $result = $openFileDialog.ShowDialog()
    if ($result -eq "OK") {
        return $openFileDialog.FileName
    } else {
        return $null
    }
}

# �^�X�N���b�Z�[�W��I������
ShowPopup("Select the task message file")
Write-Host "Select the task message file"
$taskmessageFilePath = OpenFileDialog "Select task message file" "Text Files (*.task)|*.task|All Files (*.*)|*.*"
if ($null -eq $taskmessageFilePath) {
    Write-Host "No task message file selected. Exiting..."
    exit
}

# �e���v���[�g�t�@�C����I������
ShowPopup("Select the template file")
Write-Host "Select the template file"
$templateFilePath = OpenFileDialog "Select the template file" "Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
if ($null -eq $templateFilePath) {
    Write-Host "No template file selected. Exiting..."
    exit
}

# CSV�t�@�C����I������
ShowPopup("Select the CSV file")
Write-Host "Select the CSV file"
$csvFilePath = OpenFileDialog "Select the CSV file" "CSV Files (*.csv)|*.csv|All Files (*.*)|*.*"
if ($null -eq $csvFilePath) {
    Write-Host "No CSV file selected. Exiting..."
    exit
}

# Auth_key��ǂݍ���
$auth_key = Get-Content $auth_key_file_path -Raw

# �^�X�N���b�Z�[�W��ǂݍ���
$task_message = Get-Content $taskmessageFilePath -Raw

# �e���v���[�g�t�@�C����ǂݍ���
$templateContent = Get-Content $templateFilePath -Raw -Encoding UTF8

# CSV�t�@�C����ǂݍ���
$csvContent = Get-Content $csvFilePath

# �^�E�������擾����
$town_name = ($csvContent[0] -split "\t")[1]
$town_information = ($csvContent[0] -split "\t")[1] + ":" + ($csvContent[0] -split "\t")[2]

# Townname�f�B���N�g�����쐬����
$townnameDirectoryPath = Join-Path $currentDirectory $town_name
if (-not (Test-Path $townnameDirectoryPath)) {
    New-Item -ItemType Directory -Path $townnameDirectoryPath
}

# CSV�t�@�C����2�s�ڂ���e�s����������
$csvContent | Select-Object -Skip 1 | ForEach-Object {
    $rowData = $_ -split "\t"

    # NpcCompletions�֐����Ăяo��
    Write-Host "Request GPT..."
    $npc_name = $rowData[1]
    $npc_information = $rowData[2]
    $responses = NpcCompletions -task_message $task_message -town_information $town_information -npc_name $npc_name -npc_information $npc_information -auth_key $auth_key

    # �u������
    $replacedContent = $templateContent
    for ($i = 0; $i -lt $responses.Count; $i++) {
        $responseWithEscapedNewlines = $responses[$i] -replace "`n", '\n'
        $responseWithEscapedNewlines = $responseWithEscapedNewlines -replace '\\n\\n', '\n'
        $replacedContent = $replacedContent -creplace [regex]::Escape("<<__SPEACH__[$($i)]>>"), $responseWithEscapedNewlines
    }

    Write-Host "Create script file..."
    # �u����̓��e��V�����t�@�C���ɕۑ�����
    $outputFilePath = Join-Path $townnameDirectoryPath "$($rowData[0]).txt"
    Set-Content -Path $outputFilePath -Value $replacedContent -Encoding UTF8 -NoNewline
}

Write-Host "All processes have been completed."
pause