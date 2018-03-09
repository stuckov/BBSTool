#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\..\icon.ico
#AutoIt3Wrapper_Outfile=BBSTool.exe
#AutoIt3Wrapper_Res_Comment=Flash Tool for battery check, bios update and shipping mode: For use in production. Only for MEDION confirmed projects.
#AutoIt3Wrapper_Res_Description=MEDION AG
#AutoIt3Wrapper_Res_Fileversion=3.0.0.38
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=p
#AutoIt3Wrapper_Res_LegalCopyright=SiT Medion AG
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.1
 Author:         SiT

 Script Function:
	Checks battery with gui and writes to log,
	Checks BIOS version,
	flashes BIOS,
	set Shippingmode

 How To:
	Customize your settings in variable block below.
	Compile as executeable and change files.
	All files have to be in root of usb stick.

#ce ----------------------------------------------------------------------------

; Costomize for each project: --------------------------------------------------
; parts which are "null" dont get executed --------------------------------------

global $shippingMode =  IniRead(@scriptdir & "BIOS.ini","shippingMode","shippingMode",null) 	
Global $shippingModeParameter = IniRead(@scriptdir & "BIOS.ini","shippingMode","shippingModeparameter"," /ShipUEFIOS")		

; Change command for BIOS flash. can be path to flash.bat too.
global $biosCommand = IniRead(@scriptdir & "BIOS.ini","Bios","flash",Null)

; Change bios version for each Project
global $biosVersion =IniRead(@scriptdir & "Bios.ini","Bios","version",null)

; Additional BIOS string

global $biosCaption = null	

; customice end ----------------------------------------------------------------
#include <MsgBoxConstants.au3>
#include <GUIConstantsEx.au3>
#include <WinAPISys.au3>
#include <WindowsConstants.au3>
#include <ColorConstants.au3>
#Include <WinAPI.au3>
#include <GuiListView.au3>
#include <Array.au3>

global $suchName = FileFindFirstFile("*-Rework_Logfile.log")
global $timeStamp = @MDAY&"."&@MON&"-"&@HOUR&"."&@MIN&"."&@SEC
global $logName = "\" &$timeStamp& "-Rework_Logfile.log"
global $trans
global $sModel
global $sSku
global $Output
global $Output2
global $transLog2
global $transLog
global $calcPercentCapacityRounded
global $CurrentCapacity
global $ACstatus 
global $chargerate
global $runTime = TimerInit()


local  $objWMIServiceBB, $colItemsDmiBB, $oItemBB, $sWMIServiceBB
global  $BaseBoardProductReal
$sWMIServiceBB = "winmgmts:\\" & @ComputerName & "\root\CIMV2"
$objWMIServiceBB = ObjGet($sWMIServiceBB)
$colItemsDmiBB = $objWMIServiceBB.ExecQuery("SELECT * FROM Win32_BaseBoard")

	If IsObj($colItemsDmiBB) Then 
		for $oItemBB In $colItemsDmiBB
			$BaseBoardProductReal = $oItemBB.Product
		Next
	EndIf


;collect information about Energy from WMI settings
$wbemFlagReturnImmediately = 0x10
$wbemFlagForwardOnly = 0x20
$colItems = ""
$strComputer = "localhost"
global $Output=""
$Output &= "Computer: " & $strComputer  & @CRLF
$Output &= "==========================================" & @CRLF
$objWMIService = ObjGet("winmgmts:\\" & $strComputer & "\root\CIMV2")
$colItems = $objWMIService.ExecQuery("SELECT * FROM Win32_BIOS", "WQL", _
$wbemFlagReturnImmediately + $wbemFlagForwardOnly)

Global Const $GUID_DEVCLASS_BATTERY = '{72631E54-78A4-11D0-BCF7-00AA00B7B32A}'

Global Const $DIGCF_ALLCLASSES = 0x04
Global Const $DIGCF_DEVICEINTERFACE = 0x10
Global Const $DIGCF_DEFAULT = 0x01
Global Const $DIGCF_PRESENT = 0x02
Global Const $DIGCF_PROFILE = 0x08

Global Const $IOCTL_BATTERY_QUERY_INFORMATION  = 0x00294044
Global Const $IOCTL_BATTERY_QUERY_STATUS = 0x0029404C
Global Const $IOCTL_BATTERY_QUERY_TAG = 0x00294040

Global Const $BatteryInformation = 0
Global Const $BatteryGranularityInformation = 1
Global Const $BatteryTemperature = 2
Global Const $BatteryEstimatedTime = 3
Global Const $BatteryDeviceName = 4
Global Const $BatteryManufactureDate = 5
Global Const $BatteryManufactureName = 6
Global Const $BatteryUniqueID = 7
Global Const $BatterySerialNumber = 8

Global Const $BATTERY_CAPACITY_RELATIVE = 0x40000000
Global Const $BATTERY_IS_SHORT_TERM = 0x20000000
Global Const $BATTERY_SET_CHARGE_SUPPORTED = 0x00000001
Global Const $BATTERY_SET_DISCHARGE_SUPPORTED = 0x00000002
Global Const $BATTERY_SYSTEM_BATTERY = 0x80000000

Global Const $BATTERY_CHARGING = 0x00000004
Global Const $BATTERY_CRITICAL = 0x00000008
Global Const $BATTERY_DISCHARGING = 0x00000002
Global Const $BATTERY_POWER_ON_LINE = 0x00000001

Global Const $tagSP_DEVINFO_DATA = 'dword Size;' & $tagGUID & ';dword DevInst;ulong_ptr Reserved'
Global Const $tagSP_DEVICE_INTERFACE_DATA = 'dword Size;' & $tagGUID & ';dword Flag;ulong_ptr Reserved'
Global Const $tagSP_DEVICE_INTERFACE_DETAIL_DATA = 'dword Size;wchar DevicePath[1024]'

Global Const $tagBATTERY_INFORMATION = 'ulong Capabilities;byte Technology;byte Reserved[3];char Chemistry[4];ulong DesignedCapacity;ulong FullChargedCapacity;ulong DefaultAlert1;ulong DefaultAlert2;ulong CriticalBias;ulong CycleCount'
Global Const $tagBATTERY_MANUFACTURE_DATE = 'byte Day;byte Month;ushort Year'
Global Const $tagBATTERY_QUERY_INFORMATION = 'ulong BatteryTag;ulong InformationLevel;long AtRate'
Global Const $tagBATTERY_REPORTING_SCALE = 'ulong Granularity;ulong Capacity'
Global Const $tagBATTERY_STATUS = 'ulong PowerState;ulong Capacity;ulong Voltage;long Rate'
Global Const $tagBATTERY_WAIT_STATUS = 'ulong BatteryTag;ulong Timeout;ulong PowerState;ulong LowCapacity;ulong HighCapacity'

; Step: check DMI information
Global $sWMIService2, $objWMIService2, $colItemsDmi, $oItem2
$sWMIService2 = "winmgmts:\\" & @ComputerName & "\root\CIMV2"
$objWMIService2 = ObjGet($sWMIService2)
IF IsObj($objWMIService2) Then
$colItemsDmi = $objWMIService2.ExecQuery("SELECT * FROM Win32_ComputerSystem")
	If IsObj($colItemsDmi) Then
        For $oItem2 In $colItemsDmi
            Global $sModel = $oItem2.Model
			Global $sSku = $oItem2.SystemSKUNumber
        Next
	EndIf
EndIf

; Step: check BIOS and SN.
;Global $sWMIService, $objWMIService, $colItems, $oItem
If IsObj($colItems) then
   For $objItem In $colItems
      $strBiosCharacteristics = $objItem.BiosCharacteristics(0)
	 global  $Output = $objItem.SMBIOSBIOSVersion
		if ($objItem.SerialNumber <> null) Then
			global $Output2 = $objItem.SerialNumber
		Else
			 global $Output2 = $objItem.Caption
		EndIf
   Next
EndIf

; Step: flash bios
If ($biosVersion <> null) or ($biosCaption <> null) then
	If ($biosVersion == null) Then
		if ($objItem.Caption <> $biosCaption) Then
			RunWait(@ComSpec & " /c " & $biosCommand ,@scriptdir) ; BIOS Command -> Change if needed!
		EndIf
	Else
		if ($objItem.SMBIOSBIOSVersion <> $biosVersion) Then
			RunWait(@ComSpec & " /c " & $biosCommand ,@scriptdir) ; BIOS Command -> Change if needed!
		EndIf
	EndIf
EndIf

;Step: set shipping mode
if ($shippingMode <> null) then 
	Run($shippingMode& $shippingModeParameter ,@ScriptDir)
EndIf

$aData = _QueryBatteryInfo()
#cs return aData array to console. for debug proposes
If IsArray($aData) Then
    ConsoleWrite('BatteryName:         ' & $aData[0 ] & @CR)
    ConsoleWrite('ManufactureName:     ' & $aData[1 ] & @CR)
    ConsoleWrite('ManufactureDate:     ' & $aData[2 ] & @CR)
    ConsoleWrite('SerialNumber:        ' & $aData[3 ] & @CR)
    ConsoleWrite('UniqueID:            ' & $aData[4 ] & @CR)
    ConsoleWrite('Temperature:         ' & $aData[5 ] & @CR)
    ConsoleWrite('Capabilities:        ' & $aData[6 ] & @CR)
    ConsoleWrite('Technology:          ' & $aData[7 ] & @CR)
    ConsoleWrite('Chemistry:           ' & $aData[8 ] & @CR)
    ConsoleWrite('DesignedCapacity Wh:    ' & ($aData[9 ]/1000) & @CR)
    ConsoleWrite('FullChargedCapacity Wh: ' & ($aData[10]/1000) & @CR)
    ConsoleWrite('DefaultAlert1:       ' & $aData[11] & @CR)
    ConsoleWrite('DefaultAlert2:       ' & $aData[12] & @CR)
    ConsoleWrite('CriticalBias:        ' & $aData[13] & @CR)
    ConsoleWrite('CycleCount:          ' & $aData[14] & @CR)
Else
    ConsoleWrite('Battery not found.' & @CR)
EndIf
#ce

; Query battery info function
Func _QueryBatteryInfo($iBattery = 0) 

    Local $tGUID = _WinAPI_GUIDFromString($GUID_DEVCLASS_BATTERY)

    If Not IsDllStruct($tGUID) Then
        Return 0
    EndIf

    Local $tSPDID = DllStructCreate($tagSP_DEVICE_INTERFACE_DATA)
    Local $pSPDID = DllStructGetPtr($tSPDID)
    Local $tSPDIDD = DllStructCreate($tagSP_DEVICE_INTERFACE_DETAIL_DATA)
    Local $pGUID = DllStructGetPtr($tGUID)
    Local $hData, $Tag, $Ret, $Err = 1

    $Ret = DllCall('setupapi.dll', 'ptr', 'SetupDiGetClassDevsW', 'ptr', $pGUID, 'ptr', 0, 'ptr', 0, 'dword', BitOR($DIGCF_DEVICEINTERFACE, $DIGCF_PRESENT))
    If (@error) Or (Not $Ret[0]) Then
        Return 0
    EndIf
    $hData = $Ret[0]
    DllStructSetData($tSPDID, 'Size', DllStructGetSize($tSPDID))
    If @AutoItX64 Then
        DllStructSetData($tSPDIDD, 'Size', 8)
    Else
        DllStructSetData($tSPDIDD, 'Size', 6)
    EndIf
    Do
        $Ret = Dllcall('setupapi.dll', 'int', 'SetupDiEnumDeviceInterfaces', 'ptr', $hData, 'ptr', 0, 'ptr', $pGUID, 'dword', $iBattery, 'ptr', $pSPDID)
        If (@error) Or (Not $Ret[0]) Then
            ExitLoop
        EndIf
        $Ret = DllCall('setupapi.dll', 'int', 'SetupDiGetDeviceInterfaceDetailW', 'ptr', $hData, 'ptr', $pSPDID, 'ptr', DllStructGetPtr($tSPDIDD), 'dword', DllStructGetSize($tSPDIDD), 'ptr', 0, 'ptr', 0)
        If (@error) Or (Not $Ret[0]) Then
            ExitLoop
        EndIf
        $Err = 0
    Until 1
    Dllcall('setupapi.dll', 'int', 'SetupDiDestroyDeviceInfoList', 'ptr', $hData)
    If $Err Then
        Return 0
    EndIf

    Local $hBattery = _WINAPI_CreateFile(DllStructGetData($tSPDIDD, 'DevicePath'), 3, 2, 2)

    If Not $hBattery Then
        Return 0
    EndIf

    Local $tBQI = DllStructCreate($tagBATTERY_QUERY_INFORMATION)
    Local $tBI  = DllStructCreate($tagBATTERY_INFORMATION)
    Local $tBMD = DllStructCreate($tagBATTERY_MANUFACTURE_DATE)
    Local $tData = DllStructCreate('wchar[1024]')
    Local $aData[15]

    For $i = 0 To 14
        $aData[$i] = ''
    Next

    $Err = 1

    Do
        $Ret = DllCall('kernel32.dll', 'int', 'DeviceIoControl', 'ptr', $hBattery, 'dword', $IOCTL_BATTERY_QUERY_TAG, 'ulong*', -1, 'dword', 4, 'ulong*', 0, 'dword', 4, 'dword*', 0, 'ptr', 0)
        If (@error) Or (Not $Ret[0]) Then
            ExitLoop
        EndIf
        $Tag = $Ret[5]
        DllStructSetData($tBQI, 'BatteryTag', $Tag)
        DllStructSetData($tBQI, 'AtRate', 0)
        DllStructSetData($tBQI, 'InformationLevel', $BatteryDeviceName)
        $Ret = DllCall('kernel32.dll', 'int', 'DeviceIoControl', 'ptr', $hBattery, 'dword', $IOCTL_BATTERY_QUERY_INFORMATION, 'ptr', DllStructGetPtr($tBQI), 'dword', DllStructGetSize($tBQI), 'ptr', DllStructGetPtr($tData), 'dword', DllStructGetSize($tData), 'dword*', 0, 'ptr', 0)
        If $Ret[0] Then
            $aData[0] = DllStructGetData($tData, 1)
        EndIf
        DllStructSetData($tBQI, 'InformationLevel', $BatteryManufactureName)
        $Ret = DllCall('kernel32.dll', 'int', 'DeviceIoControl', 'ptr', $hBattery, 'dword', $IOCTL_BATTERY_QUERY_INFORMATION, 'ptr', DllStructGetPtr($tBQI), 'dword', DllStructGetSize($tBQI), 'ptr', DllStructGetPtr($tData), 'dword', DllStructGetSize($tData), 'dword*', 0, 'ptr', 0)
        If $Ret[0] Then
            $aData[1] = DllStructGetData($tData, 1)
        EndIf
        DllStructSetData($tBQI, 'InformationLevel', $BatteryManufactureDate)
        $Ret = DllCall('kernel32.dll', 'int', 'DeviceIoControl', 'ptr', $hBattery, 'dword', $IOCTL_BATTERY_QUERY_INFORMATION, 'ptr', DllStructGetPtr($tBQI), 'dword', DllStructGetSize($tBQI), 'ptr', DllStructGetPtr($tBMD), 'dword', DllStructGetSize($tBMD), 'dword*', 0, 'ptr', 0)
        If $Ret[0] Then
            $aData[2] = StringFormat('%02d/%02d/%04d', DllStructGetData($tBMD, 'Month'), DllStructGetData($tBMD, 'Day'), DllStructGetData($tBMD, 'Year'))
        EndIf
        DllStructSetData($tBQI, 'InformationLevel', $BatterySerialNumber)
        $Ret = DllCall('kernel32.dll', 'int', 'DeviceIoControl', 'ptr', $hBattery, 'dword', $IOCTL_BATTERY_QUERY_INFORMATION, 'ptr', DllStructGetPtr($tBQI), 'dword', DllStructGetSize($tBQI), 'ptr', DllStructGetPtr($tData), 'dword', DllStructGetSize($tData), 'dword*', 0, 'ptr', 0)
        If $Ret[0] Then
            $aData[3] = DllStructGetData($tData, 1)
        EndIf
        DllStructSetData($tBQI, 'InformationLevel', $BatteryUniqueID)
        $Ret = DllCall('kernel32.dll', 'int', 'DeviceIoControl', 'ptr', $hBattery, 'dword', $IOCTL_BATTERY_QUERY_INFORMATION, 'ptr', DllStructGetPtr($tBQI), 'dword', DllStructGetSize($tBQI), 'ptr', DllStructGetPtr($tData), 'dword', DllStructGetSize($tData), 'dword*', 0, 'ptr', 0)
        If $Ret[0] Then
            $aData[4] = DllStructGetData($tData, 1)
        EndIf
        DllStructSetData($tBQI, 'InformationLevel', $BatteryTemperature)
        $Ret = DllCall('kernel32.dll', 'int', 'DeviceIoControl', 'ptr', $hBattery, 'dword', $IOCTL_BATTERY_QUERY_INFORMATION, 'ptr', DllStructGetPtr($tBQI), 'dword', DllStructGetSize($tBQI), 'ulong*', 0, 'dword', 4, 'dword*', 0, 'ptr', 0)
        If $Ret[0] Then
            $aData[5] = $Ret[5]
        EndIf
        DllStructSetData($tBQI, 'InformationLevel', $BatteryInformation)
        $Ret = DllCall('kernel32.dll', 'int', 'DeviceIoControl', 'ptr', $hBattery, 'dword', $IOCTL_BATTERY_QUERY_INFORMATION, 'ptr', DllStructGetPtr($tBQI), 'dword', DllStructGetSize($tBQI), 'ptr', DllStructGetPtr($tBI), 'dword', DllStructGetSize($tBI), 'dword*', 0, 'ptr', 0)
        If $Ret[0] Then
            For $i = 6 To 14
                $aData[$i] = DllStructGetData($tBI, $i - 5 + ($i > 7))
            Next
        EndIf
        $Err = 0
    Until 1
    _WinAPI_CloseHandle($hBattery)
    If Not $Err Then
        Return $aData
    Else
        Return 0
    EndIf
EndFunc   ;==>_QueryBatteryInfo

; write log function
Func writeLog($LogBuch)
;writes an log and saves it at scriptdir. Changes name with datestamp to seperate results
	if $suchName <> -1 Then
		$suchNameDa=  FileFindNextFile($suchName)
		$logName = $suchNameDa
	EndIf
	Local Const $logPath = @ScriptDir & $logName
	Local $logOpen = FileOpen($logPath, $FO_CREATEPATH)
	FileWrite($logPath, @MDAY & "." & @MON & "-" & @HOUR & ":" & @MIN & ":" & @SEC & " ::: " & $LogBuch & @CRLF)
	FileClose($logOpen)
EndFunc   ;==>writeLog

; Step: GUI show battery status gui
global $hForm = GUICreate('Test ' & StringReplace(@ScriptName, '.au3', '()'), 300, 400, -1, -1, -1, $WS_EX_TOPMOST)
global $idButton = GUICtrlCreateButton('OK', 200, 370, 70, 23)
global $idCheckbox = GUICtrlCreateCheckbox("Shippingmode", 180,320,90,23)
GUICtrlSetState($idCheckbox,$GUI_CHECKED)
HotKeySet("{ENTER}","_enter")

;gathering battery information from cimv2 object
$objWMIService3 = ObjGet("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
$objBatt = $objWMIservice3.ExecQuery ("Select * from Win32_Battery")
$info = ""
For $object In $objBatt
	$info = ($object.DesignVoltage/1000)&" V " & @CRLF
Next
Global $info2=""

Local $idListview = GUICtrlCreateListView("Battery  			    |Status  ", 10, 10, 260, 300,$WS_BORDER + $WS_VSCROLL)
Local $idItem1 = GUICtrlCreateListViewItem("BatteryName				|"&$aData[0 ], $idListview)
Local $idItem2 = GUICtrlCreateListViewItem("ManufactureName			|"&$aData[1 ], $idListview)
If ($aData[2 ] <> 0) and ($aData[2 ] <> null) Then
	Local $idItem3 = GUICtrlCreateListViewItem("ManufactureDate			|"&$aData[2 ], $idListview) ; if
EndIf
If ($aData[3 ] <> 0) and ($aData[3 ] <> null) Then 
	Local $idItem4 = GUICtrlCreateListViewItem("SerialNumber			|"&$aData[3 ], $idListview) ; if
EndIf
Local $idItem5 = GUICtrlCreateListViewItem("UniqueID				|"&$aData[4 ], $idListview)
If ($aData[5 ] <> 0) and ($aData[5 ] <> null) Then 
	Local $idItem6 = GUICtrlCreateListViewItem("Temperature				|"&$aData[5 ], $idListview) ; if
EndIf
Local $idItem7 = GUICtrlCreateListViewItem("Capabilities			|"&$aData[6 ], $idListview)
Local $idItem8 = GUICtrlCreateListViewItem("Technology				|"&$aData[7 ], $idListview)
Local $idItem9 = GUICtrlCreateListViewItem("Chemistry				|"&$aData[8 ], $idListview)
Local $idItem10 = GUICtrlCreateListViewItem("DesignedCapacity 		|"&($aData[9 ]/1000)&" Wh", $idListview)
Local $idItem11 = GUICtrlCreateListViewItem("CurrentCapacity 		|"&($aData[10]/1000)&" Wh", $idListview)
;Local $idItem12 = GUICtrlCreateListViewItem("CriticalBias			|"&$aData[11], $idListview)
if ($aData[12] <> 0) and ($aData[12] <> null) Then 
	Local $idItem13 = GUICtrlCreateListViewItem("CycleCount				|"&$aData[12], $idListview) ; if
EndIf
Local $idItem14 = GUICtrlCreateListViewItem("Design Voltage 		|"&$info, $idListview)
;Local $idItem15 = GUICtrlCreateListViewItem("Charging rate			|"&$object.MaxRechargeTime, $idListview)

$DesignedCapacity = ($aData[9 ]/1000)
Global $CurrentCapacity = ($aData[10]/1000)

func _enter()
	$bool=$GUI_EVENT_CLOSE
EndFunc

;create GUI
GUICtrlCreateLabel('AC power:', 10, 314, 90, 14)
GUICtrlCreateLabel('Status:', 10, 334, 70, 14)
GUICtrlCreateLabel('Charge:', 10, 354, 90, 14)
GUICtrlCreateLabel('Time remaining:', 10, 374, 90, 14)

Global $g_aidLabel[4]
;shows information from BatteryStatus
For $i = 0 To 3
    $g_aidLabel[$i] = GUICtrlCreateLabel('Unknown', 110, 314 + 20 * $i, 60, 14)
Next
GUISetState(@SW_SHOW)
;updates BatteryStatus
AdlibRegister('_BatteryStatus', 1000)
;GUI loop
While 1
	$bool = GUIGetMsg()
	
    Switch $bool
        Case $GUI_EVENT_CLOSE
	
		case $idButton
			_ShippingMode($BaseBoardProductReal)
            ExitLoop
    EndSwitch
WEnd
;collects and gathers battery information
Func _BatteryStatus()
	
   Local $aData = _WinAPI_GetSystemPowerStatus()
    If @error Then Return
	global $tag1
	global $ChargePercent
    If BitAND($aData[1], 128) Then
        $aData[0] = 'Not present'
;battery not present = fail 
;fail == (tag1)
        For $i = 1 To 3
            $aData[$i] = 'Unknown'
;battery does possibly not get charged (tag1)
				
;if tag1 == maximal tag count or more, test is failed.
        Next
		$tag1=$tag1+1 ;(1)
    Else
        Switch $aData[0]
	;AC power status 
	;= $aData[0] 
            Case 0
                $aData[0] = 'Offline'
				$ACstatus=False
            Case 1
                $aData[0] = 'Online'
				$ACstatus=true
            Case Else
                $aData[0] = 'Unknown'
				$ACstatus=False
			
        EndSwitch
        Switch $aData[2]
	;Charge in percent. 
	;Battery below 75% shall be displayed GUI in yellow.
            Case 0 To 100
                $aData[2] &= '%'
				;saving charge in variable
				$ChargePercent = $aData[2] 
				;MsgBox(0,"debug1", $ChargePercent)
            Case Else
                $aData[2] = 'Unknown'
	;does possibly not get charged (tag1)
					$tag1=$tag1+1 ;(2)
        EndSwitch
        Switch $aData[3]
	;Time Remaining
            Case -1
                $aData[3] = 'Unknown'
;Unknown means fully charged or does not charge because of damage (tag1)
				$tag1=$tag1+1 ;(3)
			
            Case Else
	;calculating time to charge
                Local $H, $M
                $H = ($aData[3] - Mod($aData[3], 3600)) / 3600
                $M = ($aData[3] - Mod($aData[3], 60)) / 60 - $H * 60
                $aData[3] = StringFormat($H & ':%02d', $M)
        EndSwitch
        If BitAND($aData[1], 8) Then
           $aData[1] = 'Charging'
		
		Else
            Switch BitAND($aData[1], 0xF)
	;Status of Battery
                Case 1
                    $aData[1] = 'High'
					  
                Case 2
	;Status low could mean Batterytest is failed
						$tag1=$tag1+1 ;(4)
                    $aData[1] = 'Low'
					  
				Case 4
	;Status Critical means Batterytest is failed
					$tag1=$tag1+2 ;max value of tag1 eq 4. if status is critical, value is directly 4 for failed
                    $aData[1] = 'Critical'
					 
                Case Else
	;Status unknown could mean Batterytest is failed
					$tag1=$tag1+1 ;(5)
                    $aData[1] = 'Unknown'
					
            EndSwitch
        EndIf
    EndIf
;showing color of GUI
	
	
;algorithm for checking and responding battery status	
$colourChange=0
$colour= 0xFFFF00

If ($ChargePercent<=10) Then
	if ($colourChange == 0) Then
				$colourChange=1
				$colour=$COLOR_RED
				global $transLog = " /Battery-status: Critical"
		endif
EndIf

if ($ACstatus==true) and ($ChargePercent==0) and (TimerDiff($runTime) <= 600)  then 
	
	$limbo = GUICreate("Caution!",200,50,-1,-1,-1,-1,$hForm)
	$limbotext = GUICtrlCreateLabel("Loading-test is calculating"& @CRLF & "Wait until this message disappears",10,10)
	GUISetBkColor($COLOR_RED,$limbo)
	GUISetState(@SW_SHOW, $limbo)
	
		if ($colourChange == 0) Then
				$colourChange=1
				$colour=$COLOR_RED
				global $transLog = " /Battery-status: Critical"
		endif
EndIf

if ($DesignedCapacity > 0) And ($CurrentCapacity > 0) Then
		;Global $calcPercentCapacity = (((($DesignedCapacity*$CurrentCapacity)/100))-100)*(-1)
		Global $calcPercentCapacity = (($CurrentCapacity/$DesignedCapacity)*100)
		Global $calcPercentCapacityRounded = Round($calcPercentCapacity,2)
		If ($calcPercentCapacityRounded <= 90) Then
			if ($colourChange == 0) Then
				$colourChange=1
				$colour=$COLOR_RED
				global $transLog = " /Battery-status: Critical"
			endif
		EndIf
EndIf

if ($tag1>=3) then 
	if ($colourChange == 0) Then
		$colourChange=1
		$colour=$COLOR_RED
		global $transLog = " /Battery-status: Critical"
	endif
EndIf

if ($ChargePercent>=75) then 
	if ($colourChange == 0) Then
		$colourChange=1
		$colour=$COLOR_GREEN
		global $transLog = " /Battery-status: OK"
	endif
EndIf
GUISetBkColor($colour,$hForm)
$colourChange=0
	$tag1=0
	Global $transLog2 = " /Battery-load: " & $ChargePercent
	
For $i = 0 To 3
    GUICtrlSetData($g_aidLabel[$i], $aData[$i])
Next

EndFunc

func _ShippingMode($BaseBoardProduct)
	$RegEx = _ArrayToString((StringRegExp($BaseBoardProduct,'[DFCE]1[357].*',$STR_REGEXPARRAYMATCH)))

if $idCheckbox then	

	switch $BaseBoardProduct
		;pegatron
		case $RegEx
			RunWait(@ComSpec & " /c " & "\Shippingmodes\pgt\PEGAShipT64.exe" ,@scriptdir)
			
		;Wistron Graf 	
		Case "Graf"
			RunWait(@ComSpec &" /c " & "\Shippingmodes\graf\ShipMode.exe" ,@scriptdir)

		;3Nod Wingman	
		Case "Wingman"
			RunWait(@ComSpec &" /c " & "\Shippingmodes\wingman\VarEdit.exe /flash:SM.uve" ,@scriptdir)
		;3Nod Thalia
		Case "Thalia"
			RunWait(@ComSpec &" /c " & "\Shippingmodes\thalia\H2OUVE-W-CONSOLEx64 -sv SM.uve" ,@scriptdir)
		;WCBT112X
		Case "WCBT112X"
			RunWait(@ComSpec &" /c " & "\Shippingmodes\wcbt1122\ShippingMode.exe 1" ,@scriptdir)		
		; Clevo	
		Case 'P670RE1M'
			;	MsgBox("","Clevo1","")
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\IOinit.exe" ,@scriptdir)
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\shiptool.exe" ,@scriptdir)
		case 'P670RGM'
			;	MsgBox("","Clevo2","")
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\IOinit.exe" ,@scriptdir)
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\shiptool.exe" ,@scriptdir)
		Case 'P670RG1M'
			;	MsgBox("","Clevo3","")
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\IOinit.exe" ,@scriptdir)
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\shiptool.exe" ,@scriptdir)
		case 'P670RP6M'
			;	MsgBox("","Clevo4","")
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\IOinit.exe" ,@scriptdir)
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\shiptool.exe" ,@scriptdir)
		case 'P670RP6-M'
			;	MsgBox("","Clevo4","")
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\IOinit.exe" ,@scriptdir)
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\shiptool.exe" ,@scriptdir)
		Case 'P670RSGM'
			;	MsgBox("","Clevo5","")
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\IOinit.exe" ,@scriptdir)
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\shiptool.exe" ,@scriptdir)
		Case 'P670RS-GM'
			;	MsgBox("","Clevo5","")
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\IOinit.exe" ,@scriptdir)
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\shiptool.exe" ,@scriptdir)
		Case 'N155RD1M'
			;	MsgBox("","Clevo6","")
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\IOinit.exe" ,@scriptdir)
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\shiptool.exe" ,@scriptdir)
		Case 'NR155RD1M'
			;	MsgBox("","Clevo6","")
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\IOinit.exe" ,@scriptdir)
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\shiptool.exe" ,@scriptdir)
		case 'P670HP6GM'
			;	MsgBox("","Clevo7","")
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\IOinit.exe" ,@scriptdir)
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\shiptool.exe" ,@scriptdir)
		Case 'P670HSGM'
			;	MsgBox("","Clevo8","")
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\IOinit.exe" ,@scriptdir)
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\shiptool.exe" ,@scriptdir)
		Case 'P670HS-GM'
			;	MsgBox("","Clevo8","")
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\IOinit.exe" ,@scriptdir)
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\shiptool.exe" ,@scriptdir)
		Case 'PA70HP6GM'
			;	MsgBox("","Clevo9","")
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\IOinit.exe" ,@scriptdir)
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\shiptool.exe" ,@scriptdir)
		case 'PA70HSGM'
			;	MsgBox("","Clevo10","")
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\IOinit.exe" ,@scriptdir)
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\shiptool.exe" ,@scriptdir)
		case 'PA70EX'
			;	MsgBox("","Clevo11","")
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\IOinit.exe" ,@scriptdir)
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\shiptool.exe" ,@scriptdir)
		case 'N857EK1'
			; 	MsgBox("","Clevo13","")
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\IOinit.exe" ,@scriptdir)
			RunWait(@ComSpec &" /c " & "\Shippingmodes\clevo\shiptool.exe" ,@scriptdir)
			
		;LCFC Rescurer	
		case "Y520"
			RunWait(@ComSpec &" /c " & "\Shippingmodes\y520\LBGBttCtrl_x64.exe /Lock" ,@scriptdir)
		;case no shippindmode	
		case else
			MsgBox(16&$MB_TOPMOST,"Error","Error, no shippingmode available for this device :"&$BaseBoardProduct,2) 
	EndSwitch
EndIf
EndFunc


writeLog("Model; "& $sModel &" ;Sku:; "& $sSku &" ;SN; "&$Output2 &" ;BIOSV; "& $Output & $transLog2 & " ;Remaining Capacity; " & $CurrentCapacity & "; Wh / In Percent; " & $calcPercentCapacityRounded & " ;%; " & $transLog &@CRLF)


#cs
$TitleTextSplash = "Caution!"
$contentTextSplash=	"Loading-test is calculating"& @CRLF & "Wait until this message disappears"

func TextSplash($TitleTextSplash,$contentTextSplash)
	return SplashTextOn($TitleTextSplash,$contentTextSplash,$placeTextSplash,350,60,200,350)
	sleep(20000)
EndFunc
#ce