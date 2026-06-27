# Screen Layouts — Extracted from Figma (Binance UI Kit)

> All screens: **375×667** (iPhone SE)  
> Safe area top: 84px (status bar + menu)  
> Safe area bottom: 60px (bottom bar)  
> Content area: 375×523

---

## 1. EMPTY WALLET (No wallet connected)

```
┌──────────────────────────────┐  y=0
│  Menu (Status bar)          │  h=84
│  ...9:41... [wifi][batt]   │
├──────────────────────────────┤ y=84
│                              │
│         ┌─────────┐         │ y=101
│         │  LOGO   │         │ 205w × 172h
│         │ 92×106  │         │ (centered)
│         │  Word   │         │
│         │ 205×30  │         │
│         └─────────┘         │ y=273
│                              │
│    No Wallet Is Connect      │ y=335 (295×28, Poppins 28px w600, #1E2329)
│                              │
│  Import an existing wallet   │ y=375 (207×44, Poppins 16px w300, #5C5F64)
│   or create a new wallet     │
│                              │
│  ┌──────────────────────┐   │ y=453
│  │  Create a New Wallet  │   │ 335×50, r=12, bg=#FCD535
│  └──────────────────────┘   │
│                              │
│  ┌──────────────────────┐   │ y=515
│  │Import Using seed phrase│  │ 335×50, r=12, bg=#EAECEF
│  └──────────────────────┘   │
│                              │
│  By processing, you agree to │ y=599 (207×28, Poppins 12px w500, #A5ABB6)
│  the Terms of use...         │
├──────────────────────────────┤ y=607
│  Bottom Bar (not shown)     │
└──────────────────────────────┘ y=667
```

### spacing
- Logo center: y=101 (84+17)
- "No Wallet Is Connect": y=335 (251px below logo)
- "Import an existing...": y=375 (40px below title)
- "Create" button: y=453 (78px below text)
- "Import" button: y=515 (62px below)
- Terms text: y=599 (84px below import)
- Bottom bar starts at: y=607

---

## 2. WALLET WITH CARD (Main Screen)

```
┌──────────────────────────────┐ y=0
│  Menu (Status bar)          │ h=84
├──────────────────────────────┤ y=84
│  [←]           [+ Wallet]   │ y=100 (header)
│                              │
│  ┌──────────────────────┐   │ y=144
│  │      9.23456 BNB      │   │ Card 335×160
│  │      ~ 16,234.56      │   │ bg=#FFFFFF, r=12
│  │  0x64368d...   [copy] │   │
│  └──────────────────────┘   │ y=304
│                              │
│  [Send]  [Receive]  [Buy]   │ y=320 (3 buttons, 105×40 each, r=12)
│                              │
│  [↓] Binance Smart Chain    │ y=376 (dropdown 197×20)
│                              │
│  Assets    History           │ y=416 (Tabs 162×25)
│  ───────                    │
│                              │
│  [BTC icon]  Bitcoin (BTC)  │ y=452 (token row)
│              0.0000         │
│  [ETH icon]  Ethereum (ETH) │ y=492
│              1.234          │
│  [USDT icon] Tether (USDT)  │ y=532
│              1000.00        │
│                              │
│  [+] Add Tokens             │ y=580 (blue text #236FE9)
│                              │
├──────────────────────────────┤ y=607
│  Bottom Bar 355×60          │
│ [wallet][set][browse][stck][exch]│
└──────────────────────────────┘ y=667
```

### spacing
- Card: y=144 (60px below menu)
- 3 action buttons: y=320 (16px below card), each 105×40, r=12, bg=#FCD535
  - "Send" button: icon + "Send"
  - "Receive" button: icon + "Receive"
  - "Buy" button: icon + "Buy"
- Dropdown: y=376 (16px below buttons)
- Tabs: y=416 (20px below dropdown)
- First token row: y=452 (16px below tabs)
- Token row height: 40px each
- "Add Tokens": y=580 (blue)

---

## 3. CREATE PASSWORD (Step 1)

```
┌──────────────────────────────┐ y=0
│  Menu (Status bar)          │ h=84
├──────────────────────────────┤ y=84
│                              │
│  [←]                        │ y=92 (back arrow 20×20)
│                              │
│  ○ ── ○ ── ○                │ y=130 (Step indicator 335×20)
│  01   02   03               │ (Step1: active dot 1)
│                              │
│  Create password             │ y=160 (175×20, Poppins 20px w600)
│                              │
│  This password will unlock   │ y=190 (250×44, Poppins 16px w300, #5C5F64)
│  your wallet only on...      │
│                              │
│  New Password                │ y=250 (label 14px w500)
│  ┌──────────────────────┐   │ y=272
│  │  .................... │   │ Input 335×56
│  │              [Paste]  │   │ border=#D7D7D7, r=12, eye icon
│  └──────────────────────┘   │ y=328
│                              │
│  Confirm Password            │ y=360 (label 14px w500)
│  ┌──────────────────────┐   │ y=382
│  │  .................... │   │ Input 335×56
│  │              [Paste]  │   │ border=#D7D7D7, r=12, eye icon
│  └──────────────────────┘   │ y=438
│                              │
│  ☐ I saved my password       │ y=490 (checkbox 20×20 + text)
│                              │
│  ┌──────────────────────┐   │ y=530
│  │  Create a New Wallet  │   │ 335×50, r=12 (disabled=opacity 0.5)
│  └──────────────────────┘   │
│                              │
└──────────────────────────────┘ y=667
```

### spacing (create password)
- Page starts at y=84 (after menu)
- Back arrow: y=8 from top
- Step indicator: y=46 
- Title: y=76 (30px below step)
- Description: y=106 (30px below title)
- Input 1 label: y=166
- Input 1 field: y=188
- Input 2 label: y=276
- Input 2 field: y=298
- Checkbox: y=406
- Button: y=446

---

## 4. SELECT TOKEN (Exchange/Swap)

```
┌──────────────────────────────┐ y=0
│  Menu (Status bar)          │ h=84
├──────────────────────────────┤ y=84
│                              │
│  [←]  Exchange              │ y=92
│                              │
│  You Sell                    │ y=130 (label)
│  ┌──────────────────────┐   │ y=150
│  │  [BTC] BTC   ↓    0.000│  │ Input 335×56
│  │              $ 0        │  │
│  └──────────────────────┘   │ y=206
│                              │
│  You Receive                 │ y=240
│  ┌──────────────────────┐   │ y=260
│  │  [ETH] BTC   ↓    0.000│  │ Input 335×56
│  │          -1 320.64 $    │  │
│  │          +8.01%         │  │
│  └──────────────────────┘   │ y=316
│                              │
│  [25%] [50%] [75%] [Max]    │ y=350 (chips 79×30, border=#D7D7D7, r=12)
│                              │
│  ┌──────────────────────┐   │ y=412
│  │        Swap           │   │ 335×50, r=12
│  └──────────────────────┘   │
│                              │
│  ┌──────────────────────┐   │ y=480 (modal overlay)
│  │   ───                │   │
│  │   Select Token        │   │
│  │                      │   │
│  │  [icon] Bitcoin (BTC)│   │ 40px rows
│  │  [icon] Ether (ETH)  │   │
│  │  [icon] Tether (USDT)│   │
│  │  [icon] BNB          │   │
│  │  [icon] Solana (SOL) │   │
│  │  [icon] Cardano (ADA)│   │
│  │                      │   │
│  │  [Add another] [Save]│   │
│  └──────────────────────┘   │
│                              │
├──────────────────────────────┤ y=607
│  Bottom Bar                  │
└──────────────────────────────┘ y=667
```

---

## 5. SETTINGS SCREEN

```
┌──────────────────────────────┐ y=0
│  Menu (Status bar)          │ h=84
├──────────────────────────────┤ y=84
│                              │
│  [←]  Settings               │ y=92
│                              │
│  ┌──────────────────────────┐│ y=140 (335×60, r=12, #F7F7F9)
│  │  [wallet] Wallets   [→]  ││
│  └──────────────────────────┘│
│  ┌──────────────────────────┐│ y=208
│  │  [$] Currency     [→]    ││
│  └──────────────────────────┘│
│  ┌──────────────────────────┐│ y=276
│  │  [🔒] Security     [→]   ││
│  └──────────────────────────┘│
│  ┌──────────────────────────┐│ y=344
│  │  [🔗] Wallet Connect [→] ││
│  └──────────────────────────┘│
│  ┌──────────────────────────┐│ y=412
│  │  [🔔] Push Notifications││
│  └──────────────────────────┘│
│  ┌──────────────────────────┐│ y=480
│  │  [☀] Appearance    [→]   ││
│  └──────────────────────────┘│
│  ┌──────────────────────────┐│ y=548
│  │  [?] Help Center   [→]   ││
│  └──────────────────────────┘│
│                              │
│  Logout                      │ y=590 (grey text #5C5F64, ← icon)
│                              │
├──────────────────────────────┤ y=607
│  Bottom Bar                  │
└──────────────────────────────┘ y=667
```

---

## 6. LOADING / SPLASH SCREEN

```
┌──────────────────────────────┐
│                              │
│                              │
│                              │
│         ┌─────────┐         │
│         │  LOGO   │         │ 92×106 centered
│         │ Icon    │         │
│         └─────────┘         │
│                              │
│         Finanace             │ 205×30 text
│                              │
│                              │
│                              │
│         [Loading...]         │ (spinner 30×30)
│                              │
│                              │
└──────────────────────────────┘
```

---

## 7. NOTIFICATION VARIANTS

### Complete (green)
```
┌──────────────────────────────┐
│  ✅  Transaction complete!    │ 335×68, r=12
│      Tap to view...          │ bg=#18CE6B @ 0.1 opacity
└──────────────────────────────┘
```

### Cancelled (red)
```
┌──────────────────────────────┐
│  ❌  Transaction cancelled!   │ 335×68, r=12
│      Tap to view...          │ bg=#F6465D @ 0.1 opacity
└──────────────────────────────┘
```

---

## SUMMARY: Layout Constants

```
SCREEN           = 375 × 667
MENU_BAR         = 375 × 84
BOTTOM_BAR       = 355 × 60   (r=12 top)
SAFE_TOP         = 84
SAFE_BOTTOM      = 60
CONTENT_HEIGHT   = 523        (667-84-60)

BUTTON_LARGE     = 335 × 50   (r=12)
BUTTON_MEDIUM    = 162 × 50   (r=12)
BUTTON_SMALL     = 105 × 40   (r=12)
INPUT_FIELD      = 335 × 56   (r=12)
CARD             = 335 × 160  (r=12)
NOTIFICATION     = 335 × 68   (r=12)
TAB              = 80 × 25    (underline 80×2)
STEP_INDICATOR   = 335 × 20
STRIP            = 322 × 2
STATUS_BAR       = 331 × 16

H_SPACING        = 20         (horizontal margin from edges)
V_SPACING        = 16         (default vertical gap)
V_SPACING_SMALL  = 8
V_SPACING_LARGE  = 24

ICON_SIZE        = 24
ARROW_ICON       = 20 × 20
BACK_ICON        = 20 × 20
COPY_ICON        = 20 × 20
TOKEN_ICON       = 40 × 40   (r=70/51)
CHECKBOX         = 20 × 20   (r=4)
RADIO            = 20 × 20   (circle)
CHIP             = 79 × 30   (r=12)

LOGO_ICON        = 92 × 106
LOGO_TEXT        = 205 × 30
LOGO_TOTAL       = 205 × 172

TITLE_TEXT       = 28px w600    #1E2329
SUBTITLE_TEXT    = 16px w300    #5C5F64
BUTTON_TEXT      = 16px w600    #1E2329 (on primary)
BODY_TEXT        = 14px w400    #5C5F64
CAPTION_TEXT     = 12px w500    #A5ABB6
LABEL_TEXT       = 14px w500    #1E2329
BLUE_LINK        = 14px w500    #236FE9
CHIP_TEXT        = 12px w500    #1E2329
CARD_BALANCE     = 28px w600    #1E2329
CARD_USD         = 14px w400    #A5ABB6
CARD_ADDRESS     = 12px w400    #A5ABB6
TOKEN_NAME       = 16px w600    #1E2329
TOKEN_BALANCE    = 14px w400    #A5ABB6
ERROR_TEXT       = 14px w400    #F6465D

MODAL_OVERLAY    = 375×874  bg=#020202 @ 0.41 opacity
MODAL_SHEET      = 375×513  bg=#FFFFFF  (bottom sheet)
YELLOW_BADGE     = 20×20    bg=#FCD535  with #fff number
TOGGLE           = 44×24    r=12  (bg=#EAECEF, thumb=#FCD535 16px)
ICON_ROW_HEIGHT  = 40+8    (icon 24 + spacing)
SETTINGS_CARD    = 335×60   r=12  bg=#F7F7F9

---

## 8. IMPORT WALLET — Step 1 (Choose Method)

```
┌──────────────────────────────┐ y=0
│  Menu (Status bar)          │ h=84
├──────────────────────────────┤ y=84
│                              │
│  [←]  Import Wallet          │ y=92 (title Poppins 20px w600)
│                              │
│  Private Key / Recovery Phrase │ y=140 (label 14px w500)
│  ┌──────────────────────┐   │ y=162
│  │                      │   │ Input 335×140 (multiline)
│  │                      │   │ border=#D7D7D7, r=12
│  │  [scan]        [Paste]│   │ scan icon + Paste button
│  └──────────────────────┘   │ y=302
│                              │
│  ┌──────────────────────┐   │ y=530
│  │       Import          │   │ 335×50, r=12, bg=#FCD535
│  └──────────────────────┘   │
└──────────────────────────────┘ y=667
```

## 9. IMPORT WALLET — Step 2 (Seed Phrase + Password)

```
┌──────────────────────────────┐ y=0
│  Menu (Status bar)          │ h=84
├──────────────────────────────┤ y=84
│                              │
│  [←]  Import Wallet          │ y=92
│                              │
│  Create password             │ y=136 (16px w600)
│  This password will unlock...│ y=156 (14px, #5C5F64)
│                              │
│  Private Key / Recovery Phrase │ y=210 (label)
│  ┌──────────────────────┐   │ y=230
│  │                      │   │ Input 335×140 (multiline)
│  │  [scan]        [Paste]│   │ border=#D7D7D7, r=12
│  └──────────────────────┘   │ y=370
│                              │
│  New Password (label)        │ y=410
│  ┌──────────────────────┐   │ y=430
│  │  ................ [eye]│   │ 335×56, r=12
│  └──────────────────────┘   │ y=486
│                              │
│  Confirm Password (label)    │ y=520
│  ┌──────────────────────┐   │ y=540
│  │  ................ [eye]│   │ 335×56, r=12
│  └──────────────────────┘   │ y=596
│                              │
│  Passwords do not match...   │ y=610 (guideline, #A5ABB6)
│                              │
│  ┌──────────────────────┐   │ y=650
│  │       Import          │   │ 335×50, r=12, bg=#FCD535
│  └──────────────────────┘   │
└──────────────────────────────┘ y=822 (scrollable)
```

## 10. VERIFY RECOVERY PHRASE (Error screen)

```
┌──────────────────────────────┐ y=0
│  Menu (Status bar)          │ h=84
├──────────────────────────────┤ y=84
│                              │
│  [←]  Verify recovery phrase │ y=92 (20px w600)
│                              │
│  ● ── ● ── ●                │ y=130 (Step3: ALL active)
│  01   02   03               │
│                              │
│  Tap the words to put them   │ y=160 (335×44, 16px w300, #5C5F64)
│  next to each other...       │
│                              │
│  ┌──────────────────────┐   │ y=220
│  │  WORD POOL           │   │ Words area 335×288
│  │  ┌────────┐ ┌──────┐ │   │ bg=#F7F7F9, r=12
│  │  │ 1.smash│ │2.word│ │   │ chips 147×36, r=12
│  │  └────────┘ └──────┘ │   │ default: border=#D7D7D7, bg=#FFF
│  │  ┌────────┐ ┌──────┐ │   │ error: border=#F6465D
│  │  │3.pub..█│ │4.    │ │   │ selected: bg=#1E2329
│  │  └────────┘ └──────┘ │   │
│  │  ... 12 words total  │   │
│  └──────────────────────┘   │ y=508
│                              │
│  [Disable] [Disable] [Disa] │ y=520 (selected chips 106×36, r=12)
│  [Disable] [Disable] [Disa] │ bg=#A5ABB6 when empty
│                              │
│  ┌──────────────────────┐   │ y=620
│  │       Verify          │   │ 335×50, r=12, bg=#FCD535
│  └──────────────────────┘   │
└──────────────────────────────┘ y=775
```

## 11. SETTINGS SCREEN

```
┌──────────────────────────────┐ y=0
│  Menu (Status bar)          │ h=84
├──────────────────────────────┤ y=84
│  [←]  Settings               │ y=92 (arrow + title)
│                              │
│  ┌──────────────────────────┐│ y=140 (335×60, #F7F7F9, r=12)
│  │  [wallet] Wallets   [→]  ││  icon 24×24 + text 16px + arrow
│  └──────────────────────────┘│
│  ┌──────────────────────────┐│ y=208
│  │  [$] Currency     [→]    ││
│  └──────────────────────────┘│
│  ┌──────────────────────────┐│ y=276
│  │  [🔒] Security     [→]   ││
│  └──────────────────────────┘│
│  ┌──────────────────────────┐│ y=344
│  │  [🔗] Wallet Connect [→] ││
│  └──────────────────────────┘│
│  ┌──────────────────────────┐│ y=412
│  │  [🔔] Push Notifications ││  toggle 44×24 right
│  └──────────────────────────┘│
│  ┌──────────────────────────┐│ y=480
│  │  [☀] Appearance    [→]   ││
│  └──────────────────────────┘│
│  ┌──────────────────────────┐│ y=548
│  │  [?] Help Center   [→]   ││
│  └──────────────────────────┘│
│  ┌──────────────────────────┐│ y=616
│  │  [📞] Contact Us   [→]   ││
│  └──────────────────────────┘│
│  ┌──────────────────────────┐│ y=684
│  │  [ⓘ] About         [→]   ││
│  └──────────────────────────┘│
│                              │
│  [←]  Logout                 │ y=810 (#5C5F64, 16px)
│                              │
├──────────────────────────────┤ y=752
│  Bottom Bar (if present)    │
└──────────────────────────────┘ y=812
```
