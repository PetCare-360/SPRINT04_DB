-- PetCare360 - Sprint 4 - script Oracle unificado
-- Executar como script (F5 no SQL Developer) no schema de entrega.
-- Este script remove e recria tabelas e dados de demonstracao.
-- Para gerar o JSON na mesma pasta, inicie a ferramenta SQL nessa pasta.
-- Ordem: estrutura e carga -> package e trigger -> testes -> exportacao.

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET SERVEROUTPUT ON;
SET VERIFY OFF;
SET DEFINE OFF;

PROMPT ======================================================
PROMPT ETAPA 1 - ESTRUTURA E CARGA
PROMPT ======================================================
PROMPT 1. LIMPEZA CONTROLADA DOS OBJETOS
PROMPT ======================================================

BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER TRG_AUDITORIA_SENSOR';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -4080 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE PKG_PETCARE360';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -4043 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE PRC_PETS_JSON';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -4043 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE PRC_RESUMO_SENSOR_MANUAL';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -4043 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP FUNCTION FN_CLASSIFICA_SENSOR';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -4043 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP FUNCTION FN_MONTA_JSON_PET';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -4043 THEN RAISE; END IF; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP TABLE TB_AUDITORIA_SENSOR CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE TB_LOG_ERRO CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE TB_AUTH CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE TB_ALERT CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE TB_SENSOR_DATA CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE TB_DEVICE CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE TB_PET CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE TB_USER CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE SQ_LOG_ERRO';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -2289 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE SQ_AUDITORIA_SENSOR';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -2289 THEN RAISE; END IF; END;
/

PROMPT ======================================================
PROMPT 2. CRIACAO DAS TABELAS
PROMPT ======================================================

CREATE TABLE TB_USER (
    user_id       NUMBER(10) NOT NULL,
    user_name     VARCHAR2(255) NOT NULL,
    email         VARCHAR2(255) NOT NULL,
    password_hash VARCHAR2(60) NOT NULL,
    created_at    TIMESTAMP WITH LOCAL TIME ZONE NOT NULL,
    CONSTRAINT TB_USER_PK PRIMARY KEY (user_id),
    CONSTRAINT TB_USER_EMAIL_UN UNIQUE (email)
);

CREATE TABLE TB_PET (
    pet_id          NUMBER(10) NOT NULL,
    pet_name        VARCHAR2(255) NOT NULL,
    age             NUMBER(3) NOT NULL,
    weight          NUMBER(5,2) NOT NULL,
    breed           VARCHAR2(60) NOT NULL,
    created_at      TIMESTAMP WITH LOCAL TIME ZONE NOT NULL,
    tb_user_user_id NUMBER(10) NOT NULL,
    CONSTRAINT TB_PET_PK PRIMARY KEY (pet_id),
    CONSTRAINT TB_PET_TB_USER_FK FOREIGN KEY (tb_user_user_id)
        REFERENCES TB_USER (user_id),
    CONSTRAINT CK_TB_PET_AGE CHECK (age >= 0),
    CONSTRAINT CK_TB_PET_WEIGHT CHECK (weight > 0)
);

CREATE TABLE TB_DEVICE (
    device_id      NUMBER(10) NOT NULL,
    device_status  CHAR(1) NOT NULL,
    device_battery NUMBER(3) NOT NULL,
    last_seen      TIMESTAMP WITH LOCAL TIME ZONE NOT NULL,
    tb_pet_pet_id  NUMBER(10) NOT NULL,
    CONSTRAINT TB_DEVICE_PK PRIMARY KEY (device_id),
    CONSTRAINT TB_DEVICE_PET_UN UNIQUE (tb_pet_pet_id),
    CONSTRAINT TB_DEVICE_TB_PET_FK FOREIGN KEY (tb_pet_pet_id)
        REFERENCES TB_PET (pet_id),
    CONSTRAINT CK_TB_DEVICE_STATUS CHECK (device_status IN ('A', 'I', 'M')),
    CONSTRAINT CK_TB_DEVICE_BATTERY CHECK (device_battery BETWEEN 0 AND 100)
);

CREATE TABLE TB_SENSOR_DATA (
    sensor_id           NUMBER(10) NOT NULL,
    data_hora           TIMESTAMP WITH LOCAL TIME ZONE NOT NULL,
    temperature         NUMBER(4,1) NOT NULL,
    heart_rate          NUMBER(3) NOT NULL,
    activity_level      VARCHAR2(20) NOT NULL,
    latitude            NUMBER(9,7) NOT NULL,
    longitude           NUMBER(10,7) NOT NULL,
    sensor_battery      NUMBER(3) NOT NULL,
    sensor_status       CHAR(1) NOT NULL,
    tb_device_device_id NUMBER(10) NOT NULL,
    CONSTRAINT TB_SENSOR_DATA_PK PRIMARY KEY (sensor_id),
    CONSTRAINT TB_SENSOR_DATA_DEVICE_FK FOREIGN KEY (tb_device_device_id)
        REFERENCES TB_DEVICE (device_id),
    CONSTRAINT CK_TB_SENSOR_TEMPERATURE CHECK (temperature BETWEEN 30 AND 45),
    CONSTRAINT CK_TB_SENSOR_HEART_RATE CHECK (heart_rate BETWEEN 40 AND 220),
    CONSTRAINT CK_TB_SENSOR_ACTIVITY CHECK (activity_level IN ('HIGH', 'MEDIUM', 'LOW')),
    CONSTRAINT CK_TB_SENSOR_STATUS CHECK (sensor_status IN ('A', 'I', 'M')),
    CONSTRAINT CK_TB_SENSOR_BATTERY CHECK (sensor_battery BETWEEN 0 AND 100)
);

CREATE TABLE TB_ALERT (
    alert_id      NUMBER(10) NOT NULL,
    type          VARCHAR2(15) NOT NULL,
    message       VARCHAR2(200) NOT NULL,
    alert_level   VARCHAR2(10) NOT NULL,
    created_at    TIMESTAMP WITH LOCAL TIME ZONE NOT NULL,
    tb_pet_pet_id NUMBER(10) NOT NULL,
    CONSTRAINT TB_ALERT_PK PRIMARY KEY (alert_id),
    CONSTRAINT TB_ALERT_TB_PET_FK FOREIGN KEY (tb_pet_pet_id)
        REFERENCES TB_PET (pet_id),
    CONSTRAINT CK_TB_ALERT_TYPE CHECK (type IN ('ACTIVITY', 'TEMPERATURE')),
    CONSTRAINT CK_TB_ALERT_LEVEL CHECK (alert_level IN ('CRITICAL', 'INFO', 'WARNING'))
);

CREATE TABLE TB_AUTH (
    refresh_token   VARCHAR2(255) NOT NULL,
    expires_at      TIMESTAMP WITH LOCAL TIME ZONE NOT NULL,
    tb_user_user_id NUMBER(10) NOT NULL,
    CONSTRAINT TB_AUTH_PK PRIMARY KEY (refresh_token),
    CONSTRAINT TB_AUTH_TB_USER_FK FOREIGN KEY (tb_user_user_id)
        REFERENCES TB_USER (user_id)
);

CREATE TABLE TB_LOG_ERRO (
    log_id        NUMBER(10) NOT NULL,
    objeto        VARCHAR2(100) NOT NULL,
    usuario       VARCHAR2(100) NOT NULL,
    data_erro     TIMESTAMP NOT NULL,
    codigo_erro   NUMBER,
    mensagem_erro VARCHAR2(4000),
    CONSTRAINT TB_LOG_ERRO_PK PRIMARY KEY (log_id)
);

CREATE TABLE TB_AUDITORIA_SENSOR (
    auditoria_id       NUMBER(10) NOT NULL,
    usuario_oracle     VARCHAR2(100) NOT NULL,
    tipo_operacao      VARCHAR2(10) NOT NULL,
    data_operacao      TIMESTAMP NOT NULL,
    valores_anteriores VARCHAR2(4000),
    valores_novos      VARCHAR2(4000),
    CONSTRAINT TB_AUDITORIA_SENSOR_PK PRIMARY KEY (auditoria_id),
    CONSTRAINT CK_TB_AUDITORIA_OPERACAO CHECK (tipo_operacao IN ('INSERT', 'UPDATE', 'DELETE'))
);

CREATE SEQUENCE SQ_LOG_ERRO START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SQ_AUDITORIA_SENSOR START WITH 1 INCREMENT BY 1 NOCACHE;

PROMPT ======================================================
PROMPT 3. CARGA INICIAL
PROMPT ======================================================

INSERT INTO TB_USER (user_id, user_name, email, password_hash, created_at)
VALUES (1, 'Arthur Correia', 'arthur@email.com', 'senha123', SYSTIMESTAMP);
INSERT INTO TB_USER (user_id, user_name, email, password_hash, created_at)
VALUES (2, 'Gabriel Souza', 'gabriel@email.com', 'senha123', SYSTIMESTAMP);
INSERT INTO TB_USER (user_id, user_name, email, password_hash, created_at)
VALUES (3, 'Jose Ricardo', 'jose@email.com', 'senha123', SYSTIMESTAMP);
INSERT INTO TB_USER (user_id, user_name, email, password_hash, created_at)
VALUES (4, 'Rafael Freitas', 'rafaelfreitas@email.com', 'senha123', SYSTIMESTAMP);
INSERT INTO TB_USER (user_id, user_name, email, password_hash, created_at)
VALUES (5, 'Rafael Pascotte', 'rafaelpascotte@email.com', 'senha123', SYSTIMESTAMP);

INSERT INTO TB_PET (pet_id, pet_name, age, weight, breed, created_at, tb_user_user_id)
VALUES (1, 'Thor', 5, 12.50, 'Golden Retriever', SYSTIMESTAMP, 1);
INSERT INTO TB_PET (pet_id, pet_name, age, weight, breed, created_at, tb_user_user_id)
VALUES (2, 'Pingo', 6, 2.50, 'Yorkshire', SYSTIMESTAMP, 2);
INSERT INTO TB_PET (pet_id, pet_name, age, weight, breed, created_at, tb_user_user_id)
VALUES (3, 'Cookie', 4, 22.50, 'Pitbull', SYSTIMESTAMP, 3);
INSERT INTO TB_PET (pet_id, pet_name, age, weight, breed, created_at, tb_user_user_id)
VALUES (4, 'Mel', 2, 6.80, 'Shih Tzu', SYSTIMESTAMP, 4);
INSERT INTO TB_PET (pet_id, pet_name, age, weight, breed, created_at, tb_user_user_id)
VALUES (5, 'Bob', 6, 15.10, 'Labrador', SYSTIMESTAMP, 5);

INSERT INTO TB_DEVICE (device_id, device_status, device_battery, last_seen, tb_pet_pet_id)
VALUES (1, 'A', 90, SYSTIMESTAMP, 1);
INSERT INTO TB_DEVICE (device_id, device_status, device_battery, last_seen, tb_pet_pet_id)
VALUES (2, 'A', 85, SYSTIMESTAMP, 2);
INSERT INTO TB_DEVICE (device_id, device_status, device_battery, last_seen, tb_pet_pet_id)
VALUES (3, 'M', 55, SYSTIMESTAMP, 3);
INSERT INTO TB_DEVICE (device_id, device_status, device_battery, last_seen, tb_pet_pet_id)
VALUES (4, 'A', 76, SYSTIMESTAMP, 4);
INSERT INTO TB_DEVICE (device_id, device_status, device_battery, last_seen, tb_pet_pet_id)
VALUES (5, 'I', 20, SYSTIMESTAMP, 5);

INSERT INTO TB_SENSOR_DATA (
    sensor_id, data_hora, temperature, heart_rate, activity_level,
    latitude, longitude, sensor_battery, sensor_status, tb_device_device_id
) VALUES (1, SYSTIMESTAMP, 38.5, 120, 'HIGH', -23.550520, -46.633308, 80, 'A', 1);
INSERT INTO TB_SENSOR_DATA (
    sensor_id, data_hora, temperature, heart_rate, activity_level,
    latitude, longitude, sensor_battery, sensor_status, tb_device_device_id
) VALUES (2, SYSTIMESTAMP, 37.9, 95, 'MEDIUM', -23.551000, -46.632000, 78, 'A', 2);
INSERT INTO TB_SENSOR_DATA (
    sensor_id, data_hora, temperature, heart_rate, activity_level,
    latitude, longitude, sensor_battery, sensor_status, tb_device_device_id
) VALUES (3, SYSTIMESTAMP, 39.1, 130, 'HIGH', -23.561684, -46.625378, 75, 'M', 3);
INSERT INTO TB_SENSOR_DATA (
    sensor_id, data_hora, temperature, heart_rate, activity_level,
    latitude, longitude, sensor_battery, sensor_status, tb_device_device_id
) VALUES (4, SYSTIMESTAMP, 36.8, 88, 'LOW', -23.563210, -46.654321, 70, 'A', 4);
INSERT INTO TB_SENSOR_DATA (
    sensor_id, data_hora, temperature, heart_rate, activity_level,
    latitude, longitude, sensor_battery, sensor_status, tb_device_device_id
) VALUES (5, SYSTIMESTAMP, 39.4, 140, 'HIGH', -23.570000, -46.620000, 68, 'I', 5);

INSERT INTO TB_ALERT (alert_id, type, message, alert_level, created_at, tb_pet_pet_id)
VALUES (1, 'TEMPERATURE', 'Temperatura elevada detectada', 'WARNING', SYSTIMESTAMP, 1);
INSERT INTO TB_ALERT (alert_id, type, message, alert_level, created_at, tb_pet_pet_id)
VALUES (2, 'ACTIVITY', 'Atividade intensa detectada', 'INFO', SYSTIMESTAMP, 2);
INSERT INTO TB_ALERT (alert_id, type, message, alert_level, created_at, tb_pet_pet_id)
VALUES (3, 'TEMPERATURE', 'Temperatura critica detectada', 'CRITICAL', SYSTIMESTAMP, 3);
INSERT INTO TB_ALERT (alert_id, type, message, alert_level, created_at, tb_pet_pet_id)
VALUES (4, 'ACTIVITY', 'Baixa atividade detectada', 'WARNING', SYSTIMESTAMP, 4);
INSERT INTO TB_ALERT (alert_id, type, message, alert_level, created_at, tb_pet_pet_id)
VALUES (5, 'TEMPERATURE', 'Temperatura normalizada', 'INFO', SYSTIMESTAMP, 5);

INSERT INTO TB_AUTH (refresh_token, expires_at, tb_user_user_id)
VALUES ('token001', SYSTIMESTAMP + INTERVAL '30' DAY, 1);
INSERT INTO TB_AUTH (refresh_token, expires_at, tb_user_user_id)
VALUES ('token002', SYSTIMESTAMP + INTERVAL '30' DAY, 2);
INSERT INTO TB_AUTH (refresh_token, expires_at, tb_user_user_id)
VALUES ('token003', SYSTIMESTAMP + INTERVAL '30' DAY, 3);
INSERT INTO TB_AUTH (refresh_token, expires_at, tb_user_user_id)
VALUES ('token004', SYSTIMESTAMP + INTERVAL '30' DAY, 4);
INSERT INTO TB_AUTH (refresh_token, expires_at, tb_user_user_id)
VALUES ('token005', SYSTIMESTAMP + INTERVAL '30' DAY, 5);

COMMIT;

PROMPT ======================================================
PROMPT 4. VALIDACAO DA CARGA
PROMPT ======================================================

SELECT 'TB_USER' tabela, COUNT(*) registros FROM TB_USER
UNION ALL SELECT 'TB_PET', COUNT(*) FROM TB_PET
UNION ALL SELECT 'TB_DEVICE', COUNT(*) FROM TB_DEVICE
UNION ALL SELECT 'TB_SENSOR_DATA', COUNT(*) FROM TB_SENSOR_DATA
UNION ALL SELECT 'TB_ALERT', COUNT(*) FROM TB_ALERT
UNION ALL SELECT 'TB_AUTH', COUNT(*) FROM TB_AUTH;

PROMPT ======================================================
PROMPT ETAPA 2 - PACKAGE E GATILHO
PROMPT ======================================================
PROMPT Criando especificacao PKG_PETCARE360...

CREATE OR REPLACE PACKAGE PKG_PETCARE360 AS
    FUNCTION FN_CLASSIFICA_SENSOR (
        p_temperature IN NUMBER,
        p_heart_rate  IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION FN_MONTA_JSON_PET (
        p_usuario        IN VARCHAR2,
        p_pet_id         IN NUMBER,
        p_pet            IN VARCHAR2,
        p_raca           IN VARCHAR2,
        p_peso           IN NUMBER,
        p_device_id      IN NUMBER,
        p_device_status  IN VARCHAR2,
        p_device_battery IN NUMBER
    ) RETURN CLOB;

    FUNCTION FN_EXPORTAR_DATASET_JSON (
        p_pet_id IN TB_PET.pet_id%TYPE DEFAULT NULL
    ) RETURN CLOB;

    PROCEDURE PRC_PETS_JSON (
        p_pet_id IN TB_PET.pet_id%TYPE DEFAULT NULL
    );

    PROCEDURE PRC_RESUMO_SENSOR;

    PROCEDURE PRC_INSERIR_SENSOR (
        p_sensor_id      IN TB_SENSOR_DATA.sensor_id%TYPE,
        p_device_id      IN TB_DEVICE.device_id%TYPE,
        p_temperature    IN TB_SENSOR_DATA.temperature%TYPE,
        p_heart_rate     IN TB_SENSOR_DATA.heart_rate%TYPE,
        p_activity_level IN TB_SENSOR_DATA.activity_level%TYPE,
        p_latitude       IN TB_SENSOR_DATA.latitude%TYPE,
        p_longitude      IN TB_SENSOR_DATA.longitude%TYPE,
        p_battery        IN TB_SENSOR_DATA.sensor_battery%TYPE,
        p_sensor_status  IN TB_SENSOR_DATA.sensor_status%TYPE DEFAULT 'A'
    );

    -- Ponto unico chamado pela trigger. A trigger permanece standalone porque
    -- o Oracle nao permite declarar triggers dentro de packages.
    PROCEDURE PRC_AUDITAR_SENSOR (
        p_operacao          IN VARCHAR2,
        p_valores_anteriores IN VARCHAR2,
        p_valores_novos      IN VARCHAR2
    );
END PKG_PETCARE360;
/

SHOW ERRORS PACKAGE PKG_PETCARE360;

PROMPT Criando corpo PKG_PETCARE360...

CREATE OR REPLACE PACKAGE BODY PKG_PETCARE360 AS

    PROCEDURE PRC_REGISTRAR_ERRO (
        p_objeto   IN VARCHAR2,
        p_codigo   IN NUMBER,
        p_mensagem IN VARCHAR2
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO TB_LOG_ERRO (
            log_id, objeto, usuario, data_erro, codigo_erro, mensagem_erro
        ) VALUES (
            SQ_LOG_ERRO.NEXTVAL,
            SUBSTR(p_objeto, 1, 100),
            SYS_CONTEXT('USERENV', 'SESSION_USER'),
            SYSTIMESTAMP,
            p_codigo,
            SUBSTR(p_mensagem, 1, 4000)
        );
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20998,
                'Falha ao registrar erro de ' || p_objeto || ': ' || SQLERRM);
    END PRC_REGISTRAR_ERRO;

    PROCEDURE PRC_TRATAR_ERRO (
        p_objeto        IN VARCHAR2,
        p_codigo        IN NUMBER,
        p_mensagem      IN VARCHAR2,
        p_codigo_padrao IN NUMBER
    ) IS
    BEGIN
        PRC_REGISTRAR_ERRO(p_objeto, p_codigo, p_mensagem);

        IF p_codigo BETWEEN -20999 AND -20000 THEN
            RAISE_APPLICATION_ERROR(p_codigo, SUBSTR(p_mensagem, 1, 1800));
        END IF;

        RAISE_APPLICATION_ERROR(p_codigo_padrao,
            SUBSTR(p_objeto || ': ' || p_mensagem, 1, 1800));
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20999 AND -20000 THEN
                RAISE;
            END IF;
            RAISE_APPLICATION_ERROR(-20997,
                SUBSTR('Falha no tratamento de erro de ' || p_objeto || ': ' || SQLERRM, 1, 1800));
    END PRC_TRATAR_ERRO;

    FUNCTION FN_CLASSIFICA_SENSOR (
        p_temperature IN NUMBER,
        p_heart_rate  IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        IF p_temperature IS NULL THEN
            RAISE_APPLICATION_ERROR(-20101, 'Temperatura obrigatoria.');
        END IF;
        IF p_temperature < 30 OR p_temperature > 45 THEN
            RAISE_APPLICATION_ERROR(-20102, 'Temperatura fora da faixa de 30 a 45 graus.');
        END IF;
        IF p_heart_rate IS NULL OR p_heart_rate < 40 OR p_heart_rate > 220 THEN
            RAISE_APPLICATION_ERROR(-20103, 'Frequencia cardiaca fora da faixa de 40 a 220 bpm.');
        END IF;

        IF p_temperature >= 39 OR p_heart_rate >= 135 THEN
            RETURN 'CRITICO';
        ELSIF p_temperature >= 38 OR p_heart_rate >= 120 THEN
            RETURN 'ALERTA';
        END IF;
        RETURN 'NORMAL';
    EXCEPTION
        WHEN OTHERS THEN
            PRC_TRATAR_ERRO('PKG_PETCARE360.FN_CLASSIFICA_SENSOR', SQLCODE, SQLERRM, -20901);
            RETURN NULL;
    END FN_CLASSIFICA_SENSOR;

    FUNCTION FN_MONTA_JSON_PET (
        p_usuario        IN VARCHAR2,
        p_pet_id         IN NUMBER,
        p_pet            IN VARCHAR2,
        p_raca           IN VARCHAR2,
        p_peso           IN NUMBER,
        p_device_id      IN NUMBER,
        p_device_status  IN VARCHAR2,
        p_device_battery IN NUMBER
    ) RETURN CLOB IS
        v_json CLOB;
    BEGIN
        IF p_usuario IS NULL OR p_pet_id IS NULL OR p_pet IS NULL OR p_raca IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'Usuario e dados do pet sao obrigatorios.');
        END IF;
        IF p_peso IS NULL OR p_peso <= 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Peso deve ser maior que zero.');
        END IF;
        IF p_device_id IS NULL OR p_device_status IS NULL THEN
            RAISE_APPLICATION_ERROR(-20003, 'Dados do dispositivo sao obrigatorios.');
        END IF;
        IF p_device_battery IS NULL OR p_device_battery NOT BETWEEN 0 AND 100 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Bateria deve estar entre 0 e 100.');
        END IF;

        SELECT JSON_OBJECT(
            'petId' VALUE p_pet_id,
            'name' VALUE p_pet,
            'breed' VALUE p_raca,
            'weight' VALUE p_peso,
            'ownerName' VALUE p_usuario,
            'device' VALUE JSON_OBJECT(
                'deviceId' VALUE p_device_id,
                'status' VALUE p_device_status,
                'battery' VALUE p_device_battery
            )
            RETURNING CLOB
        ) INTO v_json FROM DUAL;

        RETURN v_json;
    EXCEPTION
        WHEN OTHERS THEN
            PRC_TRATAR_ERRO('PKG_PETCARE360.FN_MONTA_JSON_PET', SQLCODE, SQLERRM, -20902);
            RETURN NULL;
    END FN_MONTA_JSON_PET;

    FUNCTION FN_EXPORTAR_DATASET_JSON (
        p_pet_id IN TB_PET.pet_id%TYPE DEFAULT NULL
    ) RETURN CLOB IS
        v_json CLOB;
        v_count NUMBER;
    BEGIN
        IF p_pet_id IS NOT NULL AND p_pet_id <= 0 THEN
            RAISE_APPLICATION_ERROR(-20201, 'pet_id deve ser positivo.');
        END IF;

        SELECT COUNT(*)
        INTO v_count
        FROM TB_PET
        WHERE p_pet_id IS NULL OR pet_id = p_pet_id;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20203, 'Nenhum pet encontrado para exportacao.');
        END IF;

        SELECT JSON_OBJECT(
            'dataset' VALUE 'petcare360-pets',
            'schemaVersion' VALUE '1.0',
            'generatedAt' VALUE TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS.FF3TZH:TZM'),
            'pets' VALUE COALESCE((
                SELECT JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'petId' VALUE p.pet_id,
                        'name' VALUE p.pet_name,
                        'age' VALUE p.age,
                        'weight' VALUE p.weight,
                        'breed' VALUE p.breed,
                        'createdAt' VALUE TO_CHAR(p.created_at, 'YYYY-MM-DD"T"HH24:MI:SS.FF3'),
                        'owner' VALUE JSON_OBJECT(
                            'userId' VALUE u.user_id,
                            'name' VALUE u.user_name,
                            'email' VALUE u.email
                        ),
                        'device' VALUE JSON_OBJECT(
                            'deviceId' VALUE d.device_id,
                            'status' VALUE d.device_status,
                            'battery' VALUE d.device_battery,
                            'lastSeen' VALUE TO_CHAR(d.last_seen, 'YYYY-MM-DD"T"HH24:MI:SS.FF3')
                        ),
                        'sensorReadings' VALUE COALESCE((
                            SELECT JSON_ARRAYAGG(
                                JSON_OBJECT(
                                    'sensorId' VALUE s.sensor_id,
                                    'timestamp' VALUE TO_CHAR(s.data_hora, 'YYYY-MM-DD"T"HH24:MI:SS.FF3'),
                                    'temperature' VALUE s.temperature,
                                    'heartRate' VALUE s.heart_rate,
                                    'activityLevel' VALUE s.activity_level,
                                    'location' VALUE JSON_OBJECT(
                                        'type' VALUE 'Point',
                                        'coordinates' VALUE JSON_ARRAY(s.longitude, s.latitude)
                                    ),
                                    'battery' VALUE s.sensor_battery,
                                    'status' VALUE s.sensor_status,
                                    'classification' VALUE FN_CLASSIFICA_SENSOR(s.temperature, s.heart_rate)
                                ) ORDER BY s.data_hora RETURNING CLOB
                            ) FROM TB_SENSOR_DATA s
                            WHERE s.tb_device_device_id = d.device_id
                        ), TO_CLOB('[]')) FORMAT JSON,
                        'alerts' VALUE COALESCE((
                            SELECT JSON_ARRAYAGG(
                                JSON_OBJECT(
                                    'alertId' VALUE a.alert_id,
                                    'type' VALUE a.type,
                                    'message' VALUE a.message,
                                    'level' VALUE a.alert_level,
                                    'createdAt' VALUE TO_CHAR(a.created_at, 'YYYY-MM-DD"T"HH24:MI:SS.FF3')
                                ) ORDER BY a.created_at RETURNING CLOB
                            ) FROM TB_ALERT a
                            WHERE a.tb_pet_pet_id = p.pet_id
                        ), TO_CLOB('[]')) FORMAT JSON
                        RETURNING CLOB
                    ) ORDER BY p.pet_id RETURNING CLOB
                )
                FROM TB_USER u
                JOIN TB_PET p ON p.tb_user_user_id = u.user_id
                JOIN TB_DEVICE d ON d.tb_pet_pet_id = p.pet_id
                WHERE p_pet_id IS NULL OR p.pet_id = p_pet_id
            ), TO_CLOB('[]')) FORMAT JSON
            RETURNING CLOB
        ) INTO v_json FROM DUAL;

        RETURN v_json;
    EXCEPTION
        WHEN OTHERS THEN
            PRC_TRATAR_ERRO('PKG_PETCARE360.FN_EXPORTAR_DATASET_JSON', SQLCODE, SQLERRM, -20903);
            RETURN NULL;
    END FN_EXPORTAR_DATASET_JSON;

    PROCEDURE PRC_PETS_JSON (
        p_pet_id IN TB_PET.pet_id%TYPE DEFAULT NULL
    ) IS
        v_json CLOB;
        v_offset PLS_INTEGER := 1;
        v_tamanho PLS_INTEGER;
    BEGIN
        v_json := FN_EXPORTAR_DATASET_JSON(p_pet_id);
        v_tamanho := DBMS_LOB.GETLENGTH(v_json);
        WHILE v_offset <= v_tamanho LOOP
            DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_json, 30000, v_offset));
            v_offset := v_offset + 30000;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            PRC_TRATAR_ERRO('PKG_PETCARE360.PRC_PETS_JSON', SQLCODE, SQLERRM, -20904);
    END PRC_PETS_JSON;

    PROCEDURE PRC_RESUMO_SENSOR IS
        v_qtd NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_qtd FROM TB_SENSOR_DATA;
        IF v_qtd = 0 THEN
            RAISE_APPLICATION_ERROR(-20301, 'TB_SENSOR_DATA sem registros.');
        END IF;

        DBMS_OUTPUT.PUT_LINE(RPAD('ATIVIDADE', 14) || RPAD('STATUS', 10) ||
            LPAD('QTD', 8) || LPAD('TEMP.MEDIA', 14));

        FOR r IN (
            SELECT activity_level, sensor_status, COUNT(*) quantidade,
                   ROUND(AVG(temperature), 2) temperatura_media
            FROM TB_SENSOR_DATA
            GROUP BY activity_level, sensor_status
            ORDER BY activity_level, sensor_status
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(RPAD(r.activity_level, 14) || RPAD(r.sensor_status, 10) ||
                LPAD(r.quantidade, 8) || LPAD(TO_CHAR(r.temperatura_media, 'FM990D00'), 14));
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            PRC_TRATAR_ERRO('PKG_PETCARE360.PRC_RESUMO_SENSOR', SQLCODE, SQLERRM, -20905);
    END PRC_RESUMO_SENSOR;

    PROCEDURE PRC_INSERIR_SENSOR (
        p_sensor_id      IN TB_SENSOR_DATA.sensor_id%TYPE,
        p_device_id      IN TB_DEVICE.device_id%TYPE,
        p_temperature    IN TB_SENSOR_DATA.temperature%TYPE,
        p_heart_rate     IN TB_SENSOR_DATA.heart_rate%TYPE,
        p_activity_level IN TB_SENSOR_DATA.activity_level%TYPE,
        p_latitude       IN TB_SENSOR_DATA.latitude%TYPE,
        p_longitude      IN TB_SENSOR_DATA.longitude%TYPE,
        p_battery        IN TB_SENSOR_DATA.sensor_battery%TYPE,
        p_sensor_status  IN TB_SENSOR_DATA.sensor_status%TYPE DEFAULT 'A'
    ) IS
        v_count NUMBER;
        v_classificacao VARCHAR2(20);
    BEGIN
        IF p_sensor_id IS NULL OR p_sensor_id <= 0 THEN
            RAISE_APPLICATION_ERROR(-20401, 'sensor_id deve ser positivo.');
        END IF;
        SELECT COUNT(*) INTO v_count FROM TB_SENSOR_DATA WHERE sensor_id = p_sensor_id;
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20402, 'sensor_id ja cadastrado.');
        END IF;
        SELECT COUNT(*) INTO v_count FROM TB_DEVICE WHERE device_id = p_device_id;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20403, 'Dispositivo nao encontrado.');
        END IF;
        IF p_activity_level NOT IN ('HIGH', 'MEDIUM', 'LOW') THEN
            RAISE_APPLICATION_ERROR(-20404, 'activity_level invalido.');
        END IF;
        IF p_sensor_status NOT IN ('A', 'I', 'M') THEN
            RAISE_APPLICATION_ERROR(-20405, 'sensor_status invalido.');
        END IF;
        IF p_battery IS NULL OR p_battery NOT BETWEEN 0 AND 100 THEN
            RAISE_APPLICATION_ERROR(-20406, 'Bateria deve estar entre 0 e 100.');
        END IF;

        v_classificacao := FN_CLASSIFICA_SENSOR(p_temperature, p_heart_rate);

        INSERT INTO TB_SENSOR_DATA (
            sensor_id, data_hora, temperature, heart_rate, activity_level,
            latitude, longitude, sensor_battery, sensor_status, tb_device_device_id
        ) VALUES (
            p_sensor_id, SYSTIMESTAMP, p_temperature, p_heart_rate, p_activity_level,
            p_latitude, p_longitude, p_battery, p_sensor_status, p_device_id
        );

        DBMS_OUTPUT.PUT_LINE('Sensor ' || p_sensor_id || ' inserido. Classificacao: ' || v_classificacao);
    EXCEPTION
        WHEN OTHERS THEN
            PRC_TRATAR_ERRO('PKG_PETCARE360.PRC_INSERIR_SENSOR', SQLCODE, SQLERRM, -20906);
    END PRC_INSERIR_SENSOR;

    PROCEDURE PRC_AUDITAR_SENSOR (
        p_operacao           IN VARCHAR2,
        p_valores_anteriores IN VARCHAR2,
        p_valores_novos      IN VARCHAR2
    ) IS
    BEGIN
        IF p_operacao NOT IN ('INSERT', 'UPDATE', 'DELETE') THEN
            RAISE_APPLICATION_ERROR(-20501, 'Operacao de auditoria invalida.');
        END IF;

        INSERT INTO TB_AUDITORIA_SENSOR (
            auditoria_id, usuario_oracle, tipo_operacao, data_operacao,
            valores_anteriores, valores_novos
        ) VALUES (
            SQ_AUDITORIA_SENSOR.NEXTVAL,
            SYS_CONTEXT('USERENV', 'SESSION_USER'),
            p_operacao,
            SYSTIMESTAMP,
            SUBSTR(p_valores_anteriores, 1, 4000),
            SUBSTR(p_valores_novos, 1, 4000)
        );
    EXCEPTION
        WHEN OTHERS THEN
            PRC_TRATAR_ERRO('PKG_PETCARE360.PRC_AUDITAR_SENSOR', SQLCODE, SQLERRM, -20907);
    END PRC_AUDITAR_SENSOR;

END PKG_PETCARE360;
/

SHOW ERRORS PACKAGE BODY PKG_PETCARE360;

PROMPT Criando trigger fina de delegacao...

CREATE OR REPLACE TRIGGER TRG_AUDITORIA_SENSOR
AFTER INSERT OR UPDATE OR DELETE ON TB_SENSOR_DATA
FOR EACH ROW
DECLARE
    v_operacao VARCHAR2(10);
    v_anterior VARCHAR2(4000);
    v_novo     VARCHAR2(4000);
BEGIN
    IF INSERTING THEN
        v_operacao := 'INSERT';
    ELSIF UPDATING THEN
        v_operacao := 'UPDATE';
    ELSE
        v_operacao := 'DELETE';
    END IF;

    IF UPDATING OR DELETING THEN
        SELECT JSON_OBJECT(
            'sensorId' VALUE :OLD.sensor_id,
            'temperature' VALUE :OLD.temperature,
            'heartRate' VALUE :OLD.heart_rate,
            'activityLevel' VALUE :OLD.activity_level,
            'battery' VALUE :OLD.sensor_battery,
            'status' VALUE :OLD.sensor_status,
            'deviceId' VALUE :OLD.tb_device_device_id
            RETURNING VARCHAR2
        ) INTO v_anterior FROM DUAL;
    END IF;

    IF INSERTING OR UPDATING THEN
        SELECT JSON_OBJECT(
            'sensorId' VALUE :NEW.sensor_id,
            'temperature' VALUE :NEW.temperature,
            'heartRate' VALUE :NEW.heart_rate,
            'activityLevel' VALUE :NEW.activity_level,
            'battery' VALUE :NEW.sensor_battery,
            'status' VALUE :NEW.sensor_status,
            'deviceId' VALUE :NEW.tb_device_device_id
            RETURNING VARCHAR2
        ) INTO v_novo FROM DUAL;
    END IF;

    PKG_PETCARE360.PRC_AUDITAR_SENSOR(v_operacao, v_anterior, v_novo);
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20550,
            SUBSTR('Falha na trigger TRG_AUDITORIA_SENSOR: ' || SQLERRM, 1, 1800));
END;
/

SHOW ERRORS TRIGGER TRG_AUDITORIA_SENSOR;


PROMPT Validando compilacao dos objetos PL/SQL...
DECLARE
    v_invalidos NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_invalidos
    FROM USER_OBJECTS
    WHERE OBJECT_NAME IN ('PKG_PETCARE360', 'TRG_AUDITORIA_SENSOR')
      AND STATUS <> 'VALID';
    IF v_invalidos > 0 THEN
        RAISE_APPLICATION_ERROR(-20601, 'Package ou trigger invalido; verifique SHOW ERRORS.');
    END IF;
END;
/

PROMPT Objetos invalidos (resultado esperado: nenhuma linha)
SELECT object_name, object_type, status
FROM user_objects
WHERE object_name IN ('PKG_PETCARE360', 'TRG_AUDITORIA_SENSOR')
  AND status <> 'VALID';

PROMPT ======================================================
PROMPT TESTES DO PACKAGE, PROCEDURES, FUNCOES E TRIGGER
PROMPT ======================================================

PROMPT 1. STATUS DOS OBJETOS
SELECT object_name, object_type, status
FROM user_objects
WHERE object_name IN ('PKG_PETCARE360', 'TRG_AUDITORIA_SENSOR')
ORDER BY object_type;

PROMPT 2. CLASSIFICACAO DOS SENSORES
SELECT sensor_id,
       temperature,
       heart_rate,
       PKG_PETCARE360.FN_CLASSIFICA_SENSOR(temperature, heart_rate) classificacao
FROM TB_SENSOR_DATA
ORDER BY sensor_id;

PROMPT 3. JSON DE UM PET
SELECT PKG_PETCARE360.FN_EXPORTAR_DATASET_JSON(1) AS pet_json
FROM DUAL;

PROMPT 3A. FUNCAO DE JSON DE UM PET
DECLARE
    v_json CLOB;
    v_id NUMBER;
BEGIN
    v_json := PKG_PETCARE360.FN_MONTA_JSON_PET(
        'Arthur Correia', 1, 'Thor', 'Golden Retriever', 12.50, 1, 'A', 90
    );
    SELECT JSON_VALUE(v_json, '$.petId' RETURNING NUMBER) INTO v_id FROM DUAL;
    IF v_id <> 1 THEN
        RAISE_APPLICATION_ERROR(-20602, 'FN_MONTA_JSON_PET retornou petId inesperado.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('FN_MONTA_JSON_PET: OK');
END;
/

PROMPT 3B. ESTRUTURA DO DATASET JSON
DECLARE
    v_json CLOB;
    v_dataset VARCHAR2(100);
    v_pets NUMBER;
BEGIN
    v_json := PKG_PETCARE360.FN_EXPORTAR_DATASET_JSON();
    SELECT JSON_VALUE(v_json, '$.dataset'),
           (SELECT COUNT(*) FROM JSON_TABLE(v_json, '$.pets[*]'
               COLUMNS (pet_id NUMBER PATH '$.petId')))
      INTO v_dataset, v_pets
      FROM DUAL;
    IF v_dataset <> 'petcare360-pets' OR v_pets <> 5 THEN
        RAISE_APPLICATION_ERROR(-20603, 'Dataset JSON incompleto ou inesperado.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('Dataset JSON: OK - ' || v_pets || ' pets');
END;
/

PROMPT 4. RELATORIO JSON VIA PROCEDURE
BEGIN
    PKG_PETCARE360.PRC_PETS_JSON(1);
END;
/

PROMPT 5. RESUMO DE SENSORES
BEGIN
    PKG_PETCARE360.PRC_RESUMO_SENSOR;
END;
/

PROMPT 6. INSERCAO RELACIONAL E DISPARO DA TRIGGER
SAVEPOINT SP_DEMO_SENSOR;

BEGIN
    PKG_PETCARE360.PRC_INSERIR_SENSOR(
        p_sensor_id      => 999,
        p_device_id      => 1,
        p_temperature    => 38.7,
        p_heart_rate     => 125,
        p_activity_level => 'MEDIUM',
        p_latitude       => -23.550520,
        p_longitude      => -46.633308,
        p_battery        => 77,
        p_sensor_status  => 'A'
    );
END;
/

UPDATE TB_SENSOR_DATA
SET temperature = 39.2,
    heart_rate = 140
WHERE sensor_id = 999;

DELETE FROM TB_SENSOR_DATA WHERE sensor_id = 999;

SELECT auditoria_id, tipo_operacao, data_operacao,
       valores_anteriores, valores_novos
FROM TB_AUDITORIA_SENSOR
WHERE JSON_VALUE(valores_anteriores, '$.sensorId' RETURNING NUMBER) = 999
   OR JSON_VALUE(valores_novos, '$.sensorId' RETURNING NUMBER) = 999
ORDER BY auditoria_id;

DECLARE
    v_qtd NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_qtd
    FROM TB_AUDITORIA_SENSOR
    WHERE (JSON_VALUE(valores_anteriores, '$.sensorId' RETURNING NUMBER) = 999
       OR JSON_VALUE(valores_novos, '$.sensorId' RETURNING NUMBER) = 999)
      AND tipo_operacao IN ('INSERT', 'UPDATE', 'DELETE');
    IF v_qtd <> 3 THEN
        RAISE_APPLICATION_ERROR(-20604, 'Auditoria esperada: 3 operacoes; encontrada: ' || v_qtd);
    END IF;
    DBMS_OUTPUT.PUT_LINE('Trigger de auditoria: OK - 3 operacoes');
END;
/

ROLLBACK TO SP_DEMO_SENSOR;

PROMPT 7. TRATAMENTO DE EXCECAO (ERRO ESPERADO ORA-20102)
DECLARE
    v_erro NUMBER := 0;
    v_resultado VARCHAR2(20);
BEGIN
    BEGIN
        v_resultado := PKG_PETCARE360.FN_CLASSIFICA_SENSOR(9, 100);
    EXCEPTION
        WHEN OTHERS THEN
            v_erro := SQLCODE;
    END;
    IF v_erro <> -20102 THEN
        RAISE_APPLICATION_ERROR(-20606, 'Excecao da funcao nao foi tratada como esperado.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('Excecao da funcao: OK - ORA-20102');
END;
/

SELECT log_id, objeto, codigo_erro, mensagem_erro, data_erro
FROM TB_LOG_ERRO
ORDER BY log_id DESC
FETCH FIRST 5 ROWS ONLY;

PROMPT 7A. EXCECAO DE PROCEDURE (DISPOSITIVO INEXISTENTE)
DECLARE
    v_erro NUMBER := 0;
    v_qtd NUMBER;
BEGIN
    BEGIN
        PKG_PETCARE360.PRC_INSERIR_SENSOR(
            998, 999999, 38.7, 125, 'MEDIUM',
            -23.550520, -46.633308, 77, 'A'
        );
    EXCEPTION
        WHEN OTHERS THEN
            v_erro := SQLCODE;
    END;
    SELECT COUNT(*) INTO v_qtd FROM TB_SENSOR_DATA WHERE sensor_id = 998;
    IF v_erro <> -20403 OR v_qtd <> 0 THEN
        RAISE_APPLICATION_ERROR(-20605, 'Excecao da procedure nao foi tratada como esperado.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('Excecao da procedure: OK - ORA-20403');
END;
/

PROMPT 8. VALIDACAO FINAL
SELECT object_name, object_type, status
FROM user_objects
WHERE status <> 'VALID'
  AND object_name IN ('PKG_PETCARE360', 'TRG_AUDITORIA_SENSOR');

PROMPT Resultado esperado para a consulta acima: nenhuma linha.

PROMPT ======================================================
PROMPT ETAPA 3 - EXPORTACAO JSON
PROMPT ======================================================
SET HEADING OFF;
SET FEEDBACK OFF;
SET VERIFY OFF;
SET ECHO OFF;
SET PAGESIZE 0;
SET LINESIZE 32767;
SET LONG 10000000;
SET LONGCHUNKSIZE 10000000;
SET TRIMSPOOL ON;

SPOOL 03_dataset_petcare360_exportado.json

SELECT PKG_PETCARE360.FN_EXPORTAR_DATASET_JSON()
FROM DUAL;

SPOOL OFF;

SET HEADING ON;
SET FEEDBACK ON;
PROMPT Dataset criado em 03_dataset_petcare360_exportado.json
PROMPT Execucao concluida.
