#include-once
#include <GDIPlus.au3>

; #INDEX# =======================================================================================================================
; Title .........: Cached GIF Animation
; AutoIt Version : 3.3.16.1
; Language ..... : English
; Description ...: Functions to manage GIF animation
; Author ........: Nine
; Modified ......: 2023-08-15
; ===============================================================================================================================

; #GLOBALS# =====================================================================================================================
Global $aGIF_Animation[0][17]
; ===============================================================================================================================

; #CURRENT# =====================================================================================================================
; _GUICtrlCreateAnimGIF
; _GUICtrlDeleteAnimGIF
; _GIF_Animation_Quit
; ===============================================================================================================================

; #INTERNAL_USE_ONLY#============================================================================================================
; __GIF_Animation_DrawTimer
; __GIF_Animation_DrawFrame
; __GDIPlus_GraphicsDrawCachedBitmap
; __GDIPlus_CachedBitmapCreate
; __GDIPlus_CachedBitmapDispose
; ===============================================================================================================================

_GDIPlus_Startup()

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlCreateAnimGIF
; Description ...: Create a GIF control inside a previously GUI created window
; Syntax.........: _GUICtrlCreateAnimGIF($vSource, $iLeft, $iTop, $iWidth, $iHeight, [$iStyle = -1, [$iExStyle = -1, [$bHandle = False, [$vBackGround = 0, [$bImage = False]]]]])
; Parameters ....: $vSource           - Either a GIF file name or a handle to a GIF image create by GDI+ (handle would be used as a resource)
;                  $iLeft             - Left position of the control
;                  $iTop              - Top position of the control
;                  $iWidth            - Width of the control (must be the actual size of the GIF)
;                  $iHeight           - Height of the control (must be the actual size of the GIF)
;                  $iStyle            - Optional: Style of the control (by default : $SS_NOTIFY forced style : $SS_BITMAP)
;                  $iExStyle          - Optional: Extented style of the control (by default : null)
;                  $bHandle           - Optional: True if a GDI+ image handle of a GIF, False if a GIF file name (by default : False)
;                  $vBackGround       - Optional: Background color or GDI+ handle of a background Image.  This is required for a GIF
;                                                 when frames need to be erased before repainting (by default : 0 for no erasure)
;                  $bImage            - Optional: True if background is a handle to GDI+. False if background is a color. (by default : false)
; Return values .: Success - Id of the control
;                  Failure - Returns 0 and sets @error
; Author ........: Nine
; Remarks .......: Width and Height are mandatory because of an erronous display without them
;                  As discussed here :https://www.autoitscript.com/forum/topic/153782-help-filedocumentation-issues-discussion-only/page/30/?tab=comments#comment-1438857
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _GUICtrlCreateAnimGIF($vSource, $iLeft, $iTop, $iWidth, $iHeight, $iStyle = -1, $iExStyle = -1, $bHandle = False, $vBackGround = 0, $bImage = False)
  Local Const $GDIP_PROPERTYTAGFRAMEDELAY = 0x5100
  If $iStyle = Default Then $iStyle = -1
  If $iExStyle = Default Then $iExStyle = -1
  If $bHandle = Default Then $bHandle = False
  If $vBackGround = Default Then $vBackGround = 0
  If $bImage = Default Then $bImage = False

  Local $iIdx, $idPic, $hImage, $aTime, $iNumberOfFrames, $iType

  If $bHandle Then
    $iType = _GDIPlus_ImageGetType($vSource)
    If @error Or $iType <> $GDIP_IMAGETYPE_BITMAP Then Return SetError(1, 0, 0)
  Else
    If Not FileExists($vSource) Then Return SetError(2, 0, 0)
  EndIf
  $idPic = GUICtrlCreatePic("", $iLeft, $iTop, $iWidth, $iHeight, $iStyle, $iExStyle)
  If Not $idPic Then Return SetError(3, 0, 0)
  $hImage = $bHandle ? $vSource : _GDIPlus_ImageLoadFromFile($vSource)
  If @error Then Return SetError(10 + @error, 0, 0)
  $iNumberOfFrames = _GDIPlus_ImageGetFrameCount($hImage, $GDIP_FRAMEDIMENSION_TIME)
  If @error Then Return SetError(20 + @error, 0, 0)
  $aTime = _GDIPlus_ImageGetPropertyItem($hImage, $GDIP_PROPERTYTAGFRAMEDELAY)
  If @error Then Return SetError(30 + @error, 0, 0)
  If UBound($aTime) - 1 <> $iNumberOfFrames Then Return SetError(4, 0, 0)
  For $i = 0 To UBound($aTime) - 1
    If Not $aTime[$i] Then $aTime[$i] = 5
  Next
  ; search for an empty slot left after deletion
  For $iIdx = 0 To UBound($aGIF_Animation) - 1
    If Not $aGIF_Animation[$iIdx][0] Then ExitLoop
  Next

  ; gather all pertinent informations

  If $iIdx = UBound($aGIF_Animation) Then ReDim $aGIF_Animation[$iIdx + 1][UBound($aGIF_Animation, 2)]
  $aGIF_Animation[$iIdx][1] = $hImage
  $aGIF_Animation[$iIdx][2] = $iNumberOfFrames
  $aGIF_Animation[$iIdx][3] = $aTime  ; 1-base array
  $aGIF_Animation[$iIdx][4] = 0       ; current Frame number
  $aGIF_Animation[$iIdx][5] = TimerInit()
  $aGIF_Animation[$iIdx][6] = GUICtrlGetHandle($idPic)
  $aGIF_Animation[$iIdx][7] = _GDIPlus_GraphicsCreateFromHWND($aGIF_Animation[$iIdx][6]) ; base graphics
  $aGIF_Animation[$iIdx][8] = $vBackGround
  $aGIF_Animation[$iIdx][9] = _GDIPlus_BitmapCreateFromGraphics($iWidth, $iHeight, $aGIF_Animation[$iIdx][7]) ; hBitmap
  $aGIF_Animation[$iIdx][10] = _GDIPlus_ImageGetGraphicsContext($aGIF_Animation[$iIdx][9]) ; backbuffer
  $aGIF_Animation[$iIdx][11] = $iWidth
  $aGIF_Animation[$iIdx][12] = $iHeight
  $aGIF_Animation[$iIdx][13] = $iLeft
  $aGIF_Animation[$iIdx][14] = $iTop
  $aGIF_Animation[$iIdx][15] = $bImage
  $aGIF_Animation[$iIdx][16] = False    ; mark for deletion
  $aGIF_Animation[$iIdx][0] = $idPic

  ; if first GIF, start the timer
  If UBound($aGIF_Animation) = 1 Then AdlibRegister(__GIF_Animation_DrawTimer, 10)
  Return $idPic

EndFunc   ;==>_GUICtrlCreateAnimGIF

; #FUNCTION# ====================================================================================================================
; Name...........: _GIF_Animation_Quit
; Description ...: Dispose of all object, unregister draw timer and shutdown GDI+
; Syntax.........: _GIF_Animation_Quit()
; Parameters ....: None
; Return values .: None
; Author ........: Nine
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _GIF_Animation_Quit()
  AdlibUnRegister(__GIF_Animation_DrawTimer)
  For $i = 0 To UBound($aGIF_Animation) - 1
    If Not $aGIF_Animation[$i][0] Then ContinueLoop
    _GDIPlus_ImageDispose($aGIF_Animation[$i][1])
    _GDIPlus_GraphicsDispose($aGIF_Animation[$i][7])
    _GDIPlus_GraphicsDispose($aGIF_Animation[$i][10])
    _GDIPlus_BitmapDispose($aGIF_Animation[$i][9])
  Next
  _GDIPlus_Shutdown()
EndFunc   ;==>_GIF_Animation_Quit

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlDeleteAnimGIF
; Description ...: Delete one GIF control
; Syntax.........: _GUICtrlDeleteAnimGIF($idPic)
; Parameters ....: $idPic              - Control id return from _GUICtrlCreateAnimGIF
; Return values .: Success - Returns 1
;                  Failure - Returns 0 and sets @error (unfound control id)
; Author ........: Nine
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _GUICtrlDeleteAnimGIF($idPic)
  Local $iNum = 0, $bFound = False
  For $iIdx = 0 To UBound($aGIF_Animation) - 1
    If $aGIF_Animation[$iIdx][0] = $idPic Then
      $aGIF_Animation[$iIdx][16] = True
      Return 1
    EndIf
  Next
  Return SetError(1, 0, 0)
EndFunc   ;==>_GUICtrlDeleteAnimGIF

; #INTERNAL_USE_ONLY#============================================================================================================
Func __GIF_Animation_DrawTimer()
  Local Static $bDrawing = False
  Local $aTime
  If $bDrawing Then Return
  $bDrawing = True
  __GIF_Animation_DeleteControl()
  For $i = 0 To UBound($aGIF_Animation) - 1
    If Not $aGIF_Animation[$i][0] Then ContinueLoop
    $aTime = $aGIF_Animation[$i][3]
    If TimerDiff($aGIF_Animation[$i][5]) >= $aTime[$aGIF_Animation[$i][4] + 1] * 10 Then
      __GIF_Animation_DrawFrame($i)
      $aGIF_Animation[$i][4] = Mod($aGIF_Animation[$i][4] + 1, $aGIF_Animation[$i][2]) ; If $iFrame = $iFrameCount then reset $iFrame to 0
      $aGIF_Animation[$i][5] = TimerInit()
    EndIf
  Next
  $bDrawing = False
EndFunc   ;==>__GIF_Animation_DrawTimer

Func __GIF_Animation_DrawFrame($iGIF)
  _GDIPlus_ImageSelectActiveFrame($aGIF_Animation[$iGIF][1], $GDIP_FRAMEDIMENSION_TIME, $aGIF_Animation[$iGIF][4])
  Local $hCachedBmp = __GDIPlus_CachedBitmapCreate($aGIF_Animation[$iGIF][10], $aGIF_Animation[$iGIF][1]) ; (hGraphics, $hBitmap)
  If $aGIF_Animation[$iGIF][8] Then
    If $aGIF_Animation[$iGIF][15] Then
      ;Local $hTmp = _GDIPlus_BitmapCloneArea($aGIF_Animation[$iGIF][8], $aGIF_Animation[$iGIF][13], $aGIF_Animation[$iGIF][14], $aGIF_Animation[$iGIF][11], $aGIF_Animation[$iGIF][12], $GDIP_PXF32RGB)
      _GDIPlus_GraphicsDrawImageRectRect($aGIF_Animation[$iGIF][10], $aGIF_Animation[$iGIF][8], $aGIF_Animation[$iGIF][13], $aGIF_Animation[$iGIF][14], _
          $aGIF_Animation[$iGIF][11], $aGIF_Animation[$iGIF][12], 0, 0, $aGIF_Animation[$iGIF][11], $aGIF_Animation[$iGIF][12])
    Else
      _GDIPlus_GraphicsClear($aGIF_Animation[$iGIF][10], BitOR(0xFF000000, $aGIF_Animation[$iGIF][8]))
    EndIf
  EndIf
  __GDIPlus_GraphicsDrawCachedBitmap($aGIF_Animation[$iGIF][10], $hCachedBmp, 0, 0) ;(hGraphics, hCachedBmp, X, Y)
  _GDIPlus_GraphicsDrawImageRect($aGIF_Animation[$iGIF][7], $aGIF_Animation[$iGIF][9], 0, 0, $aGIF_Animation[$iGIF][11], $aGIF_Animation[$iGIF][12])
  __GDIPlus_CachedBitmapDispose($hCachedBmp)
EndFunc   ;==>__GIF_Animation_DrawFrame

Func __GIF_Animation_DeleteControl()
  Local $bFound = False
  For $iIdx = 0 To UBound($aGIF_Animation) - 1
    If $aGIF_Animation[$iIdx][16] Then
      _GDIPlus_ImageDispose($aGIF_Animation[$iIdx][1])
      _GDIPlus_GraphicsDispose($aGIF_Animation[$iIdx][7])
      _GDIPlus_GraphicsDispose($aGIF_Animation[$iIdx][10])
      _GDIPlus_BitmapDispose($aGIF_Animation[$iIdx][9])
      GUICtrlDelete($aGIF_Animation[$iIdx][0])
      $aGIF_Animation[$iIdx][0] = 0
    ElseIf $aGIF_Animation[$iIdx][0] Then
      $bFound = True
    EndIf
  Next
  If Not $bFound Then
    AdlibUnRegister(__GIF_Animation_DrawTimer)
    ReDim $aGIF_Animation[0][UBound($aGIF_Animation, 2)]
  EndIf
EndFunc   ;==>__GIF_Animation_DeleteControl

Func __GDIPlus_GraphicsDrawCachedBitmap($hGraphics, $hCachedBitmap, $iX, $iY)
  Local $aResult = DllCall($__g_hGDIPDll, "int", "GdipDrawCachedBitmap", "handle", $hGraphics, "handle", $hCachedBitmap, "int", $iX, "int", $iY)
  If @error Then Return SetError(@error, @extended, False)
  If $aResult[0] Then Return SetError(10, $aResult[0], False)
  Return True
EndFunc   ;==>__GDIPlus_GraphicsDrawCachedBitmap

Func __GDIPlus_CachedBitmapCreate($hGraphics, $hBitmap)
  Local $aResult = DllCall($__g_hGDIPDll, "int", "GdipCreateCachedBitmap", "handle", $hBitmap, "handle", $hGraphics, "handle*", 0)
  If @error Then Return SetError(@error, @extended, 0)
  If $aResult[0] Then Return SetError(10, $aResult[0], 0)
  Return $aResult[3]
EndFunc   ;==>__GDIPlus_CachedBitmapCreate

Func __GDIPlus_CachedBitmapDispose($hCachedBitmap)
  Local $aResult = DllCall($__g_hGDIPDll, "int", "GdipDeleteCachedBitmap", "handle", $hCachedBitmap)
  If @error Then Return SetError(@error, @extended, False)
  If $aResult[0] Then Return SetError(10, $aResult[0], False)
  Return True
EndFunc   ;==>__GDIPlus_CachedBitmapDispose
; ===============================================================================================================================