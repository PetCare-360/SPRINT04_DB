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

O modelo logico e o fisico estao nos PDFs desta pasta. A estrutura usa apenas tabelas com prefixo `TB_`. A aplicacao Java correspondente usa este schema Oracle `TB_*`; configure-a para apontar para a mesma conta Oracle.

## Executar o Oracle

1. Use um **schema Oracle de teste** com permissao para criar tabelas, indices, sequences, packages e trigger.
2. No Oracle SQL Developer, conecte-se ao schema de teste, abra `PetCare360_Sprint4_Completo.sql` e execute o arquivo inteiro como **script** (`F5`). Ele apaga e recria os objetos `TB_*`, carrega exemplos, compila as rotinas, roda os testes e exporta o JSON. **Nao execute em uma base com dados que queira preservar.**
3. Confira no log `Funcoes clinicas: OK`, `Procedures clinicas: OK`, `Excecao e log clinico: OK` e nenhuma linha de objeto invalido.
4. Coloque o JSON gerado pelo `SPOOL` nesta pasta com o nome `03_dataset_petcare360_exportado.json`. A localizacao depende do diretorio de trabalho do cliente SQL. O JSON versionado e uma **amostra alinhada com a carga inicial**; para a entrega final, gere-o novamente no Oracle.

## MongoDB no Windows pelo VS Code

Este passo a passo usa o projeto PetCare360. O MongoDB Server fica instalado e rodando no Windows; o VS Code se conecta a ele pela extensão oficial. O arquivo JSON é importado para o banco pelo script `04_mongodb_import.js`.

### 1. Instale o MongoDB

Se ainda não estiver instalado, baixe o **MongoDB Community Server** para Windows e, durante a instalação, mantenha a opção de instalá-lo como serviço. O serviço normalmente inicia ao terminar a instalação.

Instale também o **MongoDB Shell (mongosh)**: ele é separado do servidor. Se o Windows não reconhecer `mongosh` depois da instalação, feche e reabra o VS Code para atualizar o terminal. [Instalação do MongoDB no Windows](https://www.mongodb.com/docs/v8.0/tutorial/install-mongodb-on-windows/) · [Instalação do mongosh](https://www.mongodb.com/docs/mongodb-shell/install/)

### 2. Abra o projeto no VS Code

No VS Code, use **File → Open Folder** e selecione a pasta do projeto. Depois, abra **Terminal → New Terminal** e confira se estão nela os arquivos:

- `04_mongodb_import.js`
- `03_dataset_petcare360_exportado.json`

No terminal integrado, verifique se o serviço está rodando:

```powershell
Get-Service MongoDB
```

Se o estado não for `Running`, abra o PowerShell como administrador e inicie o serviço:

```powershell
Start-Service MongoDB
```

### 3. Importe o JSON

No terminal do VS Code, entre na pasta que contém os arquivos. Troque o caminho de exemplo pelo caminho real:

```powershell
cd "C:\Users\SEU_USUARIO\Downloads\SPRINT04_DB-main"
```

Execute o script:

```powershell
mongosh "mongodb://localhost:27017" .\04_mongodb_import.js
```

A importação concluída deve mostrar `totalDocuments: 5`. Na primeira execução, podem aparecer cinco documentos em `upserted`; ao repetir, o script atualiza os documentos existentes.

### Se `mongosh` não for reconhecido

No bate-papo, o Shell foi encontrado neste caminho. Você pode chamá-lo diretamente:

```powershell
& "$env:LOCALAPPDATA\Programs\mongosh\mongosh.exe" "mongodb://localhost:27017" .\04_mongodb_import.js
```

### 4. Conecte o VS Code ao MongoDB

1. Pressione **Ctrl + Shift + X** e instale a extensão oficial **MongoDB for VS Code**, publicada pela MongoDB. [Guia de instalação da extensão](https://www.mongodb.com/docs/mongodb-vscode/install/)
2. Abra a seção **MongoDB** na barra lateral e escolha **Add Connection**.
3. Informe a conexão local:

   ```text
   mongodb://localhost:27017
   ```

4. Expanda a conexão, o banco `petcare360` e a coleção `pets`.

### 5. Consulte os documentos

Pressione **Ctrl + Shift + P**, procure **MongoDB: Create MongoDB Playground** e execute:

```javascript
use('petcare360');

db.pets.find(
  {},
  { _id: 0, petId: 1, name: 1, owner: 1 }
).limit(5);
```

O Playground mostra os resultados dentro do VS Code. [Guia de Playgrounds](https://www.mongodb.com/docs/mongodb-vscode/playgrounds/)

### Se algo der errado

- **Conexão recusada:** confira se `Get-Service MongoDB` mostra `Running`.
- **`mongosh` não reconhecido:** tente o caminho completo acima ou reabra o VS Code.
- **Arquivo não encontrado:** confira a pasta atual com `Get-Location` e liste os arquivos com `dir`.
- **Nenhum documento na consulta:** confira se a importação terminou e se está consultando `petcare360.pets`.

## Consulta rapida

```sql
SELECT PKG_PETCARE360.FN_EXPORTAR_DATASET_JSON(1) FROM DUAL;
SELECT PKG_PETCARE360_CLINICO.FN_TOTAL_CONSULTAS_PET(1) FROM DUAL;
SELECT object_name, object_type, status FROM user_objects
WHERE object_name IN ('PKG_PETCARE360', 'PKG_PETCARE360_CLINICO', 'TRG_AUDITORIA_SENSOR');
```

```powershell
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
