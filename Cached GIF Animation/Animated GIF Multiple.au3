#include <GUIConstants.au3>
#include <Constants.au3>
#include "Cached GIF Animation.au3"
#include <WinAPISysWin.au3>

OnAutoItExitRegister(_GIF_Animation_Quit)

Global $hGUI = GUICreate("GIF Animation", 500, 500, -1, -1, $WS_POPUP, $WS_EX_LAYERED)
GUISetBkColor(0xFFFFFF)
Global $IMG_Ctrl1 = _GUICtrlCreateAnimGIF("9.gif", 150, 0, 192, 172, -1, $GUI_WS_EX_PARENTDRAG)
Global $IMG_Ctrl2 = _GUICtrlCreateAnimGIF("gif-Green-UFO.gif", 0, 180, 150, 80, -1, $GUI_WS_EX_PARENTDRAG)
Global $IMG_Ctrl3 = _GUICtrlCreateAnimGIF("Catalog.gif", 160, 180, 320, 184, -1, $GUI_WS_EX_PARENTDRAG)
Global $IMG_Ctrl4 = _GUICtrlCreateAnimGIF("Kafu.gif", 30, 260, 90, 90, -1, $GUI_WS_EX_PARENTDRAG)
Local $idButton = GUICtrlCreateButton("Hide", 10, 10, 80, 30)
Local $idQuit = GUICtrlCreateButton("Quit", 10, 50, 80, 30)

_WinAPI_SetLayeredWindowAttributes($hGUI, 0xFFFFFF)

GUISetState(@SW_SHOW, $hGUI)

Local $aCaption[4] = ["Show", "Delete", "Recreate", "Hide"], $iCounter = -1

While True
  Switch GUIGetMsg()
    Case $GUI_EVENT_CLOSE, $idQuit
      ExitLoop
    Case $idButton
      $iCounter += 1
      $iCounter = Mod($iCounter,4)
      GUICtrlSetData($idButton, $aCaption[$iCounter])
      Switch $iCounter
        Case 0         ; hide
          GUICtrlSetState($IMG_Ctrl2, $GUI_HIDE)
        Case 1         ; show
          GUICtrlSetState($IMG_Ctrl2, $GUI_SHOW)
        Case 2         ; delete
          _GUICtrlDeleteAnimGIF($IMG_Ctrl2)
        Case 3         ; recreate
          $IMG_Ctrl2 = _GUICtrlCreateAnimGIF("gif-Green-UFO.gif", 0, 180, 150, 80, -1, $GUI_WS_EX_PARENTDRAG)
          _WinAPI_SetLayeredWindowAttributes($hGUI, 0xFFFFFF)
      EndSwitch
  EndSwitch
WEnd

_GIF_Animation_Quit()