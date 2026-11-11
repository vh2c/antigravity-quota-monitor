# ⚡ Antigravity Quota Monitor

[![Powered by VH2C](https://img.shields.io/badge/Developed%20by-vh2c.com.br-blue.svg?style=flat-square)](https://vh2c.com.br)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Windows-lightgrey.svg?style=flat-square)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat-square)](#)
[![PowerShell](https://img.shields.io/badge/PowerShell-WPF-5391FE.svg?style=flat-square)](#)

Monitor de cota de uso de IA elegante e nativo para o **Antigravity**. Exibe em tempo real o percentual restante dos seus limites semanais e da janela de 5 horas para **Gemini Models**, **Claude & GPT** e **Gemini 4 Argon**, com contagem regressiva para renovação e cache inteligente de 60 segundos.

Desenvolvido por [VH2C](https://vh2c.com.br).

---

## 📥 Downloads Públicos (Releases)

Para baixar os executáveis prontos para uso sem precisar compilar:

👉 **[Acessar a página de Releases](../../releases/latest)**

* 🍏 **macOS (Apple Silicon & Intel)**: Baixe `Antigravity-Quota-macOS-vh2c.zip`
* 🪟 **Windows (10 & 11)**: Baixe `Antigravity-Quota-Windows-vh2c.zip`

---

## ✨ Recursos

- ⚡ **Dados em Tempo Real**: Conexão direta com o processo local do Antigravity (`language_server`), sem necessidade de chaves de API manuais.
- 🎨 **Paleta Oficial Antigravity**:
  - Fundo em `#181818` 100% sólido (sem transparência).
  - Campos e cartões em `#1F1F1F`.
  - Botões inferiores claros de alto contraste (`#EEEEF0`) com ícones estritamente monocromáticos.
- 🍏 **macOS Nativo (Swift 6 & AppKit)**:
  - Inicialização automática via daemon nativo integrado ao sistema (`NSWorkspace`).
  - Retentativas automáticas na inicialização do sistema para aguardar o backend.
  - Armazenamento persistente que sobrevive a reinicializações.
- 🪟 **Windows Nativo (WPF & PowerShell)**:
  - Interface moderna Fluent Design Dark Theme.
  - Zero dependências externas (executa nativamente com o motor .NET embutido no Windows).
  - Atalho automático no Menu Iniciar.
- ⏳ **Contagem Regressiva de Renovação**: Mostra exatamente o tempo restante para cada janela (ex.: `2d 6h`, `1h 48m`).
- ⚡ **Cache de 60 segundos**: Evita requisições repetidas ao reabrir o aplicativo em sequência.
- 🚀 **100% Local & Seguro**: Zero telemetria externa, todo o tráfego ocorre exclusivamente no `localhost`.

---

## 🖥️ Como Instalar & Usar

### 🍏 macOS

#### Opção 1: Download do Executável Pronto
1. Baixe o `Antigravity-Quota-macOS-vh2c.zip` na aba [Releases](../../releases/latest).
2. Extraia e arraste o **Antigravity Quota.app** para a pasta `/Applications` (Aplicativos).
3. Abra pelo Spotlight (`Cmd + Espaço` -> *Antigravity Quota*) ou fixe no Dock.

#### Opção 2: Compilar via Terminal
```bash
git clone https://github.com/<seu-usuario>/antigravity-quota-monitor.git
cd antigravity-quota-monitor/macos
./install.sh
```

---

### 🪟 Windows

#### Opção 1: Download Pronto
1. Baixe o `Antigravity-Quota-Windows-vh2c.zip` na aba [Releases](../../releases/latest).
2. Extraia o conteúdo em qualquer pasta (ex.: `C:\Users\<usuario>\AppData\Local\AntigravityQuota`).
3. Clique com o botão direito no arquivo `install.ps1` e selecione **Executar com o PowerShell** (ou dê dois cliques em `AntigravityQuota.vbs`).
4. Um atalho **Antigravity Quota** será criado automaticamente no seu Menu Iniciar!

---

## 🚀 Como Publicar no GitHub com CI/CD Automático

O repositório já inclui um fluxo de trabalho do **GitHub Actions** em `.github/workflows/release.yml`. Sempre que uma versão for publicada, o GitHub constrói e anexa os arquivos `.zip` do Mac e Windows automaticamente.

### Publicando o repositório pela primeira vez:
```bash
# 1. Crie um repositório público vazio no seu GitHub (ex: antigravity-quota-monitor)
# 2. Conecte e envie o código:
git remote add origin https://github.com/<seu-usuario>/antigravity-quota-monitor.git
git branch -M main
git push -u origin main

# 3. Para gerar a primeira versão para download público (Release com os ZIPs prontos):
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```
O GitHub Actions iniciará automaticamente e criará a página de **Releases** com os arquivos para download público!

---

## 🏢 Sobre a VH2C

Desenvolvido e mantido pela [VH2C Soluções Tecnológicas](https://vh2c.com.br).

Dúvidas ou sugestões? Abra uma [Issue](../../issues) ou envie um Pull Request!

## 📄 Licença

Distribuído sob a licença [MIT](LICENSE). Copyright © 2026 [VH2C](https://vh2c.com.br).
