# Transcrever áudio do WhatsApp com um clique

Encaminhe um áudio do WhatsApp para o **[Blip ViraTexto](https://www.blip.ai/viratexto/)** (o robô que transcreve áudio na hora) com **um clique**, sem abrir menu nem procurar o contato.

Sem a automação, são 5 passos: abrir o menu do áudio → *Encaminhar* → botão de encaminhar → procurar o Blip ViraTexto → *Enviar*. Com ela:

| Ação | Atalho |
|---|---|
| Encaminhar o áudio para o Blip ViraTexto | **botão do meio do mouse** sobre o áudio (ou mouse em cima + **F9**) |
| Ir para a conversa com o Blip ViraTexto | **F10** com o WhatsApp aberto, ou **Ctrl+Alt+B** de qualquer programa |

**Funciona em:** Windows, com o **app do WhatsApp** instalado (WhatsApp Desktop, da Microsoft Store ou do site do WhatsApp), em **português**.

**Ainda não funciona em:** WhatsApp Web no navegador, Linux e Mac. Uma versão para navegador está nos planos.

> **Antes de tudo:** mande um "oi" para o Blip ViraTexto uma vez, para ele aparecer nas suas conversas: [abrir conversa com o Blip ViraTexto](https://wa.me/553133496201) (número do Brasil, tirado do [site oficial](https://www.blip.ai/viratexto/)).

## Instalação

O script usa o [AutoHotkey](https://www.autohotkey.com/), um programa gratuito que roda pequenas automações no Windows.

1. Instale o **AutoHotkey v2** em [autohotkey.com](https://www.autohotkey.com/) (botão *Download → v2.0*). A v1 não serve.
2. Baixe este repositório: botão verde **Code → Download ZIP**, no topo desta página. Descompacte numa pasta sua, por exemplo `Documentos\transcrever-audio-whatsapp`.
3. Entre na pasta `windows` e dê dois cliques em **`transcrever-audio.ahk`**. Aparece um ícone **H** verde perto do relógio: o script está rodando.

Pronto: no app do WhatsApp, com o mouse sobre um áudio (em qualquer ponto da linha dele), aperte o botão do meio. Em cerca de um segundo aparece "✓ Áudio enviado para Blip ViraTexto".

**Para abrir sozinho ao ligar o PC:** aperte `Win+R`, digite `shell:startup` e dê Enter. Na pasta que abrir, coloque um atalho para o `transcrever-audio.ahk`. Para criar o atalho: botão direito no arquivo → *Mostrar mais opções* → *Criar atalho*, depois arraste o atalho para essa pasta.

**Para desligar:** botão direito no ícone **H** verde → *Exit*.

### Primeira vez? Teste antes

Se quiser ver funcionando antes de confiar, ligue o modo de teste (`DRY_RUN := true`, veja abaixo). Ele faz tudo, deixa a janela de encaminhar aberta com o Blip ViraTexto marcado e para. Aí quem clica em enviar é você.

## Configuração

Abra o `windows\transcrever-audio.ahk` no Bloco de Notas. As opções ficam no começo do arquivo. Depois de salvar, dê dois cliques no arquivo de novo para valer.

| Opção | Padrão | O que faz |
|---|---|---|
| `DESTINO` | `"Blip ViraTexto"` | Nome do contato, exatamente como aparece no seu WhatsApp. Troque se você salvou com outro nome. |
| `DRY_RUN` | `false` | `true` = modo de teste: faz tudo e para antes de enviar. |
| `ABRIR_APOS_ENVIAR` | `false` | `true` = depois de encaminhar, já abre a conversa com o Blip para você ver a transcrição. |

**Trocar os atalhos:** são as linhas `F9::`, `MButton::` (botão do meio), `F10::` e `^!b::` (Ctrl+Alt+B). Por exemplo, trocar `MButton::` por `XButton1::` passa a usar o botão lateral do mouse.

## Como funciona

O Windows mantém uma descrição de cada tela, botão por botão, com nome e tipo, feita para os leitores de tela de quem não enxerga (a *árvore de acessibilidade*). O script procura os botões por esse nome ("Encaminhar", "Blip ViraTexto", "Enviar"), e não pela posição na tela. Por isso funciona com a janela de qualquer tamanho e com a conversa rolada em qualquer ponto.

A biblioteca que faz essa leitura é a [UIA-v2](https://github.com/Descolada/UIA-v2), de Descolada (licença MIT). Ela já vem na pasta `windows/Lib`.

## Quando algo dá errado

Aparece um aviso começando com **✗** perto do mouse, dizendo em que passo parou, e o script fecha o que tinha aberto. Ele só aperta Enviar depois de conferir que a caixa do `DESTINO` está marcada na janela de encaminhar.

- **"O cursor não está sobre um áudio"**: só funciona com mensagens de voz (as que têm a onda sonora), não com arquivos de música anexados.
- **"Não achei 'Blip ViraTexto' na lista"**: o contato está salvo com outro nome, ou você nunca conversou com ele. Veja `DESTINO` acima.
- **Parou de funcionar depois de uma atualização do WhatsApp**: o script depende dos textos dos botões. Se o WhatsApp mudar esses textos, é preciso ajustar o script: abra uma *issue* aqui no GitHub e cole o que está no log.
- **WhatsApp em outro idioma**: os textos procurados estão em português. Em outro idioma, o script não acha os botões.
- **Detalhes do erro:** ficam no arquivo `windows\transcrever-audio.log`.

## Privacidade

Tudo roda no seu computador. O script não manda nada para lugar nenhum, além do próprio encaminhamento feito pelo WhatsApp. Ele não guarda mensagens: o log registra só a hora, o passo em que parou e os nomes dos botões que achou.

Este projeto não tem ligação com o WhatsApp, a Meta ou a Blip. É uma automação da interface: faz os mesmos cliques que você faria.

## Licença

MIT. Veja [LICENSE](LICENSE).
