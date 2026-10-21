# PetCare360 — Banco de Dados

Banco de dados do PetCare360 para registrar pets, dispositivos, leituras de sensores e alertas. Os dados são criados no Oracle, exportados em JSON e importados no MongoDB para consulta em documentos.

## Tecnologias utilizadas

- **Oracle SQL e PL/SQL:** tabelas, relacionamentos, package, gatilho e testes.
- **MongoDB 8 e Mongosh:** coleção de documentos, validação e índices.
- **SQL Developer:** execução do script Oracle.

## Funcionalidades principais

1. Carga de exemplo com usuários, pets, dispositivos, sensores e alertas.
2. Classificação de leituras, inserção de sensores, auditoria e tratamento de erros no package `PKG_PETCARE360`.
3. Exportação dos dados relacionais para JSON e importação na coleção `petcare360.pets`.

## Pré-requisitos

- Acesso a um schema Oracle com permissão para criar tabelas, sequências, packages e gatilhos.
- SQL Developer, SQLcl ou SQL*Plus para executar o script Oracle.
- MongoDB em execução e `mongosh` instalado. A importação foi testada com MongoDB 8.0 e Mongosh 2.13.

## Como executar

**1. Oracle:** abra `PetCare360_Sprint4_Completo.sql` no SQL Developer e execute **o arquivo inteiro com F5**. O script cria os objetos, carrega os dados, executa os testes e gera `03_dataset_petcare360_exportado.json`.

> **Atenção:** o script remove e recria as tabelas e os dados de exemplo. Execute-o apenas em um schema preparado para essa carga.

**2. JSON:** confirme que `03_dataset_petcare360_exportado.json` está na mesma pasta de `04_mongodb_import.js`. O arquivo contém cinco pets.

**3. MongoDB:** no macOS com instalação via Homebrew, inicie o serviço:

```bash
brew services start mongodb-community@8.0
```

No terminal, entre na pasta do projeto e importe o JSON:

```bash
cd /Users/rafaelpascotte/Fiap/ArquivosSprint04/Sprint04_Database_Entrega
mongosh "mongodb://localhost:27017" 04_mongodb_import.js
```

O resultado esperado é `totalDocuments: 5`. Repetir a importação atualiza os mesmos pets, sem duplicá-los.

## Uso principal e verificação

Após executar o SQL, consulte um pet no Oracle:

```sql
SELECT PKG_PETCARE360.FN_EXPORTAR_DATASET_JSON(1) FROM DUAL;
```

Confira o total de documentos no MongoDB:

```bash
mongosh "mongodb://localhost:27017" --eval "db.getSiblingDB('petcare360').pets.countDocuments({})"
```

No VS Code, a extensão **MongoDB for VS Code** também permite abrir `petcare360 → pets` usando a conexão `mongodb://localhost:27017`. Os modelos lógico e físico estão nos PDFs da pasta; os três scripts SQL antigos estão guardados em `fontes_sql_originais/`.

## Autores e licença

| Integrante | RM |
| --- | ---: |
| Leonardo Zerbinatti de Sales | 562992 |
| Luis Guilherme Borges Silva | 566548 |
| Rafael de Freitas Moraes | 563210 |
| Rafael Pascotte Mercadante | 564928 |


