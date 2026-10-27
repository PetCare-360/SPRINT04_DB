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

## Como executar

1. Use um **schema Oracle de teste** com permissao para criar tabelas, indices, sequences, packages e trigger.
2. Instale o Oracle SQL Developer para Windows, conecte-se ao schema de teste, abra `PetCare360_Sprint4_Completo.sql` e execute o arquivo inteiro como **script** (`F5`). Ele apaga e recria seus objetos `TB_*`, carrega exemplos, compila as rotinas, roda os testes e exporta o JSON. **Nao execute em uma base com dados que queira preservar.**
3. Confira no log `Funcoes clinicas: OK`, `Procedures clinicas: OK`, `Excecao e log clinico: OK` e nenhuma linha de objeto invalido.
4. Coloque o JSON gerado pelo `SPOOL` com o nome `03_dataset_petcare360_exportado.json` nesta pasta. A localizacao do `SPOOL` depende do diretorio de trabalho do cliente SQL. O JSON versionado na pasta e uma **amostra alinhada com a carga inicial**; para entrega final, regenere-o no Oracle.
5. No Windows, instale o MongoDB Community Server 8.0 pelo instalador MSI e o MongoDB Shell (`mongosh`) pelo instalador MSI. Durante a instalacao do servidor, mantenha a opcao de instalar como servico. O servico normalmente inicia ao final da instalacao; se precisar inicia-lo manualmente, abra o PowerShell como administrador e rode:

```powershell
Start-Service MongoDB
```

6. Abra o PowerShell na pasta do projeto e importe o dataset:

```powershell
cd "C:\caminho\para\Sprint04_Database"
mongosh "mongodb://localhost:27017" .\04_mongodb_import.js
```

Para confirmar que as ferramentas estao instaladas, use `mongod --version` e `mongosh --version`. Se o comando `mongosh` nao for reconhecido, feche e abra o PowerShell novamente ou adicione a pasta do `mongosh.exe` ao `PATH` do Windows.

A importacao deve mostrar `totalDocuments: 5`. Reexecutar atualiza os cinco documentos. As senhas e os tokens de autenticacao nao sao enviados ao MongoDB.

## Usar o MongoDB pelo VS Code

1. Abra esta pasta no VS Code.
2. Na extensao **MongoDB for VS Code**, procure e instale a extensao oficial da MongoDB. Se ainda nao tiver instalado, abra a aba de extensoes com `Ctrl+Shift+X` e pesquise por `MongoDB for VS Code`.
3. Na barra lateral, abra **MongoDB** e escolha **Add Connection** ou **Connect with Connection String**.
4. Informe a conexao local `mongodb://localhost:27017` e conecte. O servico MongoDB do Windows precisa estar iniciado.
5. Na lista de conexoes, expanda `petcare360` e depois `pets` para navegar pelos documentos importados.

Para testar uma consulta, crie um **MongoDB Playground** pela paleta de comandos (`Ctrl+Shift+P`) e execute:

```javascript
use('petcare360');
db.pets.find({}, { _id: 0, petId: 1, name: 1, owner: 1 }).limit(5);
```

Consulte o guia oficial da [extensao MongoDB para VS Code](https://www.mongodb.com/docs/mongodb-vscode/) para instalar a extensao, conectar e explorar databases e collections.

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
