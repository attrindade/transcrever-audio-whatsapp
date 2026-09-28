#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_LineFile%\..\Lib\UIA.ahk

; transcrever-audio-whatsapp — encaminha o áudio sob o cursor para o Blip ViraTexto no WhatsApp Desktop.
; Uso: passe o mouse sobre um áudio (em qualquer ponto da linha dele) e aperte F9 ou o botão do meio do mouse.
;      F10 (no WhatsApp) ou Ctrl+Alt+B (de qualquer lugar) abre a conversa com o Blip ViraTexto.
; Funciona pelos nomes de acessibilidade do WhatsApp (UI Automation), não por coordenadas.

; ---------- configuração ----------
DRY_RUN := false             ; true = para antes de enviar (você confere e clica em enviar). Mude para false quando confiar.
DESTINO := "Blip ViraTexto"  ; nome do contato exatamente como aparece no WhatsApp
TIMEOUT := 3000              ; ms de espera por cada tela
ABRIR_APOS_ENVIAR := false   ; true = depois de encaminhar, já abre a conversa com o DESTINO
; ----------------------------------

CoordMode "Mouse", "Screen"
CoordMode "ToolTip", "Screen"
ARQ_LOG := A_LineFile "\..\transcrever-audio.log"
ocupado := false
abriu := false   ; já abrimos menu/seleção/diálogo? (só então vale cancelar com Esc)

#HotIf WinActive("ahk_exe WhatsApp.Root.exe")
F9::EncaminharAudio()
MButton::EncaminharAudio()
F10::AbrirConversa()
#HotIf
^!b::AbrirConversa()   ; Ctrl+Alt+B de qualquer lugar: traz o WhatsApp e abre a conversa

AbrirConversa() {
    global ocupado
    if ocupado
        return
    ocupado := true
    try {
        AbrirDestino()
    } catch as e {
        Aviso("✗ " e.Message, 4000)
        Log("ERRO: " e.Message " (linha " e.Line ")")
    }
    ocupado := false
}

; Abre a conversa com o DESTINO: clica nele na lista de conversas; se não estiver visível, pesquisa.
AbrirDestino() {
    hwnd := WinExist("ahk_exe WhatsApp.Root.exe")
    if !hwnd
        throw Error("O WhatsApp não está aberto.")
    WinActivate hwnd
    WinWaitActive hwnd, , 2
    doc := UIA.ElementFromHandle(hwnd).FindElement({Type:"Document"})
    composer := {Name:"Digite uma mensagem para " DESTINO, Type:"Edit"}
    try {
        doc.FindElement(composer)   ; já está nela
        return
    }
    pesquisou := false
    item := ItemDaLista(doc)
    if !item {
        busca := doc.FindElement({Name:"Pesquisar ou começar uma nova conversa", Type:"Edit"})
        busca.SetFocus()
        Send "^a"
        SendText DESTINO
        pesquisou := true
        fim := A_TickCount + TIMEOUT
        while !item && A_TickCount < fim {
            Sleep 100
            item := ItemDaLista(doc)
        }
        if !item
            throw Error("Não achei '" DESTINO "' nas conversas.")
    }
    item.Click("left", , , , , 0)
    campo := doc.WaitElement(composer, TIMEOUT)
    if !campo
        throw Error("Não consegui abrir a conversa com " DESTINO ".")
    if pesquisou {
        ; limpa a pesquisa para a lista de conversas voltar ao normal
        try {
            busca.SetFocus()
            Send "^a{Delete}"
        }
    }
    campo.SetFocus()
}

; Item visível da lista de conversas com o nome do DESTINO (ou 0).
ItemDaLista(doc) {
    for it in doc.FindElements({Name:DESTINO, Type:"DataItem", mm:2})
        if !it.IsOffscreen
            return it
    return 0
}

EncaminharAudio() {
    global ocupado, abriu
    if ocupado
        return
    ocupado := true, abriu := false
    try {
        Encaminhar()
    } catch as e {
        if abriu
            Cancelar()
        Aviso("✗ " e.Message, 4000)
        Log("ERRO: " e.Message " (linha " e.Line ")")
    }
    ocupado := false
}

Encaminhar() {
    global abriu
    MouseGetPos &mx, &my
    hwnd := WinExist("ahk_exe WhatsApp.Root.exe")
    doc := UIA.ElementFromHandle(hwnd).FindElement({Type:"Document"})

    ; 1. acha a linha de mensagem sob o cursor que contém um áudio
    voz := AudioSob(doc, mx, my, &linha)
    if !voz
        throw Error("O cursor não está sobre um áudio.")

    ; 2. abre o menu da mensagem. O botão ▾ só aparece com o mouse sobre a bolha,
    ;    então leva o cursor até ela; se o botão não surgir, usa o clique direito ali.
    Aviso("Encaminhando áudio…")
    abriu := true
    b := UIA.RawViewWalker.GetParentElement(voz).Location
    MouseMove b.x + b.w // 2, b.y + b.h // 2, 0
    menuBtn := linha.WaitElement({Name:"Menu de contexto", Type:"Button", mm:2}, 600)
    if menuBtn
        menuBtn.Click()
    else
        Click "Right"
    item := doc.WaitElement({Name:"Encaminhar", Type:"MenuItem"}, menuBtn ? 1000 : TIMEOUT)
    if !item && menuBtn {
        Log("botão ▾ não abriu o menu; tentando clique direito")
        Click "Right"
        item := doc.WaitElement({Name:"Encaminhar", Type:"MenuItem"}, TIMEOUT)
    }
    MouseMove mx, my, 0
    if !item
        throw Error("Menu sem a opção Encaminhar.")
    item.Click()

    ; 3. barra "1 selecionada" → botão Encaminhar
    btn := doc.WaitElement({Name:"Encaminhar", Type:"Button"}, TIMEOUT)
    if !btn
        throw Error("Não achei o botão Encaminhar da seleção.")
    btn.Click()

    ; 4. diálogo "Encaminhar mensagem para" → marca o destino
    titulo := doc.WaitElement({Name:"Encaminhar mensagem para", Type:"Text"}, TIMEOUT)
    if !titulo
        throw Error("O diálogo de encaminhar não abriu.")
    dlg := Ancestral(titulo, UIA.Type.Window)   ; o próprio diálogo, não outra janela qualquer
    if !dlg
        throw Error("Não identifiquei o diálogo de encaminhar.")
    ; pesquisa sempre pelo nome: a lista de recentes muda de ordem e o contato pode estar fora da tela
    busca := dlg.FindElement({Name:"Pesquisar nome", Type:"Edit", mm:2})
    busca.SetFocus()
    SendText DESTINO
    Sleep 300
    alvo := EsperaVisivel(dlg, {Name:DESTINO, Type:"CheckBox"}, TIMEOUT)
    if !alvo
        alvo := EsperaVisivel(dlg, {Name:DESTINO, Type:"CheckBox", mm:2}, 500)
    if !alvo
        throw Error("Não achei '" DESTINO "' na lista.")
    ; clique físico no nome do contato (o clique "lógico" do UIA não marca a caixa)
    alvo.Click("left", , , , , 0)
    Sleep 150
    if !Marcado(alvo)
        throw Error("A caixa de '" DESTINO "' não ficou marcada.")

    ; o botão Enviar já existe escondido e entra na tela com animação depois que a caixa é marcada
    enviar := EsperaVisivel(dlg, {Name:"Enviar", Type:"Button"}, TIMEOUT)
    if !enviar && Marcado(alvo) {
        ; o WebView às vezes marca o botão como "fora da tela" mesmo visível; como a caixa
        ; do destino está marcada (e só ela), aceita o botão se ele tiver tamanho dentro do diálogo
        try {
            e := dlg.FindElement({Name:"Enviar", Type:"Button"})
            r := e.BoundingRectangle, d := dlg.BoundingRectangle
            if (r.r > r.l && r.b > r.t && r.l >= d.l && r.r <= d.r && r.t >= d.t && r.b <= d.b) {
                enviar := e
                Log("Enviar marcado como fora da tela, mas dentro do diálogo: usando")
            }
        }
    }
    if !enviar {
        nomes := ""
        for bt in dlg.FindElements({Type:"Button"})
            nomes .= "[" bt.Name (bt.IsOffscreen ? " (fora da tela)" : "") "] "
        Log("Diálogo sem botão Enviar. Botões: " nomes)
        throw Error("Não achei o botão Enviar (detalhes em transcrever-audio.log).")
    }

    ; 5. envia
    if DRY_RUN {
        Aviso("Teste: tudo pronto. Clique em enviar você mesmo.", 4000)
        Log("DRY_RUN ok")
        return
    }
    enviar.Click()
    Aviso("✓ Áudio enviado para " DESTINO, 2000)
    Log("enviado")
    if ABRIR_APOS_ENVIAR {
        Sleep 500
        AbrirDestino()
    }
}

; Espera um elemento existir E estar visível (não "fora da tela"); devolve 0 se o tempo acabar.
EsperaVisivel(raiz, cond, timeout) {
    fim := A_TickCount + timeout
    Loop {
        try {
            el := raiz.FindElement(cond)
            if !el.IsOffscreen
                return el
        }
        if A_TickCount > fim
            return 0
        Sleep 50
    }
}

; Primeiro ancestral do tipo pedido (ou 0).
Ancestral(el, tipo) {
    Loop 25 {
        el := UIA.RawViewWalker.GetParentElement(el)
        if !el
            return 0
        if el.Type = tipo
            return el
    }
    return 0
}

; A caixa de seleção (ou a caixa interna dela) está marcada?
Marcado(chk) {
    Loop 10 {                      ; o WhatsApp leva um instante para refletir o clique
        for el in [chk, chk.FindElements({Type:"CheckBox"})*] {
            try {
                if el.TogglePattern.CurrentToggleState = 1
                    return true
            }
        }
        Sleep 100
    }
    ; diagnóstico para o log: o que a acessibilidade mostrou de cada caixa
    info := ""
    for el in [chk, chk.FindElements({Type:"CheckBox"})*] {
        est := "?"
        try est := el.TogglePattern.CurrentToggleState
        info .= "[toggle? " el.GetPropertyValue(UIA.Property.IsTogglePatternAvailable) " estado " est "] "
    }
    Log("Caixa não marcada: " chk.Name " " info)
    return false
}

; Mensagem de voz cuja linha (DataItem) contém o ponto; a linha volta em &linha.
AudioSob(doc, x, y, &linha) {
    for voz in doc.FindElements({Name:"Mensagem de voz", Type:"Group"}) {
        el := voz
        Loop 8 {
            el := UIA.RawViewWalker.GetParentElement(el)
            if !el
                break
            if el.Type = UIA.Type.DataItem {
                r := el.BoundingRectangle
                if (x >= r.l && x <= r.r && y >= r.t && y <= r.b) {
                    linha := el
                    return voz
                }
                break
            }
        }
    }
    return 0
}

Cancelar() {
    ; fecha menu/diálogo e sai do modo seleção, para não deixar o WhatsApp pela metade.
    ; Só aperta Esc enquanto houver algo aberto: Esc sobrando fecha a conversa.
    if !WinActive("ahk_exe WhatsApp.Root.exe")
        return
    try {
        doc := UIA.ElementFromHandle(WinExist("ahk_exe WhatsApp.Root.exe")).FindElement({Type:"Document"})
        Loop 3 {
            aberto := 0
            try aberto := doc.FindElement({Name:"Encaminhar mensagem para", Type:"Text"})
            if !aberto
                try aberto := doc.FindElement({Name:"selecionad", Type:"Text", mm:2})
            if !aberto
                try aberto := doc.FindElement({Type:"Menu"})
            if !aberto
                return
            Send "{Esc}"
            Sleep 300
        }
    }
}

Aviso(texto, ms := 0) {
    MouseGetPos &x, &y
    ToolTip texto, x + 16, y + 16
    if ms
        SetTimer () => ToolTip(), -ms
}

Log(texto) {
    try FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " " texto "`n", ARQ_LOG, "UTF-8")
}






