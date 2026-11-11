# ⚡ Antigravity Quota Monitor

[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Windows-blue.svg)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](#)
[![PowerShell](https://img.shields.io/badge/PowerShell-WPF-5391FE.svg)](#)

Monitor de cota de uso de IA elegante e nativo para o **Antigravity**. Exibe em tempo real o percentual restante dos seus limites semanais e da janela de 5 horas para **Gemini Models**, **Claude & GPT** e **Gemini 4 Argon**, com tempo estimado para renovação e cache inteligente de 60 segundos.

---

## ✨ Recursos

- ⚡ **Dados em Tempo Real**: Conecta-se diretamente ao serviço RPC local do Antigravity (`language_server`), sem necessidade de chaves de API manuais.
- 🎨 **Interface Nativa & Dark Mode**:
  - **macOS**: Desenvolvido em Swift nativo com AppKit, suporte a Dark Mode, efeito translúcido (Vibrancy) e tipografia San Francisco.
  - **Windows**: Interface nativa Fluent/WPF em Dark Theme com barras de progresso dinâmicas coloridas.
- ⏳ **Contagem Regressiva**: Mostra exatamente quando cada janela será renovada (ex.: `2d 7h`, `2h 25m`).
- ⚡ **Cache de 60 segundos**: Evita requisições repetidas se você reabrir o app em sequência.
- 🔄 **Atualização Sob Demanda**: Botão *Atualizar* (ou atalho `Cmd+R` / `F5`) para forçar recarga instantânea.
- 🚀 **Zero Telemetria & 100% Local**: Todo o processamento ocorre no `localhost`.

---

## 🖥️ Instalação & Uso

### macOS

#### Opção 1: Download Direto (Releases)
1. Baixe o arquivo `Antigravity-Quota-macOS.zip` na aba [Releases](../../releases).
2. Extraia e arraste o **Antigravity Quota.app** para a sua pasta `/Applications` (Aplicativos).
3. Abra pelo Spotlight (`Cmd + Espaço` -> *Antigravity Quota*) ou fixe no Dock.

#### Opção 2: Compilar a partir do código fonte
```bash
git clone https://github.com/<seu-usuario>/antigravity-quota-monitor.git
cd antigravity-quota-monitor/macos
./install.sh
```

---

### Windows

#### Opção 1: Download Direto (Releases)
1. Baixe o `Antigravity-Quota-Windows.zip` na aba [Releases](../../releases).
2. Extraia a pasta em qualquer local (ex.: `C:\Users\<usuario>\AppData\Local\AntigravityQuota`).
3. Clique com o botão direito em `install.ps1` e selecione **Executar com o PowerShell** (ou dê dois cliques em `AntigravityQuota.vbs`).
4. Um atalho com o nome **Antigravity Quota** será criado no seu Menu Iniciar!

---

## 🛠️ Como Funciona

O Antigravity executa localmente um processo chamado `language_server` (ou `agy`) que escuta requisições de serviço em uma porta dinâmica protegida por um token CSRF (`--csrf_token`).

O **Antigravity Quota Monitor**:
1. Detecta o processo ativo e localiza a porta RPC local e o token de autorização.
2. Faz uma chamada local segura para o endpoint `/exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary`.
3. Normaliza e formata os dados das cotas e janelas de tempo.
4. Renderiza o pop-up nativo ultra-rápido.

---

## 🤝 Contribuição

Contribuições são muito bem-vindas! Sinta-se à vontade para abrir uma *Issue* ou enviar um *Pull Request*.

## 📄 Licença

Distribuído sob a licença [MIT](LICENSE).
