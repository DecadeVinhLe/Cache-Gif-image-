#include <GUIConstants.au3>
#include <GDIPlus.au3>
#include "Cached GIF Animation.au3"

OnAutoItExitRegister(_GIF_Animation_Quit)

Local $hGUI = GUICreate("GIF Animation", 800, 600, -1, -1, $WS_POPUP, $WS_EX_CONTROLPARENT)
Local $hGraphics = _GDIPlus_GraphicsCreateFromHWND($hGUI)
Local $hOrig = _GDIPlus_ImageLoadFromFile("bg.png")
Local $hImage = _GDIPlus_ImageResize($hOrig, 800, 600)
_GDIPlus_ImageDispose($hOrig)

GUISetState()

_GDIPlus_GraphicsDrawImageRect($hGraphics, $hImage, 0, 0, 800, 600)
_GUICtrlCreateAnimGIF("Counter.gif", 150, 50, 285, 280, -1, -1, False, $hImage, True)

Do
Until GUIGetMsg() = $GUI_EVENT_CLOSE

_GDIPlus_ImageDispose($hImage)
_GDIPlus_GraphicsDispose($hGraphics)
