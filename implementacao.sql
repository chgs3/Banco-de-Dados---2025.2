-- CREATE
-- criando as tabelas sem FK 
CREATE TABLE DIRETOR (
    ID_Diretor NUMBER PRIMARY KEY,
    Nome VARCHAR2(100) NOT NULL,
    CPF VARCHAR2(11) UNIQUE NOT NULL
);
CREATE TABLE SUPERINTENDENTE (
    ID_Super NUMBER PRIMARY KEY,
    Nome VARCHAR2(100) NOT NULL,
    CPF VARCHAR2(11) UNIQUE NOT NULL
);
CREATE TABLE CRIME (
    ID_Crime NUMBER PRIMARY KEY,
    Descricao VARCHAR2(100) NOT NULL,
    Artigo_Penal VARCHAR2(20)
);
CREATE TABLE VISITANTE (
    ID_Visitante NUMBER PRIMARY KEY,
    Nome VARCHAR2(100) NOT NULL,
    CPF VARCHAR2(11) UNIQUE NOT NULL
);

-- criando as tabelas com FK
CREATE TABLE PRESIDIO (
    ID_Presidio NUMBER PRIMARY KEY,
    Nome VARCHAR2(100) NOT NULL,
    Endereco VARCHAR2(200),
    ID_Diretor NUMBER UNIQUE,
    CONSTRAINT fk_pres_dir FOREIGN KEY (ID_Diretor) REFERENCES DIRETOR(ID_Diretor)
);

CREATE TABLE ALA (
    ID_Ala NUMBER PRIMARY KEY,
    Nome_Ala VARCHAR2(50) NOT NULL,
    ID_Presidio NUMBER NOT NULL,
    ID_Super NUMBER UNIQUE,
    CONSTRAINT fk_ala_pres FOREIGN KEY (ID_Presidio) REFERENCES PRESIDIO(ID_Presidio),
    CONSTRAINT fk_ala_super FOREIGN KEY (ID_Super) REFERENCES SUPERINTENDENTE(ID_Super)
);

CREATE TABLE CELA (
    ID_Cela NUMBER PRIMARY KEY,
    Codigo_Identificacao VARCHAR2(10) NOT NULL,
    Capacidade NUMBER NOT NULL,
    ID_Ala NUMBER NOT NULL,
    CONSTRAINT fk_cela_ala FOREIGN KEY (ID_Ala) REFERENCES ALA(ID_Ala)
);

CREATE TABLE DETENTO (
    ID_Detento NUMBER PRIMARY KEY,
    Nome VARCHAR2(100) NOT NULL,
    CPF VARCHAR2(11) UNIQUE NOT NULL,
    Data_Entrada DATE NOT NULL,
    ID_Cela NUMBER NOT NULL,
    CONSTRAINT fk_det_cela FOREIGN KEY (ID_Cela) REFERENCES CELA(ID_Cela)
);

-- criando as tabelas associativas
CREATE TABLE SENTENCA (
    ID_Detento NUMBER,
    ID_Crime NUMBER,
    Pena_Anos NUMBER NOT NULL,
    PRIMARY KEY (ID_Detento, ID_Crime),
    CONSTRAINT fk_sen_det FOREIGN KEY (ID_Detento) REFERENCES DETENTO(ID_Detento),
    CONSTRAINT fk_sen_cri FOREIGN KEY (ID_Crime) REFERENCES CRIME(ID_Crime)
);

CREATE TABLE VISITA (
    ID_Visita NUMBER PRIMARY KEY,
    Data_Visita DATE NOT NULL,
    ID_Detento NUMBER NOT NULL,
    ID_Visitante NUMBER NOT NULL,
    CONSTRAINT fk_vis_det FOREIGN KEY (ID_Detento) REFERENCES DETENTO(ID_Detento),
    CONSTRAINT fk_vis_vis FOREIGN KEY (ID_Visitante) REFERENCES VISITANTE(ID_Visitante)
);

-- INSERT
-- inserindo pessoas e localizações
INSERT INTO DIRETOR VALUES (1, 'João Silva', '11122233344');
INSERT INTO SUPERINTENDENTE VALUES (1, 'Jose Carlos', '55566677788');
INSERT INTO PRESIDIO VALUES (1, 'Presidio Central', 'Rua A, 100', 1);
INSERT INTO ALA VALUES (1, 'Ala Norte', 1, 1);
INSERT INTO CELA VALUES (1, '035', 2, 1); -- Cela 035, cap 2, Ala Norte
INSERT INTO CELA VALUES (2, '036', 1, 1);

-- inserindo crimes e visitantes
INSERT INTO CRIME VALUES (1, 'Assalto a banco', '157');
INSERT INTO CRIME VALUES (2, 'Furto', '155');
INSERT INTO VISITANTE VALUES (1, 'Maria Souza', '99988877766');

-- inserindo detento
INSERT INTO DETENTO VALUES (1, 'Carlos Bandido', '12312312312', DATE '2010-05-20', 1); -- entrou em 1010 na cela 035

-- inserindo sentença
INSERT INTO SENTENCA VALUES (1, 1, 15);
INSERT INTO SENTENCA VALUES (1, 2, 20);

-- inserindo visita
INSERT INTO VISITA VALUES (1, DATE '2023-10-01', 1, 1);

-- READ
-- detentos na ala do Superintendente José Carlos
SELECT D.Nome, D.Data_Entrada
FROM DETENTO D
JOIN CELA C ON D.ID_Cela = C.ID_Cela
JOIN ALA A ON C.ID_Ala = A.ID_Ala
JOIN SUPERINTENDENTE S ON A.ID_Super = S.ID_Super
WHERE S.Nome = 'Jose Carlos';

-- visitantes do presídio do Diretor João Silva
SELECT DISTINCT V.Nome
FROM VISITANTE V
JOIN VISITA VI ON V.ID_Visitante = VI.ID_Visitante
JOIN DETENTO D ON VI.ID_Detento = D.ID_Detento
JOIN CELA C ON D.ID_Cela = C.ID_Cela
JOIN ALA A ON C.ID_Ala = A.ID_Ala
JOIN PRESIDIO P ON A.ID_Presidio = P.ID_Presidio
JOIN DIRETOR DIR ON P.ID_Diretor = DIR.ID_Diretor
WHERE DIR.Nome = 'João Silva';

-- detentos da cela 035 com crime de assalto a banco
SELECT D.Nome
FROM DETENTO D
JOIN CELA C ON D.ID_Cela = C.ID_Cela
JOIN SENTENCA S ON D.ID_Detento = S.ID_Detento
JOIN CRIME CR ON S.ID_Crime = CR.ID_Crime
WHERE C.Codigo_Identificacao = '035'
AND CR.Descricao = 'Assalto a banco';

-- implementação de procedimentos
-- verificação de capacidade ao inserir detentos
CREATE OR REPLACE PROCEDURE InserirDetentoComVerificacao(
    p_id_det NUMBER,
    p_nome VARCHAR2,
    p_cpf VARCHAR2,
    p_data DATE,
    p_id_cela NUMBER
) IS
    v_capacidade NUMBER;
    v_ocupacao NUMBER;
BEGIN
    -- aqui é p verificar a capacidade da cela
    SELECT Capacidade INTO v_capacidade FROM CELA WHERE ID_Cela = p_id_cela;
    
    -- aqui é p verificar quantos já existem
    SELECT COUNT(*) INTO v_ocupacao FROM DETENTO WHERE ID_Cela = p_id_cela;
    
    IF v_ocupacao >= v_capacidade THEN
        RAISE_APPLICATION_ERROR(-20001, 'Erro: Capacidade maxima da cela atingida!');
    ELSE
        INSERT INTO DETENTO (ID_Detento, Nome, CPF, Data_Entrada, ID_Cela)
        VALUES (p_id_det, p_nome, p_cpf, p_data, p_id_cela);
        COMMIT;
    END IF;
END;
/

-- teste
BEGIN InserirDetentoComVerificacao(2, 'Pedro Pistolero', '11111111111', SYSDATE, 1); END;
BEGIN InserirDetentoComVerificacao(2, 'Zezinho Facão', '11111111111', SYSDATE, 1); END;
BEGIN InserirDetentoComVerificacao(2, 'Jagunço', '11111111111', SYSDATE, 1); END;
BEGIN InserirDetentoComVerificacao(2, 'Zé Branquinho', '11111111111', SYSDATE, 1); END;

-- calculando data de saída
CREATE OR REPLACE PROCEDURE CalcularDataSaida(p_id_det NUMBER) IS
    v_data_entrada DATE;
    v_total_anos NUMBER := 0;
    v_data_saida DATE;
BEGIN
    -- data de entrada
    SELECT Data_Entrada INTO v_data_entrada 
    FROM DETENTO WHERE ID_Detento = p_id_det;
    
    -- soma das penas
    SELECT COALESCE(SUM(Pena_Anos), 0) INTO v_total_anos
    FROM SENTENCA WHERE ID_Detento = p_id_det;
    
    -- teto de 30 anos
    IF v_total_anos > 30 THEN
        v_total_anos := 30;
    END IF;
    
    -- calculando saída
    v_data_saida := ADD_MONTHS(v_data_entrada, v_total_anos * 12);
    
    -- resultado
    DBMS_OUTPUT.PUT_LINE('Detento ID: ' || p_id_det);
    DBMS_OUTPUT.PUT_LINE('Total de Pena Calculada: ' || v_total_anos || ' anos');
    DBMS_OUTPUT.PUT_LINE('Data de Saida: ' || TO_CHAR(v_data_saida, 'DD/MM/YYYY'));
END;
/

-- teste 
BEGIN CalcularDataSaida(1); END;
BEGIN CalcularDataSaida(2); END;
BEGIN CalcularDataSaida(3); END;
