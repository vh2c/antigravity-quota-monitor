# ⚡ Antigravity Quota Monitor — Resumo do Projeto

> Desenvolvido por **[VH2C Soluções Tecnológicas](https://vh2c.com.br)**  
> Repositório Multiplataforma: **macOS (Swift/AppKit)** & **Windows (.NET/WPF)**

---

## 📌 Visão Geral

O **Antigravity Quota Monitor** é uma aplicação nativa e leve criada para resolver a necessidade de acompanhar os limites de consumo dos modelos de inteligência artificial no **Antigravity**.

Em vez de exigir chaves de API externas ou login em painéis web, o monitor se conecta diretamente ao processo local do Antigravity (`language_server`) em `127.0.0.1` via chamadas RPC autenticadas pelo token CSRF local.

---

## 🎯 Principais Funcionalidades

1. **Leitura Precisa e em Tempo Real**:
   - **Gemini Models**: Limite Semanal (%) e Janela de 5 Horas (%) com contagem regressiva de renovação (ex.: `2d 5h`, `26m`).
   - **Claude & GPT Models**: Limite Semanal e Janela de 5 Horas.
   - **Gemini 4 Argon**: Limite específico do plano Pro.
   - Identificação da conta do usuário e plano ativo (ex.: `vitorh2c@gmail.com • Plano Pro`).

2. **Paleta Oficial do Antigravity (100% Sólida)**:
   - Fundo principal: `#181818` (sem transparência ou desfoque).
   - Cartões e campos: `#1F1F1F` com bordas sutis em `#2C2C2C` e separadores em `#282828`.
   - Barras de progresso: Trilho `#2D2D2D` com preenchimento dinâmico colorido por nível (`#34C759` >50%, `#FF9500` 20-50%, `#FF3B30` <20%).
   - Botões inferiores: Claros e destacados em `#EEEEF0` com texto `#181818`.
   - Ícones: Estritamente monocromáticos (SF Symbol `arrow.clockwise` colado ao texto "Atualizar").
   - Assinatura VH2C: Link sutil `vh2c.com.br` centralizado no rodapé.

3. **Comportamento de Janela Fluido**:
   - Janela com comportamento normal (`window.level = .normal` no macOS e `Topmost="False"` no Windows).
   - Ao clicar em outra aplicação, a janela vai suavemente para segundo plano sem bloquear a área de trabalho.
   - Suporte a minimizar para o Dock / Barra de Tarefas.

4. **Monitor em Segundo Plano (Zero CPU / Zero Polling)**:
   - **macOS**: Daemon nativo `AntigravityWatcher` registrado no `launchd` (`com.antigravity.quotamonitor`). Utiliza a API do sistema `NSWorkspace.didLaunchApplicationNotification`. Abre o pop-up automaticamente ao iniciar o Antigravity (ou ao ligar o computador com o app aberto).
   - **Mecanismo de Retentativa (Retry)**: Ao detectar a inicialização, tenta até 6 vezes (1s entre tentativas) para aguardar o backend do Antigravity subir a porta RPC antes de exibir os dados.
   - **Cache de 60 Segundos**: Evita abertura repetida se o usuário alternar entre janelas em menos de 1 minuto.
   - **Armazenamento Persistente**: Dados salvos em `~/Library/Application Support/AntigravityQuota/`, imunes a reinicializações.

---

## 📂 Estrutura de Arquivos do Repositório

```text
antigravity-quota-monitor/
├── .github/
│   └── workflows/
│       └── release.yml          # CI/CD: Compila macOS e Windows automaticamente a cada release
├── core/
│   └── quota_engine.js          # Motor RPC universal Node.js (descoberta de porta, CSRF e parser)
├── macos/
│   ├── src/
│   │   ├── QuotaApp.swift       # Interface gráfica nativa Swift / AppKit
│   │   └── QuotaWatcher.swift   # Daemon de monitoramento em segundo plano (NSWorkspace)
│   ├── build.sh                 # Script para compilar o executável e gerar o "Antigravity Quota.app"
│   └── install.sh               # Instalador com 1 clique para macOS (App + LaunchAgent)
├── windows/
│   ├── AntigravityQuota.ps1     # Interface nativa Windows WPF / XAML (Dark Theme Fluent)
│   ├── AntigravityQuota.vbs     # Inicializador silencioso (sem piscar terminal)
│   └── install.ps1              # Instalador do atalho no Menu Iniciar do Windows
├── LICENSE                      # Licença MIT em nome da VH2C (vh2c.com.br)
├── README.md                    # Documentação completa em português/inglês para o GitHub
└── RESUMO.md                    # Este resumo técnico
```

---

## 🌐 Como Tornar Público no GitHub

O projeto já está 100% commitado localmente no branch `main`. Para que ele fique público para qualquer pessoa baixar:

### Passo 1: Criar o Repositório no GitHub
1. Acesse [github.com/new](https://github.com/new).
2. Defina o nome do repositório como `antigravity-quota-monitor`.
3. Escolha **Public** (Público).
4. **Não marque** as opções de adicionar README ou .gitignore (eles já existem no projeto).
5. Clique em **Create repository**.

### Passo 2: Enviar o Código Local para o GitHub
No Terminal do seu Mac, execute:

```bash
cd ~/.gemini/antigravity/scratch/antigravity-quota-monitor

# Vincular o repositório remoto da conta vh2c
git remote add origin https://github.com/vh2c/antigravity-quota-monitor.git

# Enviar o branch principal
git branch -M main
git push -u origin main
```

### Passo 3: Gerar os Arquivos para Download Público (Release)
O GitHub Actions configurado em `.github/workflows/release.yml` compilará os arquivos automaticamente para quem quiser apenas baixar e usar:

```bash
# Criar e enviar a tag da versão 1.0.0
git tag -a v1.0.0 -m "Release v1.0.0 - Antigravity Quota Monitor by vh2c.com.br"
git push origin v1.0.0
```

Após esse comando, acesse:
`https://github.com/vh2c/antigravity-quota-monitor/releases`

O GitHub Actions gerará os dois downloads públicos:
* 🍏 `Antigravity-Quota-macOS-vh2c.zip`
* 🪟 `Antigravity-Quota-Windows-vh2c.zip`

---

## 🏢 Créditos & Licença

* **Autor**: Vitor Hugo Cunha / **VH2C Soluções Tecnológicas**
* **Site Oficial**: [https://vh2c.com.br](https://vh2c.com.br)
* **Licença**: [MIT](LICENSE)
