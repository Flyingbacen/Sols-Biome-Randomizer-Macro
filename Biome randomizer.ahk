#Requires AutoHotkey v2.0
#SingleInstance Force
#Include OCR.ahk
#Include CaptureScreen.ahk
#Include CreateFormData.ahk
FileInstall('OCR.ahk', A_Temp '\AHK_SOLS_OCR.ahk', 1)
FileInstall('CaptureScreen.ahk', A_Temp '\AHK_CAPTURE_SCREEN.ahk', 1)
FileInstall('CreateFormData.ahk', A_Temp '\UPLOAD_HELPER.ahk', 1)
SendMode('Event')
OnExit(OnGuiClose)

IniFile := A_ScriptDir "\settings.ini"
; -- UI / inventory coords
RectangleTopX := IniRead(IniFile, "Inventory Coordinates", "RectangleTopX", 805)
RectangleTopY := IniRead(IniFile, "Inventory Coordinates", "RectangleTopY", 424)
RectangleWidth := IniRead(IniFile, "Inventory Coordinates", "RectangleWidth", 90)
RectangleHeight := IniRead(IniFile, "Inventory Coordinates", "RectangleHeight", 90)
RectangleMidX := RectangleTopX + (RectangleWidth // 2)
RectangleMidY := RectangleTopY + (RectangleHeight // 2)

UseButtonX := IniRead(IniFile, "Inventory Coordinates", "UseButtonX", 683)
UseButtonY := IniRead(IniFile, "Inventory Coordinates", "UseButtonY", 580)

SearchX := IniRead(IniFile, "Inventory Coordinates", "SearchX", 876)
SearchY := IniRead(IniFile, "Inventory Coordinates", "SearchY", 360)

InventoryX := IniRead(IniFile, "Inventory Coordinates", "InventoryX", 32)
InventoryY := IniRead(IniFile, "Inventory Coordinates", "InventoryY", 507)

InventoryItemsX := IniRead(IniFile, "Inventory Coordinates", "InventoryItemsX", 1268)
InventoryItemsY := IniRead(IniFile, "Inventory Coordinates", "InventoryItemsY", 330)

CraftCloseX := IniRead(IniFile, "Crafting", "CraftCloseX", 1850)
CraftCloseY := IniRead(IniFile, "Crafting", "CraftCloseY", 180)
OpenRecipeMenuX := IniRead(IniFile, "Crafting", "OpenRecipeMenuX", 229)
OpenRecipeMenuY := IniRead(IniFile, "Crafting", "OpenRecipeMenuY", 825)
CraftButtonX := IniRead(IniFile, "Crafting", "CraftButtonX", 1079)
CraftButtonY := IniRead(IniFile, "Crafting", "CraftButtonY", 686)
MerchantDialogueSkipX := IniRead(IniFile, "Inventory Coordinates", "MerchantDialogueSkipX", 948)
MerchantDialogueSkipY := IniRead(IniFile, "Inventory Coordinates", "MerchantDialogueSkipY", 837)
MerchantDialogueLeftX := IniRead(IniFile, "Inventory Coordinates", "MerchantDialogueLeftX", 778)
MerchantDialogueLeftY := IniRead(IniFile, "Inventory Coordinates", "MerchantDialogueLeftY", 912)

HPScrolls := IniRead(IniFile, "Crafting\Heavenly", "HPScrolls", 10)
HPCraftMenuX := IniRead(IniFile, "Crafting\Heavenly", "HPCraftMenuX", 1600)
HPCraftMenuY := IniRead(IniFile, "Crafting\Heavenly", "HPCraftMenuY", 664)
HPLuckyPotionsAmountX := IniRead(IniFile, "Crafting\Heavenly", "HPLuckyPotionsAmountX", 1047)
HPLuckyPotionsAmountY := IniRead(IniFile, "Crafting\Heavenly", "HPLuckyPotionsAmountY", 431)
HPLuckyPotionsAmount := IniRead(IniFile, "Crafting\Heavenly", "HPLuckyPotionsAmount", 250)
HPLuckyPotionsAddX := IniRead(IniFile, "Crafting\Heavenly", "HPLuckyPotionsAddX", 1130)
HPLuckyPotionsAddY := IniRead(IniFile, "Crafting\Heavenly", "HPLuckyPotionsAddY", 431)
HPCelestialAddX := IniRead(IniFile, "Crafting\Heavenly", "HPCelestialAddX", 1130)
HPCelestialAddY := IniRead(IniFile, "Crafting\Heavenly", "HPCelestialAddY", 486)
HPExoticAddX := IniRead(IniFile, "Crafting\Heavenly", "HPExoticAddX", 1130)
HPExoticAddY := IniRead(IniFile, "Crafting\Heavenly", "HPExoticAddY", 537)
BypassCraftClose := IniRead(IniFile, "Toggles", "BypassCraftClose", "false") == "true" ? true : false

DiscordWebhookURL := IniRead(IniFile, "Discord Webhook", "DiscordWebhookURL", "")
DiscordUserID := IniRead(IniFile, "Discord Webhook", "DiscordUserID", "")

BiomeRandomizerEnabled := IniRead(IniFile, "Toggles", "BiomeRandomizerEnabled", "true") == "true" ? true : false
StrangeControllerEnabled := IniRead(IniFile, "Toggles", "StrangeControllerEnabled", "true") == "true" ? true : false
IgnoreOCR := IniRead(IniFile, "Toggles", "IgnoreOCR", "false") == "true" ? true : false

; -- cooldowns
BiomeRandomizerCooldownMinutes := IniRead(IniFile, "Cooldowns", "BiomeRandomizerCooldownMinutes", 35.2)
StrangeControllerCooldownMinutes := IniRead(IniFile, "Cooldowns", "StrangeControllerCooldownMinutes", 20.2)
AFKIntervalMinutes := IniRead(IniFile, "Cooldowns", "AFKIntervalMinutes", 10)

; -- Convert to milliseconds
BiomeCooldownMs := BiomeRandomizerCooldownMinutes * 60 * 1000
StrangeCooldownMs := StrangeControllerCooldownMinutes * 60 * 1000
AFKIntervalMs := AFKIntervalMinutes * 60 * 1000

; -- Scheduler / state
lastUsedBiome := 0
lastUsedStrange := 0
lastAFK := 0

SchedulerIntervalMs := 1000

; -- AFK target window (default empty). Set to Roblox to automatically run whenever it's opened.
; -- (May not work properly with multi-instancing)
TargetWindow := "Roblox"

; -- GUI controls (will be created below)
BiomeRandomizerGUI := Gui()
BiomeRandomizerGUI.MarginX := 8
BiomeRandomizerGUI.MarginY := 8

; Labels showing remaining time
lblBiome := BiomeRandomizerGUI.Add("Text", "w300", "Biome Randomizer: --:--")
lblStrange := BiomeRandomizerGUI.Add("Text", "w300", "Strange Controller: --:--")
lblAFK := BiomeRandomizerGUI.Add("Text", "w300", "AFK action: --:--")
BiomeRandomizerGUI.Add("Text", "h10") ; spacer

; Controls for AFK target
BiomeRandomizerGUI.Add("Text", "", "AFK target (window HWND or title):")
edtTarget := BiomeRandomizerGUI.Add("Edit", "w300 vEdtTarget")
btnApplyTextTarget := BiomeRandomizerGUI.Add("Button", "w140", "Apply text as HWND/title")
btnApplyTextTarget.OnEvent("Click", ApplyTextTarget)
btnUseActive := BiomeRandomizerGUI.Add("Button", "w140", "Ctrl+Click = active window")
btnUseActive.OnEvent("Click", SetTargetFromActive)
BiomeRandomizerGUI.Add("Text", "h10") ; spacer

; Action buttons
btnToggle := BiomeRandomizerGUI.Add("Button", "w80", "Toggle Active")
btnToggle.OnEvent("Click", ToggleScheduler)
btnForceAFK := BiomeRandomizerGUI.Add("Button", "w80", "Force AFK")
btnForceAFK.OnEvent("Click", ForceAFK)
btnForceBiome := BiomeRandomizerGUI.Add("Button", "w120", "Force Biome Use")
btnForceBiome.OnEvent("Click", ForceBiome)
btnToggleBiome := BiomeRandomizerGUI.Add("Button", "x+10", "Toggle Biome Use")
btnToggleBiome.OnEvent("Click", ToggleBiomeRandomizer)
btnForceStrange := BiomeRandomizerGUI.Add("Button", "xp-130 y+m w120", "Force Strange Use")
btnForceStrange.OnEvent("Click", ForceStrange)
btnToggleStrange := BiomeRandomizerGUI.Add("Button", "x+10", "Toggle Strange Use")
btnToggleStrange.OnEvent("Click", ToggleStrangeController)

; Status
BiomeRandomizerGUI.Add("Text", "h6")
lblStatus := BiomeRandomizerGUI.Add("Text", "xp-130 w300", "Status: stopped")

BiomeRandomizerGUI.OnEvent("Close", OnGuiClose)

BiomeRandomizerGUI.Show()

; Timer flags
SchedulerRunning := false
UpdateGuiTimerRunning := false

StartGuiUpdater()

return


/**
 * Toggles whether or not it does stuff
 */
ToggleScheduler(*) {
    global SchedulerRunning, SchedulerIntervalMs, lblStatus
    if (SchedulerRunning) {
        SetTimer(Scheduler, 0)
        SchedulerRunning := false
        lblStatus.Text := "Status: stopped"
    } else {
        SetTimer(Scheduler, SchedulerIntervalMs)
        SchedulerRunning := true
        lblStatus.Text := "Status: running"
    }
}

ToggleBiomeRandomizer(*) {
    global BiomeRandomizerEnabled
    BiomeRandomizerEnabled := !BiomeRandomizerEnabled
}

ToggleStrangeController(*) {
    global StrangeControllerEnabled
    StrangeControllerEnabled := !StrangeControllerEnabled
}

StartGuiUpdater() {
    global UpdateGuiTimerRunning
    if (!UpdateGuiTimerRunning) {
        SetTimer(UpdateGui, 1000)
        UpdateGuiTimerRunning := true
    }
}

OnGuiClose(*) {
    global IniFile
    IniWrite(RectangleTopX, IniFile, "Inventory Coordinates", "RectangleTopX")
    IniWrite(RectangleTopY, IniFile, "Inventory Coordinates", "RectangleTopY")
    IniWrite(RectangleWidth, IniFile, "Inventory Coordinates", "RectangleWidth")
    IniWrite(RectangleHeight, IniFile, "Inventory Coordinates", "RectangleHeight")
    IniWrite(UseButtonX, IniFile, "Inventory Coordinates", "UseButtonX")
    IniWrite(UseButtonY, IniFile, "Inventory Coordinates", "UseButtonY")
    IniWrite(SearchX, IniFile, "Inventory Coordinates", "SearchX")
    IniWrite(SearchY, IniFile, "Inventory Coordinates", "SearchY")
    IniWrite(InventoryX, IniFile, "Inventory Coordinates", "InventoryX")
    IniWrite(InventoryY, IniFile, "Inventory Coordinates", "InventoryY")
    IniWrite(InventoryItemsX, IniFile, "Inventory Coordinates", "InventoryItemsX")
    IniWrite(InventoryItemsY, IniFile, "Inventory Coordinates", "InventoryItemsY")
    IniWrite(MerchantDialogueSkipX, IniFile, "Inventory Coordinates", "MerchantDialogueSkipX")
    IniWrite(MerchantDialogueSkipY, IniFile, "Inventory Coordinates", "MerchantDialogueSkipY")
    IniWrite(MerchantDialogueLeftX, IniFile, "Inventory Coordinates", "MerchantDialogueLeftX")
    IniWrite(MerchantDialogueLeftY, IniFile, "Inventory Coordinates", "MerchantDialogueLeftY")

    IniWrite(CraftCloseX, IniFile, "Crafting", "CraftCloseX")
    IniWrite(CraftCloseY, IniFile, "Crafting", "CraftCloseY")
    IniWrite(OpenRecipeMenuX, IniFile, "Crafting", "OpenRecipeMenuX")
    IniWrite(OpenRecipeMenuY, IniFile, "Crafting", "OpenRecipeMenuY")
    IniWrite(CraftButtonX, IniFile, "Crafting", "CraftButtonX")
    IniWrite(CraftButtonY, IniFile, "Crafting", "CraftButtonY")
    IniWrite(HPScrolls, IniFile, "Crafting\Heavenly", "Scrolls")
    IniWrite(HPCraftMenuX, IniFile, "Crafting\Heavenly", "HeavenlyCraftMenuX")
    IniWrite(HPCraftMenuY, IniFile, "Crafting\Heavenly", "HeavenlyCraftMenuY")
    IniWrite(HPLuckyPotionsAmountX, IniFile, "Crafting\Heavenly", "HPLuckyPotionsAmountX")
    IniWrite(HPLuckyPotionsAmountY, IniFile, "Crafting\Heavenly", "HPLuckyPotionsAmountY")
    IniWrite(HPLuckyPotionsAmount, IniFile, "Crafting\Heavenly", "HPLuckyPotionsAmount")
    IniWrite(HPLuckyPotionsAddX, IniFile, "Crafting\Heavenly", "HPLuckyPotionsAddX")
    IniWrite(HPLuckyPotionsAddY, IniFile, "Crafting\Heavenly", "HPLuckyPotionsAddY")
    IniWrite(HPCelestialAddX, IniFile, "Crafting\Heavenly", "HPCelestialAddX")
    IniWrite(HPCelestialAddY, IniFile, "Crafting\Heavenly", "HPCelestialAddY")
    IniWrite(HPExoticAddX, IniFile, "Crafting\Heavenly", "HPExoticAddX")
    IniWrite(HPExoticAddY, IniFile, "Crafting\Heavenly", "HPExoticAddY")


    IniWrite(BypassCraftClose ? "true" : "false", IniFile, "Toggles", "BypassCraftClose")
    IniWrite(BiomeRandomizerEnabled ? "true" : "false", IniFile, "Toggles", "BiomeRandomizerEnabled")
    IniWrite(StrangeControllerEnabled ? "true" : "false", IniFile, "Toggles", "StrangeControllerEnabled")
    IniWrite(IgnoreOCR ? "true" : "false", IniFile, "Toggles", "IgnoreOCR")

    IniWrite(BiomeRandomizerCooldownMinutes, IniFile, "Cooldowns", "BiomeRandomizerCooldownMinutes")
    IniWrite(StrangeControllerCooldownMinutes, IniFile, "Cooldowns", "StrangeControllerCooldownMinutes")
    IniWrite(AFKIntervalMinutes, IniFile, "Cooldowns", "AFKIntervalMinutes")

    IniWrite(DiscordWebhookURL, IniFile, "Discord Webhook", "DiscordWebhookURL")
    IniWrite(DiscordUserID, IniFile, "Discord Webhook", "DiscordUserID")


    SetTimer(Scheduler, 0)
    SetTimer(UpdateGui, 0)
    ExitApp()
}

UpdateGui() {
    global lastUsedBiome, lastUsedStrange, lastAFK
    global BiomeCooldownMs, StrangeCooldownMs, AFKIntervalMs
    global lblBiome, lblStrange, lblAFK, edtTarget

    now := A_TickCount

    nextBiome := lastUsedBiome + BiomeCooldownMs
    nextStrange := lastUsedStrange + StrangeCooldownMs
    nextAFK := lastAFK + AFKIntervalMs

    lblBiome.Text := "Biome Randomizer: " . (BiomeRandomizerEnabled ? FormatRemaining(nextBiome - now) : "Disabled")
    lblStrange.Text := "Strange Controller: " . (StrangeControllerEnabled ? FormatRemaining(nextStrange - now) : "Disabled")
    lblAFK.Text := "AFK action: " . FormatRemaining(nextAFK - now)

    if (TargetWindow) {
        edtTarget.Value := TargetWindow
    }
}

/**
 * @param {Integer} ms 
 * @returns {String} display MM:SS or "Ready"
 */
FormatRemaining(ms) {
    if (ms <= 0)
        return "Ready"
    s := Ceil(ms / 1000)
    m := Floor(s / 60)
    r := s - m * 60
    return Format("{:02}:{:02}", m, r)
}

ForceAFK(*) {
    global lastAFK
    DoAFK()
    lastAFK := A_TickCount
}

ForceBiome(*) {
    global lastUsedBiome
    if (UseItem("Biome Randomizer"))
        lastUsedBiome := A_TickCount
}

ForceStrange(*) {
    global lastUsedStrange
    if (UseItem("Strange Controller"))
        lastUsedStrange := A_TickCount
}

; ---------------------
; Setting AFK target
; ---------------------
SetTargetFromActive(*) {
    global TargetWindow, edtTarget
    ; Ctrl+click
    while !(GetKeyState("Ctrl", "P") && GetKeyState("LButton", "P")) {
        Sleep(10)
    }
    MouseGetPos(, , &WindowUnderCursor) ; HWND of window under cursor
    if (WindowUnderCursor) {
        TargetWindow := WindowUnderCursor
        edtTarget.Value := TargetWindow
        TrayTip("AFK Target", "Target window HWND: " . TargetWindow . " with window title: " . WinGetTitle("ahk_id " TargetWindow), 2)
        WinActivate("ahk_id " BiomeRandomizerGUI.Hwnd)
    } else {
        TrayTip("AFK Target", "No window found under cursor", 2)
    }
}

ApplyTextTarget(*) {
    global TargetWindow, edtTarget
    val := edtTarget.Value
    if (val) {
        TargetWindow := val
        TrayTip("AFK Target", "Target set to: " . TargetWindow, 2)
    } else {
        TrayTip("AFK Target", "No target text provided", 2)
    }
}

; ---------------------
; Scheduler
; ---------------------
Scheduler() {
    global lastUsedBiome, lastUsedStrange, lastAFK
    global BiomeCooldownMs, StrangeCooldownMs, AFKIntervalMs

    ; Prevent re-entrancy: stop the timer while running
    SetTimer(Scheduler, 0)
    try {
        now := A_TickCount

        if ((now - lastAFK) >= AFKIntervalMs) {
            OutputDebug("Scheduler: performing AFK")
            if (DoAFK()) {
                lastAFK := A_TickCount
            }
            SetTimer(Scheduler, SchedulerIntervalMs)
            return
        }

        biomeReady := (now - lastUsedBiome) >= BiomeCooldownMs
        strangeReady := (now - lastUsedStrange) >= StrangeCooldownMs

        if (biomeReady && strangeReady) {
            ; both ready -> use Biome Randomizer first
            OutputDebug("Both ready: using Biome first then Strange")
            if (UseItem("Strange Controller")) {
                lastUsedBiome := A_TickCount
                Sleep(500)
                if (UseItem("Biome Randomizer"))
                    lastUsedStrange := A_TickCount
            } else {
                if (UseItem("Biome Randomizer"))
                    lastUsedStrange := A_TickCount
            }
        }
        else if (biomeReady) {
            OutputDebug("Using Biome Randomizer")
            if (UseItem("Biome Randomizer"))
                lastUsedBiome := A_TickCount
        }
        else if (strangeReady) {
            OutputDebug("Using Strange Controller")
            if (UseItem("Strange Controller"))
                lastUsedStrange := A_TickCount
        }
    } catch as e {
        MsgBox("Scheduler error: " e.Message " at line " e.Line)
    }
    SetTimer(Scheduler, SchedulerIntervalMs)
}

/**
 * Clicks on the confirm spot—mainly for Eden—and also jumps/presses E thrice
 * @returns {Boolean} 
 */
DoAFK() {
    global TargetWindow

    ; If no target specified, try to use the active window -- shouldn't happen unless you Force AFK before setting Target
    if (!TargetWindow) {
        TargetWindow := WinGetID("A")
    }

    CurrentWindow := WinGetID("A")
    ; If TargetWindow is a HWND string, use it; otherwise try to search by title
    tQuery := (RegExMatch(TargetWindow, "^\d+$") ? "ahk_id " . TargetWindow : TargetWindow)

    if (!WinExist(tQuery)) {
        MsgBox("Window not Found", "Error", "IconX")
        ToolTip()
        return false
    }

    WinActivate(tQuery)
    Sleep(150)

    Send("{Space 3}")
    Sleep(50)
    Send("{e 3}")
    Sleep(50)
	Send("{f 3}")
    Sleep(50)


    SetTimer(CheckEden, -5000)
    if GetKeyState("RButton", "P")
        MouseClick("Right",,,,,"U")
    ; WinGetPos(&WindowX, &WindowY, &Width, &Height, tQuery)
    MouseGetPos(&MouseX, &MouseY)
    ; Move to coords for Eden button (hopefully)
    ; Eden coords: 778, 912
    ; craft potion coords: 578, 578
    MouseMove(778, 912, 3)
    Click()
    MouseMove(MouseX, MouseY, 3) ; move back to original position

    ; Reactivate previous window if it still exists
    if (WinExist("ahk_id " . CurrentWindow)) {
        WinActivate("ahk_id " . CurrentWindow)
    }
    OutputDebug("DoAFK completed on target: " . tQuery)
    return true
}

CheckEden() {
    global TargetWindow

    tQuery := (RegExMatch(TargetWindow, "^\d+$") ? "ahk_id " . TargetWindow : TargetWindow)

    ; Adjust the coordinates dynamically based on the window's position and size
    WinGetPos(&WindowX, &WindowY, &WindowWidth, &WindowHeight, tQuery)
    
    ; Calculate the adjusted coordinates for the OCR rectangle
    AdjustedTopX := WindowX + RectangleTopX
    AdjustedTopY := WindowY + RectangleTopY
    
    results := OCR.FromWindow(tQuery, {lang: "en-US", scale: 2, grayscale: true, invertcolors: true}).Text

    OutputDebug("OCR text: " . results)
    if (InStr(StrLower(results), "eden") || InStr(StrLower(results), "contract") || FuzzySearch(results, "contract", false) <= 3) {
        WinActivate(tQuery)
        loop 10 {
            MouseClick(, MerchantDialogueSkipX, MerchantDialogueSkipY, 10, 5)
            MouseClick(, MerchantDialogueLeftX, MerchantDialogueLeftY, 10, 5)
            Sleep(1000)
        }
        outfile := A_ScriptDir "\Eden_" A_TickCount ".png"
        CaptureScreen(1, false, outfile,, tQuery)
        ImageUrl := CatboxUpload(outfile)

        if (DiscordWebhookURL) {
            DiscordWebhook("Eden Detection detected", ImageUrl)
        }

    }
}

/**
 * 
 * @param Text Custom text to send with the webhook
 * @param image The image link to use to embed
 */
DiscordWebhook(Text := "", image := "https://cdn.discordapp.com/embed/avatars/0.png") {
    url := DiscordWebhookURL ; use the url from Discord webhook bot
    postdata := Format( ; Format "requires" using {{} to insert a literal curly brace
    (
        "{{}
            `"content`": `"<@{1}>`",
            `"embeds`": [
                {{}
                    `"title`": `"{2}`",
                    `"color`": 986895,
                    `"timestamp`": `"{3}`", 
                    `"image`": {{}
                        `"url`": `"{4}`"
                    {}}
                {}}
            ]
        {}}"
    ), DiscordUserID, Text, FormatTime(A_NowUTC, "yyyy'-'MM'-'dd'T'HH:mm:ss'.000Z'"), image) ; Use https://leovoel.github.io/embed-visualizer/ to generate above webhook code

    WebRequest := ComObject("WinHttp.WinHttpRequest.5.1")
    WebRequest.Open("POST", url, false)
    WebRequest.SetRequestHeader("Content-Type", "application/json")
    WebRequest.Send(postdata)
}

CatboxUpload(filepath := "C:\Users\Aster\Pictures\BLOT!!!!\bath time.jfif") {
    ; Param := {reqtype: "fileupload", fileToUpload: [filepath]}
    Param := Map(
        "reqtype", "fileupload",
        "fileToUpload", [filepath]
    )
    CreateFormData(&PostData, &retHeader, Param)

    WebRequest := ComObject("WinHttp.WinHttpRequest.5.1")
    WebRequest.Open("POST", "https://catbox.moe/user/api.php", false)
    WebRequest.SetRequestHeader("Content-Type", retHeader)
    WebRequest.SetRequestHeader("Pragma", "no-cache")
    WebRequest.SetRequestHeader("Cache-Control", "no-cache, no-store")
    WebRequest.Send(PostData)
    WebRequest.WaitForResponse()
    ; MsgBox(WebRequest.ResponseText)
    A_Clipboard := WebRequest.ResponseText
    return WebRequest.ResponseText
}



/**
 * @param {String} Item Item to use
 */
UseItem(Item) {
    global RectangleTopX, RectangleTopY, RectangleWidth, RectangleHeight
    global RectangleMidX, RectangleMidY, UseButtonX, UseButtonY
    global InventoryX, InventoryY, InventoryItemsX, InventoryItemsY, SearchX, SearchY
    global TargetWindow, StrangeControllerEnabled, BiomeRandomizerEnabled

    if (Item = "Strange Controller") {
        if (!StrangeControllerEnabled) {
            ; MsgBox(FormatTime(DateAdd(A_Now, -5, "Hours"), "yyyy'-'MM'-'dd'T'HH:mm:ss'z'"))
            ; outfile := A_ScriptDir "\Eden_" A_TickCount ".png"
            ; CaptureScreen(1, false, outfile,, "Roblox")
            ; DiscordWebhook("manually testing webhook", CatboxUpload(outfile))
            return false ; Will cause this to run every second, but it's better than just resetting the timer
        }
    } else if (Item = "Biome Randomizer") {
        if (!BiomeRandomizerEnabled) {
            return false ; ^^^
        }
    }

    ; If no target specified, try to use the active window
    if (!TargetWindow) {
        TargetWindow := WinGetID("A")
    }
    
    CurrentWindow := WinGetID("A")
    ; If TargetWindow is a HWND string, use it; otherwise try to search by title
    tQuery := (RegExMatch(TargetWindow, "^\d+$") ? "ahk_id " . TargetWindow : TargetWindow)
    
    if (!WinExist(tQuery)) {
        MsgBox("Window not Found", "Error", "IconX")
        ToolTip()
        return false
    }
    
    WinActivate(tQuery)
    Sleep(150)
    Crafting := false
    CraftingHeavenly := false
    ; if we're in a crafting menu, close it
    if (PixelGetColor(1850, 180) == "0xFFFFFF" || BypassCraftClose) {
        ; the position of the close button
        ; This button doesn't exist if using MultiScope merchant fix, in which case bypasses based on ini settings
        if (PixelGetColor(248, 592) == "0xFF98DC") {
            ; crafting a heavenly based on the buff, scroll down to it and open it's recipe when we're done
            CraftingHeavenly := true
        }

        MouseClick("left", CraftCloseX, CraftCloseY,, 5)
        Sleep(500)
        Crafting := true
    }

    MouseClick("left", InventoryX, InventoryY,, 5)
    Sleep(200)
    MouseClick("left", InventoryItemsX, InventoryItemsY,, 5)
    Sleep(200)
    MouseClick("left", SearchX, SearchY,, 5)
    Sleep(200)
    A_Clipboard := Item
    Send("^v") ; more consistent + faster
    Sleep(300)
    
    ; Adjust the coordinates dynamically based on the window's position and size
    WinGetPos(&WindowX, &WindowY, &WindowWidth, &WindowHeight, tQuery)
    
    ; Calculate the adjusted coordinates for the OCR rectangle
    AdjustedTopX := WindowX + RectangleTopX
    AdjustedTopY := WindowY + RectangleTopY
    
    if (!IgnoreOCR) {
        results := OCR.FromRect(AdjustedTopX, AdjustedTopY, RectangleWidth, RectangleHeight, {lang: "en-US", invertcolors: true, grayscale: true}).Text
        OutputDebug("OCR text: " . results)
        if (results = "") {
            Return False
        }
        results := Trim(StrSplit(results, "x")[1]) ; sometimes recognizes the amount.
    }
    ; If exact or fuzzy match is found
    if (IgnoreOCR || FuzzySearch(results, Item, false) <= 3) {
        MouseClick("left", RectangleMidX, RectangleMidY,, 5)
        Sleep(200)
        MouseClick("left", UseButtonX, UseButtonY,, 5)
        Sleep(300)
        MouseClick("left", InventoryX, InventoryY,, 5)
        
        if Crafting { 
            ; only works for mari's cauldron
            Send("f")
            Sleep(500)
            if CraftingHeavenly {
                MouseClick("left", Integer(A_ScreenWidth / 1.2), A_ScreenHeight // 2,, 5) ; crafting menu
                Send("{WheelDown 10}")
                MouseClick("left", HPCraftMenuX, HPCraftMenuY,, 5) ; heavenly potion
                MouseClick("left", OpenRecipeMenuX, OpenRecipeMenuY,, 5) ; open recipe menu

                MouseClick("left", HPLuckyPotionsAmountX, HPLuckyPotionsAmountY,, 5) ; attempt to add lucky potions
                Send("^a")
				Send(String(HPLuckyPotionsAmount))
                MouseClick("left", HPLuckyPotionsAddX, HPLuckyPotionsAddY,, 5) ; add potions

                loop 2 {
                    MouseClick("left", HPCelestialAddX, HPCelestialAddY,, 5) ; add celestial
                    Sleep 100
                }

                MouseClick("left", HPExoticAddX, HPExoticAddY,, 5) ; add exotic

                MouseClick("left", CraftButtonX, CraftButtonY,, 5) ; attempt to craft it
            }
        }

        ; Reactivate previous window if it still exists
        if (WinExist("ahk_id " . CurrentWindow)) {
            WinActivate("ahk_id " . CurrentWindow)
        }

        return true
    }

    ; Not found / not used, close inventory
    MouseClick("left", InventoryX, InventoryY,, 5)
    ; Reactivate previous window if it still exists
    if (WinExist("ahk_id " . CurrentWindow)) {
        WinActivate("ahk_id " . CurrentWindow)
    }
    return false
}

/**
 * FuzzySearch (Levenshtein) <br>
 * Credits: iPhilip, Source: https://www.autohotkey.com/boards/viewtopic.php?style=17&p=509167#p509167 <br>
 * [Wikipedia page](https://en.wikipedia.org/wiki/Levenshtein_distance#Iterative_with_two_matrix_rows) <br>
 * Grabbed from [OCR library Github example](https://github.com/Descolada/OCR/blob/15154d1477eb21ade15dc82a62594053face757f/Examples/Example9_FuzzyMatching.ahk)
 * @param {String} Source Original text
 * @param {String} Target Text you want to reach
 * @param {Boolean} CaseSense Whether capitals are ignored or not
 * @returns {Integer} How many modifications need to be made to reach Target from Source 
 */
FuzzySearch(Source, Target, CaseSense := True) {
    if CaseSense ? Source == Target : Source = Target
        return 0
    Source := StrSplit(Source)
    Target := StrSplit(Target)
    if !Source.Length
        return Target.Length
    if !Target.Length
        return Source.Length

    v0 := [], v1 := []
    Loop Target.Length + 1
        v0.Push(A_Index - 1)
    v1.Length := v0.Length

    for Index, SourceChar in Source {
        v1[1] := Index
        for TargetChar in Target
            v1[A_Index + 1] := Min(v1[A_Index] + 1, v0[A_Index + 1] + 1, v0[A_Index] + (CaseSense ? SourceChar !== TargetChar : SourceChar != TargetChar))
        Loop Target.Length + 1
            v0[A_Index] := v1[A_Index]
    }
    return v1[Target.Length + 1]
}

#SuspendExempt true
f12::ExitApp