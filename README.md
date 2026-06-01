# ES-PI3-2026-T2-G09

### Integrantes
* **João Paulo Ferreira** - 25000684 - [Clique aqui para acessar o perfil do aluno](https://github.com/Jpaulo06972)
* **Felipe Batista Bastos** - 25005337 - [Clique aqui para acessar o perfil do aluno](https://github.com/Febastos21)
* **Felipe Cesar Ferreira Lirani** - 25007003 - [Clique aqui para acessar o perfil do aluno](https://github.com/felipelirani)
* **Tomás de Paula Michelon Toniato** - 25004211 - [Clique aqui para acessar o perfil do aluno](https://github.com/lightblueyz)

---

## 🚀 Sobre o Projeto
O **Mesclainvest** é um aplicativo mobile focado em gestão de investimentos e controle financeiro. O objetivo do projeto é oferecer um frontend amigável e seguro, proporcionando um fluxo intuitivo desde a autenticação até a visualização de portfolios de investimento.

---

## 🛠️ Gestão e Organização (Avaliação PI III)

Para este projeto, adotamos práticas de governança de código e gestão ágil diretamente no ecossistema GitHub:

### 📊 Gestão de Projeto (GitHub Projects)
Nosso fluxo de trabalho é gerenciado através do **GitHub Project**, onde organizamos nossas sprints e prioridades.
* [🔗 Clique aqui para acessar o Kanban do Projeto](https://github.com/users/Jpaulo06972/projects/3)

### 🚩 Rastreabilidade (Issues)
Utilizamos **Issues** para documentar requisitos, bugs e melhorias. Cada integrante é atribuído a tarefas específicas para garantir a transparência da colaboração.
* [🔗 Visualizar Issues Ativas](https://github.com/Jpaulo06972/ES-PI3-2026-T2-G09/issues)

### 🌿 Estratégia de Versionamento
Para garantir a integridade do código, seguimos o padrão, com as seguintes divisões principais e fluxos:
* `main`: Código estável em produção.
* `dev`: Ambiente de integração de novas funcionalidades.
* `feature/`: Branches individuais para desenvolvimento de tarefas (ex: `auth`, `dashboard`, `profile`).

---

## ✨ Funcionalidades do Aplicativo

O Frontend do aplicativo atualmente está estruturado nos seguintes módulos:

### Autenticação (Fluxo de Entrada)
- **Página de Login**: Acesso para usuários existentes.
- **Página de Cadastro**: Fluxo para registro de novos usuários.
- **Componentes de Entrada Seguros e Validados**:
  - `CpfField`: Campo testado com máscara e validação de formato de CPF.
  - `PasswordField`: Campo oculto com função para alternar a visibilidade (mostrar/esconder senha).
  - `NameField`: Campo padrão para entradas de nome.
- **Validação de Dados**: Uso robusto de formulários via `GlobalKey<FormState>`.

### Dashboard Principal
- Tela inicial pós-login com visão geral do portfólio.

### Perfil
- Gerenciamento de dados do usuário.

### Startups
- Listagem e detalhes de startups disponíveis para investimento.

### Counter / Trading
- Funcionalidades de negociação de tokens.

### Wallet
- Funcionalidades de depósitos, saques e transferências.

---

## 💻 Tecnologias Utilizadas
* **Linguagem Frontend:** Dart
* **Framework:** Flutter
* **Linguagem Backend:** TypeScript/Node.js
* **Banco de Dados:** Firestore

---

## 📂 Estrutura de Diretórios (Visão Geral)

```text
lib/
 ├── autentication/      # Módulo de Autenticação
 │   ├── components/     # Widgets reutilizáveis (CpfField, PasswordField, etc.)
 │   └── pages/          # Telas de Login e Signup
 ├── dashboard/          # Módulo da Tela Principal do usuário logado
 │   └── home.dart       # Tela principal do Dashboard
 ├── startups/           # Módulo de Startups
 ├── tokens/             # Módulo de Tokens e Trading
 └── main.dart           # Ponto de entrada do aplicativo
```

---

## ⚙️ Como Executar o Projeto

Certifique-se de ter o ambiente [Flutter instalado](https://docs.flutter.dev/get-started/install) na sua máquina.

1. Clone o repositório:
   ```bash
   git clone https://github.com/Jpaulo06972/ES-PI3-2026-T2-G09.git
   ```
2. Navegue até a pasta do projeto:
   ```bash
   cd ES-PI3-2026-T2-G09
   ```
3. Baixe as dependências:
   ```bash
   flutter pub get
   ```
4. Execute o aplicativo (usando um emulador ou dispositivo físico conectado):
   ```bash
   flutter run
   ```
