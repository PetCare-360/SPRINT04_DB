# PetCare360 - Banco de Dados (Sprint 04)

Base Oracle do PetCare360 para tutores, pets, dispositivos, sensores, alertas e acompanhamento veterinario. Um dataset em JSON projeta os dados de cada pet para uma colecao de documentos no MongoDB.

## Tecnologias

- Oracle SQL e PL/SQL: **15 tabelas `TB_*`**, dois packages, trigger, chaves e testes.
- MongoDB 8 e Mongosh: colecao `petcare360.pets`, validacao e indices.
- SQL Developer, SQLcl ou SQL*Plus para executar o SQL.

## Estrutura

| Grupo | Tabelas |
| --- | --- |
| Nucleo original | `TB_USER`, `TB_PET`, `TB_DEVICE`, `TB_SENSOR_DATA`, `TB_ALERT`, `TB_AUTH`, `TB_LOG_ERRO`, `TB_AUDITORIA_SENSOR` |
| Complemento para o Java | `TB_ROLE`, `TB_USER_ROLE`, `TB_PET_VETERINARIAN`, `TB_ALERT_HISTORY`, `TB_PET_MESSAGE`, `TB_APPOINTMENT`, `TB_CARE_RECOMMENDATION` |

`PKG_PETCARE360` mantem classificacao, leitura, auditoria e exportacao JSON. `PKG_PETCARE360_CLINICO` oferece funcoes de consulta e vinculo veterinario; suas procedures atribuem perfis, vinculam veterinarios, enviam mensagens, agendam consultas, criam recomendacoes e mudam o estado de alertas. As falhas sao registradas em `TB_LOG_ERRO` e propagadas ao chamador. Os testes de escrita usam `SAVEPOINT` e `ROLLBACK`, preservando apenas a carga inicial.

O modelo logico e o fisico estao nos PDFs desta pasta. A estrutura usa apenas tabelas com prefixo `TB_`. O Java ainda precisa trocar os mapeamentos `SJ_*` pelos nomes, colunas e valores deste schema; a alteracao desta entrega **nao altera automaticamente o projeto Java**.

## Como executar

1. Use um **schema Oracle de teste** com permissao para criar tabelas, indices, sequences, packages e trigger.
2. Abra `PetCare360_Sprint4_Completo.sql` e execute o arquivo inteiro como **script** (`F5` no SQL Developer). Ele apaga e recria seus objetos `TB_*`, carrega exemplos, compila as rotinas, roda os testes e exporta o JSON. **Nao execute em uma base com dados que queira preservar.**
3. Confira no log `Funcoes clinicas: OK`, `Procedures clinicas: OK`, `Excecao e log clinico: OK` e nenhuma linha de objeto invalido.
4. Coloque o JSON gerado pelo `SPOOL` com o nome `03_dataset_petcare360_exportado.json` nesta pasta. A localizacao do `SPOOL` depende do diretorio de trabalho do cliente SQL. O JSON versionado na pasta e uma **amostra alinhada com a carga inicial**; para entrega final, regenere-o no Oracle.
5. Inicie o MongoDB e importe:

```bash
brew services start mongodb-community@8.0
cd /Users/rafaelpascotte/Fiap/ArquivosSprint04/Sprint04_Database
mongosh "mongodb://localhost:27017" 04_mongodb_import.js
```

A importacao deve mostrar `totalDocuments: 5`. Reexecutar atualiza os cinco documentos. As senhas e os tokens de autenticacao nao sao enviados ao MongoDB.

## Consulta rapida

```sql
SELECT PKG_PETCARE360.FN_EXPORTAR_DATASET_JSON(1) FROM DUAL;
SELECT PKG_PETCARE360_CLINICO.FN_TOTAL_CONSULTAS_PET(1) FROM DUAL;
SELECT object_name, object_type, status FROM user_objects
WHERE object_name IN ('PKG_PETCARE360', 'PKG_PETCARE360_CLINICO', 'TRG_AUDITORIA_SENSOR');
```

```bash
mongosh "mongodb://localhost:27017" --eval "db.getSiblingDB('petcare360').pets.countDocuments({})"
```

O JSON `schemaVersion: 2.0` incorpora veterinarios, mensagens, consultas, recomendacoes e historico dos alertas dentro de cada pet. O importador converte datas para BSON Date e cria indices para consultas por dono, veterinario, alertas e agendamentos.

## Integrantes

| Integrante | RM |
| --- | ---: |
| Leonardo Zerbinatti de Sales | 562992 |
| Luis Guilherme Borges Silva | 566548 |
| Rafael de Freitas Moraes | 563210 |
| Rafael Pascotte Mercadante | 564928 |
