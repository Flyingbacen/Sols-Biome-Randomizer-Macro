/**
 * @param {0|1|2|3|String} area Capturing area.</br>
 * `0`: entire desktop, `1`: active window, `2`: active client area, `3`: active monitor</br>
 * `area` can also be a string in the format of `"{left}, {top}, {right}, {bottom}, {zoomed_width?}, {zoomed_height?}"`
 * @param {Bool} includeCursor If `true`, the cursor will be captured as well
 * @param {String|0} savePath Path to save the image to. If `0`, the image will be saved to the clipboard; if omitted or `""`, the image will be saved to the script's directory with the name `screen.bmp`
 * @param {Integer} quality A number between 0 and 100 that specifies the quality of the image. Only applies to JPEG format.
 */
CaptureScreen(area := 0, includeCursor := False, savePath := "", quality := "", ID := "") {
	newWidth := 0, newHeight := 0
	ID := ID ? ID : "A"
	if (!area) {
		left := SysGet(76)
		top := SysGet(77)
		width := SysGet(78)
		height := SysGet(79)
	}
	else if (area == 1)
		WinGetPos(&left, &top, &width, &height, ID)
	else if (area == 2) {
		rect := Buffer(16, 0)
		hWnd := WinGetID(ID)
		DllCall("GetClientRect", "Ptr", hWnd, "Ptr", rect)
		DllCall("ClientToScreen", "Ptr", hWnd, "Ptr", rect)
		left := NumGet(rect, 0, "Int")
		top := NumGet(rect, 4, "Int")
		width := NumGet(rect, 8, "Int")
		height := NumGet(rect, 12, "Int")
	}
	else if (area == 3) {
		pos := 0
		DllCall("GetCursorPos", "Int64*", &pos)
		hMonitor := DllCall("MonitorFromPoint", "Int64", pos, "UInt", 2, "Ptr")
		length := 4 * 2 + 16 * 2
		monitorInfo := Buffer(length, 0)
		NumPut("UInt", length, monitorInfo)
		DllCall("GetMonitorInfo", "Ptr", hMonitor, "Ptr", monitorInfo)
		left := NumGet(monitorInfo, 4, "Int")
		top := NumGet(monitorInfo, 8, "Int")
		width := NumGet(monitorInfo, 12, "Int") - left
		height := NumGet(monitorInfo, 16, "Int") - top
	}
	else {
		args := StrSplit(area, ",")
		left := Integer(Trim(args[1]))
		top := Integer(Trim(args[2]))
		width := Integer(Trim(args[3])) - left
		height := Integer(Trim(args[4])) - top
		if (args.Length == 6) {
			newWidth := Integer(Trim(args[5]))
			newHeight := Integer(Trim(args[6]))
		}
	}
	hDstDevice := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
	hBitmap := CreateDIBSection(hDstDevice, width, height)
	hBitmapObj := DllCall("SelectObject", "Ptr", hDstDevice, "Ptr", hBitmap, "Ptr")
	hSrcDevice := DllCall("GetDC", "Ptr", 0, "Ptr")
	DllCall("BitBlt", "Ptr", hDstDevice, "Int", 0, "Int", 0, "Int", width, "Int", height, "Ptr", hSrcDevice, "Int", left, "Int", top, "UInt", 0x40CC0020)
	DllCall("ReleaseDC", "Ptr", 0, "Ptr", hSrcDevice)
	if (includeCursor)
		CaptureCursor(hDstDevice, left, top)
	DllCall("SelectObject", "Ptr", hDstDevice, "Ptr", hBitmapObj)
	DllCall("DeleteDC", "Ptr", hDstDevice)
	if (newWidth && newHeight)
		hBitmap := Resize(hBitmap, width, height, newWidth, newHeight)
	if (savePath == 0)
		SetClipboardData(hBitmap)
	else {
		Convert(hBitmap, savePath, quality)
		DllCall("DeleteObject", "Ptr", hBitmap)
	}
}

CaptureCursor(hDevice, left, top) {
	length := 4 + 4 + A_PtrSize + 4 * 2
	cursorInfo := Buffer(length, 0)
	NumPut("UInt", length, cursorInfo)
	DllCall("GetCursorInfo", "Ptr", cursorInfo)
	flags := NumGet(cursorInfo, 4, "UInt")
	hCursor := NumGet(cursorInfo, 8, "UPtr")
	xCursor := NumGet(cursorInfo, 8 + A_PtrSize, "Int")
	yCursor := NumGet(cursorInfo, 12 + A_PtrSize, "Int")

	iconInfo := Buffer(4 * 3 + A_PtrSize * 2, 0)
	DllCall("GetIconInfo", "Ptr", hCursor, "Ptr", iconInfo)
	xHotspot := NumGet(iconInfo, 4, "UInt")
	yHotspot := NumGet(iconInfo, 8, "UInt")
	hbmMask := NumGet(iconInfo, 12, "UPtr")
	hbmColor := NumGet(iconInfo, 12 + A_PtrSize, "UPtr")

	if (flags & 1)
		DllCall("DrawIcon", "Ptr", hDevice, "Int", xCursor - xHotspot - left, "Int", yCursor - yHotspot - top, "Ptr", hCursor)
	if (hbmMask)
		DllCall("DeleteObject", "Ptr", hbmMask)
	if (hbmColor)
		DllCall("DeleteObject", "Ptr", hbmColor)
}

Resize(hBitmap, width, height, newWidth, newHeight) {
	hDC1 := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
	hDC2 := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
	hNewBitmap := CreateDIBSection(hDC2, newWidth, newHeight)
	hBM1 := DllCall("SelectObject", "Ptr", hDC1, "Ptr", hBitmap, "Ptr")
	hBM2 := DllCall("SelectObject", "Ptr", hDC2, "Ptr", hNewBitmap, "Ptr")
	DllCall("SetStretchBltMode", "Ptr", hDC2, "Int", 4)
	DllCall("StretchBlt", "Ptr", hDC2, "Int", 0, "Int", 0, "Int", newWidth, "Int", newHeight, "Ptr", hDC1, "Int", 0, "Int", 0, "Int", width, "Int", height, "UInt", 0x00CC0020)
	DllCall("SelectObject", "Ptr", hDC1, "Ptr", hBM1)
	DllCall("SelectObject", "Ptr", hDC2, "Ptr", hBM2)
	DllCall("DeleteDC", "Ptr", hDC1)
	DllCall("DeleteDC", "Ptr", hDC2)
	DllCall("DeleteObject", "Ptr", hBitmap)
	return hNewBitmap
}

Convert(savePathFr := "", savePathTo := "", quality := "") {
	if (savePathTo == "")
		savePathTo := A_ScriptDir "\screen.bmp"
	SplitPath(savePathTo, , &sDirTo, &sExtTo, &sNameTo)

	hGdiPlus := DllCall("LoadLibrary", "str", "gdiplus.dll", "Ptr")
	if (!hGdiPlus)
		return Integer(savePathFr) ? SaveHBITMAPToFile(savePathFr, sDirTo (sDirTo == "" ? "" : "\") sNameTo ".bmp") : ""
	token := 0
	startupInput := Buffer(4 + A_PtrSize + 4 + 4, 0)
	NumPut("UInt", 1, startupInput)
	DllCall("gdiplus\GdiplusStartup", "UInt*", &token, "Ptr", startupInput, "Ptr", 0)

	pImage := 0
	if (!savePathFr) {
		DllCall("OpenClipboard", "Ptr", 0)
		if (DllCall("IsClipboardFormatAvailable", "UInt", 2) && (hBM := DllCall("GetClipboardData", "UInt", 2, "Ptr")))
			DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "Ptr", hBM, "Ptr", 0, "Ptr*", &pImage)
		DllCall("CloseClipboard")
	}
	else if (savePathFr is Integer)
		DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "Ptr", savePathFr, "Ptr", 0, "Ptr*", &pImage)
	else
		DllCall("gdiplus\GdipLoadImageFromFile", "WStr", savePathFr, "Ptr*", &pImage)

	nCount := 0, nSize := 0
	DllCall("gdiplus\GdipGetImageEncodersSize", "UInt*", &nCount, "UInt*", &nSize)
	encoders := Buffer(nSize, 0)
	DllCall("gdiplus\GdipGetImageEncoders", "UInt", nCount, "UInt", nSize, "Ptr", encoders)
	structSize := 48 + 7 * A_PtrSize
	offset := 32 + 3 * A_PtrSize
	pCodec := encoders.Ptr
	loop (nCount) {
		ext := StrGet(NumGet(offset + pCodec, "UPtr"), "UTF-16")
		if (InStr(ext, "*." sExtTo))
			break
		pCodec += structSize
	}

	pParam := 0
	if (InStr(".JPG.JPEG.JPE.JFIF", "." sExtTo) && quality != "" && pImage && pCodec < encoders.Ptr + nSize) {
		DllCall("gdiplus\GdipGetEncoderParameterListSize", "Ptr", pImage, "Ptr", pCodec, "UInt*", &nCount)
		params := Buffer(nCount, 0)
		structSize := 24 + A_PtrSize
		DllCall("gdiplus\GdipGetEncoderParameterList", "Ptr", pImage, "Ptr", pCodec, "UInt", nCount, "Ptr", params)
		loop (NumGet(params, 0, "UInt")) {
			if (NumGet(params, structSize * (A_Index - 1) + 16 + A_PtrSize, "UInt") == 1 && NumGet(params, structSize * (A_Index - 1) + 20 + A_PtrSize, "UInt") == 6) {
				pParam := params.Ptr + structSize * (A_Index - 1)
				NumPut("UInt", quality, NumGet(NumPut("UInt", 4, NumPut("UInt", 1, pParam + 0) + 16 + A_PtrSize), "UPtr"))
				break
			}
		}
	}

	if (pImage) {
		if (pCodec < encoders.Ptr + nSize)
			DllCall("gdiplus\GdipSaveImageToFile", "Ptr", pImage, "WStr", savePathTo, "Ptr", pCodec, "Ptr", pParam)
		else {
			DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pImage, "Ptr*", &hBitmap, "UInt", 0)
			SetClipboardData(hBitmap)
			DllCall("gdiplus\GdipDisposeImage", "Ptr", pImage)
		}
	}
	DllCall("gdiplus\GdiplusShutdown", "UInt", token)
	DllCall("FreeLibrary", "Ptr", hGdiPlus)
}

CreateDIBSection(hDevice, width, height, bpp := 32, &pBits := 0) {
	bmInfo := Buffer(40, 0)
	NumPut("UInt", 40, "Int", width, "Int", height, "UShort", 1, "UShort", bpp, bmInfo, 0)
	return DllCall("gdi32\CreateDIBSection", "Ptr", hDevice, "Ptr", bmInfo, "UInt", 0, "Ptr*", &pBits, "Ptr", 0, "UInt", 0, "Ptr")
}

SaveHBITMAPToFile(hBitmap, savePath) {
	length := 64 + 5 * A_PtrSize
	obj := Buffer(length, 0)
	DllCall("GetObject", "Ptr", hBitmap, "Int", length, "Ptr", obj)
	saveFile := FileOpen(savePath, "w")
	saveFile.WriteShort(0x4D42)
	saveFile.WriteInt(54 + NumGet(obj, 36 + 2 * A_PtrSize, "UInt"))
	saveFile.WriteInt64(54 << 32)
	saveFile.RawWrite(obj.Ptr + 16 + 2 * A_PtrSize, 40)
	saveFile.RawWrite(NumGet(obj, 16 + A_PtrSize), NumGet(obj, 36 + 2 * A_PtrSize, "UInt"))
	saveFile.Close()
}

SetClipboardData(hBitmap) {
	length := 64 + 5 * A_PtrSize
	obj := Buffer(length, 0)
	DllCall("GetObject", "Ptr", hBitmap, "Int", length, "Ptr", obj)
	size := NumGet(obj, 36 + 2 * A_PtrSize, "UInt")
	hDIB := DllCall("GlobalAlloc", "UInt", 2, "UPtr", 40 + size, "Ptr")
	pDIB := DllCall("GlobalLock", "Ptr", hDIB, "Ptr")
	SIZE_T := A_PtrSize = 4 ? "UInt" : "UInt64"
	DllCall("RtlMoveMemory", "Ptr", pDIB, "Ptr", obj.Ptr + 16 + 2 * A_PtrSize, SIZE_T, 40)
	DllCall("RtlMoveMemory", "Ptr", pDIB + 40, "Ptr", NumGet(obj, 16 + A_PtrSize, "UPtr"), SIZE_T, size)
	DllCall("GlobalUnlock", "Ptr", hDIB)
	DllCall("DeleteObject", "Ptr", hBitmap)
	DllCall("OpenClipboard", "Ptr", 0)
	DllCall("EmptyClipboard")
	DllCall("SetClipboardData", "UInt", 8, "Ptr", hDIB)
	DllCall("CloseClipboard")
}
