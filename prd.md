# Documento de Requisitos do Produto (PRD) — FICAI 4.0

**Sistema de Ficha de Comunicação de Aluno Infrequente**  
**Secretaria Municipal de Educação de Itaguaí (SMEDU / CPD)**  
*Versão Atual: 4.2.1 — Atualizado em: 26/08/2026*

---

## 1. Visão Geral do Produto

O **FICAI 4.0** é a plataforma oficial da Secretaria Municipal de Educação de Itaguaí (SMEDU) destinada à identificação, acompanhamento, intervenção e controle da evasão e infrequência escolar na Rede Municipal de Ensino.

O sistema integra e consolida os fluxos intersetoriais entre:
- **Unidades Escolares** (Professores, Orientadores Educacionais e Direção);
- **Rede de Apoio à Escola (RAE)** e Assistência Social (CRAS/CREAS);
- **Conselho Tutelar de Itaguaí**;
- **Promotorias de Justiça da Infância e da Juventude** (Ministério Público).

---

## 2. Objetivos Principais

1. **Combate Ativo à Evasão**: Identificar alunos infrequentes nos estágios iniciais de faltas antes da consolidação do abandono escolar.
2. **Padronização Legal e Documental**: Emissão do espelho oficial da FICAI em formato padrão A4 (1 página retrato) para arquivamento e trâmite legal.
3. **Rastreabilidade e Histórico Contínuo**: Linha do tempo digital auditável que recebe novos fatos, visitas e providências mesmo após a geração inicial da ficha.
4. **Imutabilidade e Registro Permanente**: FICAIs canceladas possuem bloqueio definitivo contra edições, preservando a integridade jurídica das informações auditadas.
5. **Alta Disponibilidade e Offline-First**: Operação local resiliente através de IndexedDB combinada com sincronização em nuvem via Supabase.
6. **Roteamento e Georreferenciamento Escolar**: Visualização cartográfica com traçado viário real (ex: BR-101 / Rodovia Rio-Santos) entre a unidade escolar e o endereço residencial do aluno.

---

## 3. Identidade Visual & Design System

- **Tipografia Universal**: Família tipográfica **Alexandria** (pesos de 100 a 900) aplicada em toda a aplicação (títulos, tabelas, formulários, modais e botões).
- **Paleta de Cores**:
  - *Navy Municipal*: `#071a2f`, `#0c2138`, `#15365a`
  - *Primary Blue*: `#0066cc`, `#0877c9`
  - *Accent Gold*: `#b8860b`, `#ffd700`
  - *Status*: Alerta Crítico (Vermelho `#ef4444`), Aviso (Amarelo `#f59e0b`), Conselho Tutelar (Roxo `#8b5cf6`), Sucesso/Retorno (Verde `#10b981`).
- **Cards de Estatísticas (Stat-Cards)**:
  - Dimensões compactas e proporcionais com altura mínima harmonizada (116px), padding otimizado (14px 14px 12px), tipografia balanceada (25px) e badges/tags contextuais (`Ativo`, `Principal`, `Social`, `Saúde`, `Alerta`, `Sucesso`).
- **Aparência e Efeitos**:
  - Suporte completo a **Modo Claro** e **Modo Noturno** (*Dark Mode*).
  - Componentes com profundidade suave, *glassmorphism*, bordas translúcidas e caixas *inset*.
- **Mecanismo Universal de Tooltips**:
  - Engine própria em JS (`initTooltipEngine`) com posicionamento flutuante automático (`top`, `bottom`, `left`, `right`), setas direcionais dinâmicas e proteção contra estouro de tela (*viewport bounds detection*).

---

## 4. Módulos e Funcionalidades

### 4.1 Dashboard
- **Painel de Estatísticas**:
  - Casos Ativos, Falta de Motivação, Trabalho Familiar, Doença / Saúde, Alunos Desistentes e FICAIs Finalizadas com tags e tendências semanais recalculadas em tempo real do banco de dados.
- **Controle de Evasões / Frequência (Layout Split Dual-Column)**:
  - **Barra de Filtros Superior**:
    - Campo de busca global (*live search*): aluno, documento ou responsável;
    - Dropdowns customizados por Turmas (filtro por ano escolar, ex: 8º Ano), Situações e Períodos;
    - Reset rápido e foco com feedback visual.
  - **Coluna 1 — Recebidos CT**:
    - Contador dinâmico de documentos recebidos;
    - Selection All e atalho direto para prontuário completo.
  - **Coluna 2 — Gerados**:
    - Contador dinâmico de documentos gerados;
    - Tags coloridas por status e links para prontuário.

### 4.2 Gerar FICAI
- **Gerador Automático Sequencial de Número FICAI (`00001/YYYY`)**:
  - Algoritmo conectado à tabela `ficais_sequencial` do Supabase e IndexedDB;
  - Reinicia automaticamente a contagem a partir de `00001` a cada novo ano letivo (ex: `00001/2026`);
  - Selo interativo `[✨ Auto]` e botão de recálculo dinâmico `[🔄]`.
- **Formulário Passo a Passo em 6 Seções**:
  1. *Escola e Aluno*: Seleção da escola, autocompletar de dados cadastrais, endereço e responsáveis.
  2. *Situação Escolar*: Turma, turno, modalidade, período de faltas e comunicação.
  3. *Procedimentos da Escola*: Checkboxes com datas de contatos, visitas e reuniões.
  4. *Motivos e Situação*: Constatação dos motivos de ausência, vulnerabilidades sociais e observações.
  5. *Diagnóstico da Evasão*: Grupos diagnósticos (Pedagógico, Familiar, Psicossocial, Saúde).
  6. *Revisão e Impressão*: Visualização do espelho oficial A4 e emissão de PDF.

### 4.3 Modal de Informações da FICAI & Georreferenciamento
- **Layout Premium Fiel ao Design System**:
  - Cabeçalho em degradê *Dark Navy* com avatar do estudante, estatísticas em caixas *inset*, vulnerabilidades e procedimentos.
  - Linha do tempo auditável de acompanhamento pós-geração.
  - Bloqueio automático de formulário de novos lançamentos em FICAIs canceladas.
- **Mapeamento Cartográfico & Roteamento Viário Real**:
  - MapLibre GL + OSRM para traçado viário real (BR-101 / Rodovia Rio-Santos contornando o litoral), exibindo quilometragem (~21.6 km) e tempo estimado (~21 min).

### 4.4 Conselho Tutelar & RAE
- Painel de controle de diligências com stat-cards dedicados (`Aguardando Recebimento`, `Em Diligência`, `Prazo de Retorno`, `Devolvidas à Escola`);
- Formulário e modal de registro de pareceres e devoluções intersetoriais sincronizados com o Dashboard.

### 4.5 Encerramento e Reabertura de Casos
- Justificativa formal de arquivamento por motivo legal (Reintegração, Mudança de Domicílio, Transferência, etc.);
- Tabela de casos arquivados com funcionalidade de reabertura e reativação imediata no formulário.

### 4.6 Cancelamento de FICAI & Imutabilidade Permanente Auditada
- **Módulo Dedicado (`#view-cancelamento`)**:
  - Layout simplificado focado diretamente no formulário de cancelamento com stepper 1-2-3;
  - Remoção dos campos duplicados de busca superior e do card "Histórico da FICAI selecionada";
  - Mini-tabela de resumo com dados zerados/limpos por padrão (`—`) e nova coluna **"Última atualização"** (`DD/MM/YYYY HH:mm`);
  - Barra de pesquisa dedicada no rodapé auditável para busca instantânea no histórico de canceladas (`#cancAuditSearchInput`).
- **Bloqueio Rigoroso de Edição**:
  - FICAIs canceladas possuem **Registro Permanente Auditado** imutável;
  - O sistema impede a edição de dados no formulário principal (`saveFicaiDatabase`), exibe o aviso em banner vermelho (`#canceledFicaiFormWarning`) e desabilita os controles de formulário e novos registros no prontuário.

### 4.7 Configurações & Catálogos
- Módulo de gerenciamento de catálogos:
  - Unidades Escolares;
  - Turmas, Turnos e Anos Letivos (com importação de 428 turmas reais);
  - Procedimentos da Escola, Motivos e Diagnósticos.

---

## 5. Arquitetura Técnica & Banco de Dados

### 5.1 Front-end
- **Tecnologias**: HTML5 Semântico, CSS3 Moderno (Vanilla com Variáveis CSS), JavaScript Vanilla ES6+.
- **Fontes & Ícones**: Google Fonts (Alexandria) e Font Awesome 6.
- **Mapas & Roteamento**: MapLibre GL 5.x, OpenFreeMap Tiles, OSRM Routing API.

### 5.2 Camada de Dados Local
- **IndexedDB**: Banco local `FICAI4LocalDB` (versão 1) com `students` e `ficais`.

### 5.3 Camada Cloud (Supabase)
- **Instância**: `https://ojvxsrvmmkjxfgyczypm.supabase.co`
- **Tabelas Relacionais Ativas**:
  - `escolas`: Unidades escolares de Itaguaí;
  - `turmas`: Cadastro oficial com 428 turmas municipais;
  - `alunos`: Cadastro de estudantes;
  - `ficais`: Fichas registradas;
  - `ficais_sequencial`: Controle do gerador de número inicial `00001/YYYY` por ano letivo;
  - `procedimentos_realizados`, `motivos_ausencia`, `diagnosticos_evasao`;
  - `historico_acompanhamento`, `encaminhamentos_ct`, `atuacao_promotoria`;
  - `encerramentos_ficais`: Registro oficial de arquivamentos e cancelamentos;
  - `logs_sistema`: Registros auditáveis de segurança e operacionais.
- Políticas de Row Level Security (RLS) habilitadas.

---

## 6. Histórico de Alterações e Implementações (Changelog)

| Data | Versão | Descrição da Implementação |
| :--- | :--- | :--- |
| **19/08/2026** | `4.0.0` | Criação do protótipo base da FICAI 4.0 com IndexedDB e espelho A4 de impressão. |
| **19/08/2026** | `4.0.1` | Configuração do schema relacional no Supabase (`supabase_schema.sql` e `supabase_client.js`). |
| **22/08/2026** | `4.0.5` | Criação e estilização do módulo de **Encerramento e Reabertura de Casos**, com arquivamento formal e restauração completa de dados no wizard. |
| **22/08/2026** | `4.0.6` | Implementação do mapa interativo de geolocalização da rota Escola ➔ Residência do Aluno no Modal de Informações da FICAI via MapLibre GL. |
| **23/08/2026** | `4.1.0` | **Redesenho e Ajuste Dimensional dos Stat-Cards**: Otimização do grid e proporções visuais (116px de altura mínima, padding compacto, tipografia de 25px e tags de status enriquecidas) no Dashboard e na tela do Conselho Tutelar. |
| **23/08/2026** | `4.1.0` | **Roteamento Viário Real no Mapa (BR-101 / Rio-Santos)**: Integração com a API OSRM e fallback viário de alta resolução que contorna o litoral pela Rodovia Rio-Santos (sem linhas retas cortando o mar), calculando distância (~21.6 km) e tempo de percurso (~21 min) precisos. |
| **23/08/2026** | `4.1.0` | **Sincronização e Validação do Banco de Dados**: Verificação de consistência estatística e integração com IndexedDB e Supabase. |
| **23/08/2026** | `4.1.1` | **Cálculo Dinâmico dos Stat-Cards em Tempo Real**: Ativação do recálculo automático contínuo de todos os cards de estatísticas a partir do banco de dados (IndexedDB e Supabase). |
| **26/08/2026** | `4.2.0` | **Gerador Sequencial Anual (`00001/YYYY`)**: Criação da tabela `ficais_sequencial` no Supabase com reinício automático da numeração a cada novo ano letivo. |
| **26/08/2026** | `4.2.0` | **Refatoração da Tela de Cancelamento de FICAI**: Layout otimizado em 2 colunas, busca flexível por N.º FICAI, Aluno, Turma ou Status, remoção de dados fictícios, inclusão da coluna "Última atualização" e barra de pesquisa no rodapé de históricos cancelados. |
| **26/08/2026** | `4.2.0` | **Imutabilidade e Bloqueio de Edição de FICAIs Canceladas**: Proteção completa contra alterações em FICAIs canceladas (banner de alerta no formulário, bloqueio no salvamento e ocultação de novos lançamentos no prontuário). |
| **26/08/2026** | `4.2.0` | **Sincronização e Carga no Supabase**: População de 428 turmas reais de Itaguaí, criação da tabela `encerramentos_ficais` e limpeza/persistência de logs do sistema. |

---

## 7. Roadmap & Próximas Etapas

- [ ] **Sincronização Bidirecional em Nuvem**: Conexão em segundo plano entre o IndexedDB local e o Supabase via `supabase_client.js`.
- [ ] **Módulo de Controle de Acesso (RBAC)**: Perfis diferenciados para *Escola*, *Orientação Pedagógica*, *SMEDU/Administrador* e *Conselho Tutelar*.
- [ ] **Integração com Diário Digital**: Importação automática de listas de alunos infrequentes com base nas faltas lançadas pelos professores.
- [ ] **Notificações Automatizadas**: Webhooks para avisos via WhatsApp e e-mail para responsáveis e equipe da RAE.
