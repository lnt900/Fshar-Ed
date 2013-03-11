#cs
FsharEd
Version : 0.3 BETA
Author : lnt900@gmail.com
************** Change Log *****************
0.3 : Changes
	- Now check for size of file when got download link (prevent links to be deleted short after get and not download)
	- Also add "size" column at link list box
	- Small fix on clipboard catching, prevent from catching download link it self when click "copy links download"
0.2 : Changes
	- Clipboard Monitor added, now get links from clipboard when copy
	- Support download links with password
	- Added action to wait 60 secs if duplicated login session with other ones, retry for 4 times
	- Some small fixes
	- Disable/Enable buttons when processing
0.1 : Initializing
*******************************************
#ce
#include <GUIListBox.au3>
#include <WindowsConstants.au3>
#include <File.au3>
#include <Array.au3>
#include <GuiListView.au3>
#include <GUIConstants.au3>
#include <GuiButton.au3>

Global $version = "0.3 BETA"
Global $hListBox,$origHWND,$lastCopied='',$WM_CLIPUPDATE=0x031D
Local $hGUI, $linklist, $dllist, $listviewcontrols, $username, $password, $retry = 0, $loggedin = 0, $cookies[1][2] = [["", ""]], $f = "account.txt"

; GUI
$hGUI = GUICreate("FsharEd " & $version, 800, 600)
;GUISetIcon(@SystemDir & "\mspaint.exe", 0)

;Clipboard monitor
$origHWND = DLLCall("user32.dll","int","AddClipboardFormatListener","hwnd",$hGUI)
$origHWND = $origHWND[0]
GUIRegisterMsg($WM_CLIPUPDATE,"OnClipBoardChange")
Func OnClipBoardChange($hWnd, $Msg, $wParam, $lParam)
    ; do what you need when clipboard changes
    CBmonitor(ClipGet())
EndFunc

; Input link box
GUICtrlCreateLabel("Fshare links (Đưa link fshare vào đây, phân cách bởi xuống dòng hoặc space)" & @CRLF & "Nếu có mật khẩu thì thêm vào sau link kèm theo ký tự | (vd : link|matkhau) Nếu không nhập mật khẩu cùng link, tool sẽ tự động hỏi.", 5, 3)
$LinkInput = GUICtrlCreateEdit("", 5, 40, 500, 185)

; LIST VIEW
Local $iListView = GUICtrlCreateListView("", 5, 235, 790,180)
_GUICtrlListView_AddColumn($iListView, "Fshare Link", 200)
_GUICtrlListView_AddColumn($iListView, "Download Link", 530)
_GUICtrlListView_AddColumn($iListView, "Size", 55)

;buttons
$btnGetLink = GUICtrlCreateButton ("Lấy Link Download  >>>", 520,  40, 250, 40)
$btnClearlinks = GUICtrlCreateButton ("Xóa danh sách download", 520,  420, 180, 45)
_GUICtrlButton_Enable($btnClearlinks, False)
$btnSendToIDM = GUICtrlCreateButton ("Gửi link sang IDM", 520,  475, 180, 45)
_GUICtrlButton_Enable($btnSendToIDM, False)
$btnCopy = GUICtrlCreateButton ("Copy links download", 520,  530, 180, 45)
_GUICtrlButton_Enable($btnCopy, False)

;checkbox
;GUICtrlCreateCheckbox("Xóa list cũ", 710, 20, 80, 20)
;GUICtrlSetState(-1, $GUI_CHECKED)

; Listbox Progress
$hListBox = _GUICtrlListBox_Create($hGUI, "", 5, 420, 500, 170, BitOR($LBS_NOSEL, $WS_VSCROLL, $WS_HSCROLL, $LBS_HASSTRINGS))
GUISetState(@SW_SHOW)
_GUICtrlListBox_ResetContent($hListBox)
;_GUICtrlListBox_InitStorage($hListBox, 100, 4096)
addText("Fshare Get " & $version & ' Started ...',$hListBox);
addText("[Info] Open Source Project founded by lnt900 @ HDVietnam forum",$hListBox)
addText("----------------------------------------------------------------------------------------",$hListBox)


;function to add text and scroll listbox to bottom
Func addText($txt,$listBox)
     _GUICtrlListBox_InsertString($listBox, $txt, -1)
	 $num = _SendMessage($hListBox, 0x18B, 0, 0)
	_GUICtrlListBox_SetCurSel($listBox, $num -1)
EndFunc

;account info
Dim $aRecords
If Not _FileReadToArray($f, $aRecords) Then
	$username = ""
	$password = ""
ElseIf $aRecords[0] > 1 Then
	$username = $aRecords[1]
	$password = $aRecords[2]
	addText("[Account] Sử dụng tài khoản " & $username & " ...",$hListBox)
EndIf

; GROUP / Input fshare account
GUICtrlCreateGroup("Thông tin Fshare Account", 520, 80,250,145)
GUICtrlCreateLabel("Email :", 540, 100)
$txtAccEmail = GUICtrlCreateInput($username, 540, 115, 210, 22)
GUICtrlCreateLabel("Mật khẩu :", 540, 140)
$txtAccPassword = GUICtrlCreateInput($password, 540, 155, 210, 22, 0x0020)
$btnSaveAccInfo = GUICtrlCreateButton ("Lưu lại", 600,  185, 100, 25)
GUICtrlCreateGroup("", -99, -99, 1, 1) ;close group

;function to save account to tzt file
Func saveAcc($usr, $pw,$file)
	$usrx = GUICtrlRead($usr)
	$pwx = GUICtrlRead($pw)
	FileDelete($file)
	$fxx = FileOpen($file, 1)
	FileSetPos($fxx,0,0)
	FileFlush($fxx)
	FileWrite($fxx, $usrx & @CRLF)
	FileWrite($fxx, $pwx & @CRLF)
	FileClose($fxx)
	addText("[Account] Đã lưu thông tin tài khoản fshare ...",$hListBox)
EndFunc

;function logout of fshare
Func logoutF()
	addText("[Fshare] Logout khỏi fshare ...",$hListBox)
	$res = getHTTP("http://www.fshare.vn/logout.php", mkCookies())
	$res = getHTTP("http://www.fshare.vn/", mkCookies(), 'http://www.fshare.vn/logout.php')
	If StringInStr($res[2], "login.php") <> 0 Then
		addText("  -> Đã thoát.",$hListBox)
		$loggedin = 0
	Else
		addText("[Lỗi] chưa thoát được khỏi fshare !",$hListBox)
	EndIf
EndFunc

;Function Login to Fshare
Func loginF()
	$user = GUICtrlRead($txtAccEmail)
	$pword = GUICtrlRead($txtAccPassword)
	addText("[Fshare] Đăng nhập vào Fshare ...",$hListBox)
	$res = getHTTP("https://www.fshare.vn/login.php?url_refe=https%3A%2F%2Fwww.fshare.vn%2Findex.php&login_useremail=" & URLEncode($user) & '&login_password=' & URLEncode($pword), mkCookies(),"https://www.fshare.vn/login.php",0, 1, 0)
	$res = getHTTP("http://www.fshare.vn/", mkCookies())
	If StringInStr($res[2], "logout.php") <> 0 Then
		addText("  -> Đăng nhập thành công !",$hListBox)
		If StringInStr($res[2], "VIP.gif") <> 0 Then
			addText("  -> Tài khoản VIP ... OK !",$hListBox)
			$loggedin = 1
		Else
			addText("  -> Không phải tài khoản VIP. Thoát khỏi Fshare ...",$hListBox)
			logoutF()
		EndIf

	Else
		addText("  -> Đăng nhập thất bại, kiểm tra lại tk fshare",$hListBox)
	EndIf
EndFunc

;function to parse links input
Func parseLinks($input, $loggoutthen = 1)
	;$links = GUICtrlRead($input)
	$links = StringReplace($input, @CRLF, " ")
	$links = StringReplace($links, @TAB, " ")
	$aLink = StringSplit($links, " ")
	$hasfsharelinks = StringRegExp($links,'http:/(.*?)fshare.vn/(.*?)')

	If $hasfsharelinks = 1 Then
		_GUICtrlButton_Enable($btnGetLink, False)
		If $loggedin = 0 Then
			;Login to Fshare
			loginF()
		EndIf

		If $loggedin = 1 Then
			For $x=1 To $aLink[0]
				If $loggedin = 1 Then
					$retry = 0
					parseLink($aLink[$x])
				EndIf
			Next
		EndIf

		If $loggoutthen = 1 And $loggedin = 1 Then
			logoutF()
		EndIf

		If $retry < 4 Then
			addText("[OK] Đã xử lý xong tất cả các links !",$hListBox)
		Else
			addText("[Lỗi] trùng phiên đăng nhập quá 4 lần, vui lòng thử lại sau vài phút !",$hListBox)
			$retry = 0
		EndIf
		_GUICtrlButton_Enable($btnGetLink, True)
	Else
		addText("[Lỗi] Không có link fshare trong danh sách link !",$hListBox)
	EndIf
EndFunc

;function to get fshare download link
Func parseLink($lnk)
	$validLink = StringRegExp($lnk,'http:/(.*?)fshare.vn/file(.*?)')
	$isfolder = StringRegExp($lnk,'http:/(.*?)fshare.vn/folder(.*?)')
	If $validLink = 1 Then


		If StringInStr($lnk, '|') <> 0 Then
			;$lnk = StringReplace($lnk, '*', '|')
			$plink = StringSplit($lnk, '|')
			$lnk = $plink[1]
			$dlpw = $plink[2]
		Else
			$dlpw = ''
		EndIf

		If StringInStr($lnk, '?') <> 0 Then
			$plink = StringSplit($lnk, '?')
			$slink = $plink[1]
			addText("[Fshare] Lấy link cho file " & $slink & " ...",$hListBox)
			$res = getHTTP($lnk, mkCookies(), $slink, 1, 1)
		Else
			$slink = $lnk
			addText("[Fshare] Lấy link cho file " & $slink & " ...",$hListBox)
			$res = getHTTP($lnk, mkCookies(), '', 1)
		EndIf


		If (StringInStr($res[2], "logout.php") <> 0) Or ($res[1] = 1) Then
			$filesize = "unknown"
			If $res[1] = 1 Then
				;GUICtrlSetData($LinkInput,GUICtrlRead($LinkInput) & @CRLF & "Có redir đến " & $res[0])
				$size = InetGetSize($res[0])
				If $size > 1000000000 Then
						$filesize = Round($size/(1024^3),2) & " GB"
					ElseIf $size > 1000000 Then
						$filesize = Round($size/(1024^2),2) & " MB"
					ElseIf $size > 1000 Then
						$filesize = Round($size/(1024),2) & " KB"
					EndIf
				$listviewcontrols = arradd($listviewcontrols, GUICtrlCreateListViewItem($slink & "|" & $res[0] & "|" & $filesize, $iListView))
				$linklist = arradd($linklist, $res[0])
				$dllist = arradd($dllist, $slink)
				_GUICtrlButton_Enable($btnClearlinks, True)
				_GUICtrlButton_Enable($btnCopy, True)
				_GUICtrlButton_Enable($btnSendToIDM, True)
				addText("  -> Done.",$hListBox)
			ElseIf StringInStr($res[2], "vip_package_bt.png") <> 0 AND StringInStr($res[2], "fshare.vn/vip") <> 0 Then
				$arr = StringRegExp($res[2], '<form action="(.*?)" method="post" name="frm_download">', 3)
				If UBound($arr) > 0 Then
					;GUICtrlSetData($LinkInput,GUICtrlRead($LinkInput) & @CRLF & "Lấy được link download " & $arr[0])
					$size = InetGetSize($arr[0])
					If $size > 1000000000 Then
						$filesize = Round($size/(1024^3),2) & " GB"
					ElseIf $size > 1000000 Then
						$filesize = Round($size/(1024^2),2) & " MB"
					ElseIf $size > 1000 Then
						$filesize = Round($size/(1024),2) & " KB"
					EndIf
					$listviewcontrols = arradd($listviewcontrols, GUICtrlCreateListViewItem($slink & "|" & $arr[0] & "|" & $filesize, $iListView))
					$linklist = arradd($linklist, $arr[0])
					$dllist = arradd($dllist, $slink)
					_GUICtrlButton_Enable($btnClearlinks, True)
					_GUICtrlButton_Enable($btnCopy, True)
					_GUICtrlButton_Enable($btnSendToIDM, True)
					addText("  -> Done.",$hListBox)
				EndIf
			ElseIf StringInStr($res[2], "vip_package_bt.png") <> 0 AND StringInStr($res[2], '<input type="text" name="link_file_pwd_dl"/>') <> 0 Then
				addText("  -> Link Download có mật khẩu ...",$hListBox)
				If StringInStr($res[2], '<ul class="message-error">') <> 0 Then
					$announce = 'Mật khẩu không đúng. Nhập lại ?'
				Else
					$announce = 'File này yêu cầu nhập mật khẩu để tải.'
				EndIf

				if $dlpw = '' Then
					$filename = StringRegExp($res[2], '<p><b>(.*?):</b>(.*?)</p>', 3)
					$pos = WinGetPos($hGUI)
					$dlpw = InputBox("Mật khẩu", $slink & @CRLF & '-> ' & $filename[1] & @CRLF & @CRLF & $announce & ' Bỏ trống hoặc Cancel để bỏ qua link này. Nếu không nhập mật khẩu sau 15 giây sẽ tự động bỏ qua', '', '', - 1, 240, $pos[0]+200, $pos[1]+200, 15)
					If $dlpw = '' Then
						$err = '[Fshare] Bỏ qua link ' & $slink & ' -> unknown error !'
						Select
							Case @error = 0
								$err = '[Fshare] Bỏ qua link ' & $slink & ' -> bởi người dùng'
							Case @error = 1
								$err = '[Fshare] Bỏ qua link ' & $slink & ' -> bởi người dùng'
							Case @error = 2
								$err = '[Fshare] Bỏ qua link ' & $slink & ' -> Timeout 15s'
						EndSelect
					EndIf
				EndIf

				If $dlpw = '' Then
					addText($err ,$hListBox)
				Else
					$fileid = StringRegExp($res[2], '<input type="hidden" name="file_id" value="(.*?)"/>', 3)
					$newlnk = $lnk & '?action=download_file&file_id=' & $fileid[0] & '&link_file_pwd_dl=' & URLEncode($dlpw)
					parseLink($newlnk)
				EndIf
			ElseIf StringInStr($res[2], '<ul class="message-error">') <> 0 Then
				addText("[Fshare][Lỗi] Có thể đang trùng phiên đăng nhập với người khác !",$hListBox)
				logoutF()
				addText(" -> Đợi xử lý lại sau 1 phút ...",$hListBox)
				$retry += 1
				If $retry < 4 Then
					Sleep(60000)
					loginF()
					parseLink($lnk)
				EndIf
			Else
				addText("[Fshare] Error: No Download Link !",$hListBox)
			EndIf
		EndIf
		Sleep(200)
	ElseIf $isfolder = 1 Then
		addText("[Fshare] Link " & $lnk & " là thư mục !",$hListBox)
		$res = getHTTP($lnk, mkCookies(), '', 1)
		If StringInStr($res[2], "fshare.vn/file/") <> 0 Then
			$arr = StringRegExp($res[2], '<a href="(.*?)" target="_blank"><span class="filename">', 3)
			addText("[Fshare] Có " & UBound($arr) & " file trong thư mục ...",$hListBox)
			;parseLinks(_ArrayToString($arr, " "), 0)
			For $i = 0 To UBound($arr) - 1
				parseLink($arr[$i])
			Next
		Else
			addText("[Fshare] Thư mục trống !",$hListBox)
		EndIf
	EndIf
EndFunc

;function to get/post http links
Func getHTTP($lnk, $cookie = '', $refer = '', $ignorecookies = 0, $post = 0, $redir = 0)
	$method = "GET"
	$weblink = StringSplit($lnk, '?')
	;addText($weblink[2],$hListBox)
	If $post = 1 Then
		$method = "POST"
		$linklink = $weblink[1]
		$poststring = $weblink[2]
	Else
		$linklink = $lnk
	EndIf

	$oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
	If $redir = 0 Then
		$oHTTP.Option(6) = False
	EndIf
	$oHTTP.Open($method, $linklink , False)
	$oHTTP.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:19.0) Gecko/20100101 Firefox/19.0")
	If StringLen($refer)>1 Then
		$oHTTP.SetRequestHeader("Referer", $refer)
	EndIf
	If StringLen($cookie)>1 Then
		$oHTTP.SetRequestHeader("Cookie", $cookie)
	EndIf
	If $post = 1 Then
		$oHTTP.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
		$oHTTP.SetRequestHeader("Content-Length", StringLen($poststring))
		$oHTTP.Send($poststring)
	Else
		$oHTTP.Send()
	EndIf
	$oHTTP.WaitForResponse
	$HeaderResponses = $oHTTP.GetAllResponseHeaders()

	If $ignorecookies = 0 Then
		; Handle Cookies
		$array = StringRegExp($HeaderResponses, 'Set-Cookie: (.+)\r\n', 3)
		;$cookies = ''
		for $i = 0 to UBound($array) - 1
			; Add all cookies to a single string, and then clean it up.
			$cook = $array[$i] & ';'
			; Removing parts we do not use..
			$cook = StringRegExpReplace($cook, "( path| domain| expires)=[^;]+", "")
			$cook = StringRegExpReplace($cook, " HttpOnly", "")
			$cook = StringRegExpReplace($cook, "[;]{2,}", ";")

			$cook1 = StringSplit($cook,";")
			For $k=1 To $cook1[0]
				If StringInStr($cook1[$k],"=") Then
					$cook2 = StringSplit(StringReplace($cook1[$k]," ", ""),"=")
					if $cookies[0][0] == "" Then
						$cookies[0][0] = $cook2[1]
						$cookies[0][1] = $cook2[2]
					Else
						$inserted = 0
						for $j = 0 to UBound($cookies) - 1
							If $cook2[1] == $cookies[$j][0] Then
								$cookies[$j][1] = $cook2[2]
								$inserted = 1
							ElseIf ($j == (UBound($cookies) - 1)) And ($inserted == 0) Then
								ReDim $cookies[UBound($cookies) + 1][2]
								$cookies[UBound($cookies) - 1][0] = $cook2[1]
								$cookies[UBound($cookies) - 1][1] = $cook2[2]

							EndIf
						Next
					EndIf
				EndIf
			Next

		Next
	EndIf

	Dim $ret[4]
	If StringInStr($HeaderResponses, "Location:") <> 0 Then
		$ret["0"] = $oHTTP.GetResponseHeader("Location")
		$ret["1"] = 1
	Else
		$ret["0"] = ""
		$ret["1"] = 0
	EndIf
	$ret["2"] = $oHTTP.Responsetext
	;$ret["method"] = $method
	$ret["3"] = $oHTTP.GetAllResponseHeaders()

	Return $ret
EndFunc

;function to encode url for websurfing
Func URLEncode($urlText)
    $url = ""
    For $i = 1 To StringLen($urlText)
        $acode = Asc(StringMid($urlText, $i, 1))
        Select
            Case ($acode >= 48 And $acode <= 57) Or _
                    ($acode >= 65 And $acode <= 90) Or _
                    ($acode >= 97 And $acode <= 122)
                $url = $url & StringMid($urlText, $i, 1)
            Case $acode = 32
                $url = $url & "+"
            Case Else
                $url = $url & "%" & Hex($acode, 2)
        EndSelect
    Next
    Return $url
EndFunc

;function to make cookies from array
Func mkCookies()
	$rt = ""
	for $j = 0 to UBound($cookies) - 1
		$rt = $rt & $cookies[$j][0] & "=" & $cookies[$j][1]
		If $j <> (UBound($cookies) - 1) Then
			$rt = $rt & "; "
		EndIf
	Next
	Return $rt
EndFunc

;function to add element to array ( fuck autoit )
Func arradd($array, $value)
	If IsArray($array) Then
		_ArrayAdd($array, $value)
		Return $array
	Else
		Dim $rt[1] = [$value]
		Return $rt
	EndIf
EndFunc

;function to clear links list
Func ClearLinks()
	$linklist = 0
	$dllist = 0
	GUICtrlSetData($LinkInput,'')
	For $i = 0 to UBound($listviewcontrols) - 1
		GUICtrlDelete($listviewcontrols[$i])
	Next
	$listviewcontrols = 0
	_GUICtrlButton_Enable($btnClearlinks, False)
	_GUICtrlButton_Enable($btnCopy, False)
	_GUICtrlButton_Enable($btnSendToIDM, False)
EndFunc

;function to send download links to IDM
Func SendToIDM()
	If UBound($linklist) > 0 Then
		$clsid = "{AC746233-E9D3-49CD-862F-068F7B7CCCA4}"
		$idd = "{4BD46AAE-C51F-4BF7-8BC0-2E86E33D1873}"
		$desc = "SendLinkToIDM hresult(bstr;bstr;bstr;bstr;bstr;bstr;bstr;bstr;long);"
		$idm = ObjCreateInterface($clsid,$idd,$desc)
		For $i = 0 to UBound($linklist) - 1
			$idm.SendLinkToIDM($linklist[$i], $dllist[$i], '', '', '', '','', '', 2)
		Next
		addText("[IDM] Đã gửi link download sang IDM",$hListBox)
	EndIf
EndFunc

;function executing when clipboard changed
Func CBmonitor($data)
	If $data<>$lastCopied Then
		$lastCopied=$data
		$isfsharelink = StringRegExp($data,'http://(.*?)fshare.vn/file(.*?)')
		$isfsharefolder = StringRegExp($data,'http://(.*?)fshare.vn/folder(.*?)')
		If $isfsharelink = 1 Or $isfsharefolder = 1 Then
			addText("[Clipboard Monitor] Đã lấy link fshare từ clipboard",$hListBox)
			$ctb = GUICtrlRead($LinkInput)
			If StringLen($ctb)>0 Then
				$ctb = $ctb & @CRLF
			EndIf
			GUICtrlSetData($LinkInput,$ctb & $data)
		EndIf
	EndIf
EndFunc

; GUI MESSAGE LOOP
While 1
	$msg = GUIGetMsg()
	Select
		Case $msg = $GUI_EVENT_CLOSE
			ExitLoop
		Case $msg = $btnGetLink
			parseLinks(GUICtrlRead($LinkInput))
		Case $msg = $btnClearlinks
			ClearLinks()
		Case $msg = $btnSendToIDM
			SendToIDM()
		Case $msg = $btnCopy
			;_ArrayToClip($linklist);
			ClipPut(_ArrayToString($linklist, @CRLF))
			addText("[Clipboard Monitor] Đã Copy Link vào clipboard",$hListBox)
		Case $msg = $btnSaveAccInfo
			saveAcc($txtAccEmail, $txtAccPassword,$f)
	EndSelect
WEnd