/**
 * Convencoes
 *    Offline: Atividades ocorridas na loja fisica ou acoes feitas pela aplicacao Eco.
 *    Online: Atividades ocorridas na loja virtual ou acoes feitas pela aplicacao Drupal.
 */
SET SQL DIALECT 3;

CREATE DOMAIN CONTADOR AS
INTEGER
NOT NULL;

CREATE DOMAIN QUANTIDADE AS
NUMERIC(12,4);

CREATE DOMAIN VALOR AS
NUMERIC(18,3);

CREATE TABLE TLOJCLIENTES (
    ID           CONTADOR NOT NULL /* CONTADOR = INTEGER NOT NULL */,
    CPFCNPJ      VARCHAR(14),
    RGIE         VARCHAR(20),
    NOME         VARCHAR(50),
    FANTASIA     VARCHAR(50),
    IDENDERECO   VARCHAR(40),
    FONE         VARCHAR(11),
    EMAIL        VARCHAR(50)
);

ALTER TABLE TLOJCLIENTES ADD CONSTRAINT PK_TLOJCLIENTES PRIMARY KEY (ID);
ALTER TABLE TLOJCLIENTES ADD CONSTRAINT FK_TLOJENDERECOS_1 FOREIGN KEY (IDENDERECO) REFERENCES TLOJENDERECOS (ID);

CREATE TABLE TLOJENDERECOS (
    ID           CONTADOR /* CONTADOR = INTEGER NOT NULL */,
    ENDERECO     VARCHAR(40),
    COMPLEMENTO  VARCHAR(30),
    BAIRRO       VARCHAR(20),
    CODIGOIBGE   INTEGER,
    CEP          VARCHAR(8),
    FONE         VARCHAR(11)
);

ALTER TABLE TLOJENDERECOS ADD CONSTRAINT PK_TLOJENDERECOS PRIMARY KEY (ID);

CREATE TABLE TLOJPEDIDO (
    IDPEDIDO       CONTADOR NOT NULL /* CONTADOR = INTEGER NOT NULL */,
    IDEMPRESA      VARCHAR(2),
    IDCLIENTE      CONTADOR /* CONTADOR = INTEGER NOT NULL */,
    IDPRODUTO      VARCHAR(6),
    QTDE           QUANTIDADE /* QUANTIDADE = NUMERIC(12,4) */,
    PRECOUNITARIO  VALOR /* VALOR = NUMERIC(18,3) */,
    PRECOTOTAL     VALOR /* VALOR = NUMERIC(18,3) */,
    FRETETOTAL     VALOR /* VALOR = NUMERIC(18,3) */,
    CONDICAOPAGTO  VARCHAR(3),
    /* Informacoes sobre a transacao de pagto por cartao de credito. */
    IDTRANSACAO    INTEGER NOT NULL,
    /* Status do Pedido. */
    IDSTATUS       INTEGER NOT NULL,
    /* ID da tabela de enderecos (TLOJENDERECOS). */
    ENDENTREGA     INTEGER,
    /**
     * Define se o registro sofreu alguma alteracao desde a ultima checagem.
     *     
     * Possiveis valores para este campo sao:
     * 0 (zero) = O Drupal precisa atualizar o STATUSPEDIDO online.
     * 1 (um) = O STATUSPEDIDO nao foi alterado offline desde a ultima checagem.
     * 
     * Toda vez que o STATUSPEDIDO for alterado pela aplicacao offline esta devera alterar o valor deste
     * campo para 0 (zero).
     * O Drupal ira mudar este valor para 1 (um) apos atualizar o PEDIDOSTATUS online.
     */
    ATUALIZADO     VARCHAR(1) NOT NULL,    
);

ALTER TABLE TLOJPEDIDO ADD CONSTRAINT PK_TLOJPEDIDO PRIMARY KEY (IDPEDIDO);
ALTER TABLE TLOJPEDIDO ADD CONSTRAINT FK_TLOJPEDIDO_1 FOREIGN KEY (IDEMPRESA) REFERENCES TGEREMPRESA (CODIGO);
ALTER TABLE TLOJPEDIDO ADD CONSTRAINT FK_TLOJPEDIDO_2 FOREIGN KEY (IDCLIENTE) REFERENCES TLOJCLIENTES (ID);
ALTER TABLE TLOJPEDIDO ADD CONSTRAINT FK_TLOJPEDIDO_3 FOREIGN KEY (IDEMPRESA, IDPRODUTO) REFERENCES TESTPRODUTO (EMPRESA, PRODUTO);
ALTER TABLE TLOJPEDIDO ADD CONSTRAINT FK_TLOJPEDIDO_4 FOREIGN KEY (IDEMPRESA, CONDICAOPAGTO) REFERENCES TESTCONDPAGVENDA (EMPRESA, CODIGO);
ALTER TABLE TLOJPEDIDO ADD CONSTRAINT FK_TLOJPEDIDO_5 FOREIGN KEY (ENDENTREGA) REFERENCES TLOJENDERECOS (ID);
ALTER TABLE TLOJPEDIDO ADD CONSTRAINT FK_TLOJPEDIDO_6 FOREIGN KEY (IDSTATUS) REFERENCES TLOJPEDIDOSTATUS (IDSTATUS);
ALTER TABLE TLOJPEDIDO ADD CONSTRAINT FK_TLOJPEDIDO_7 FOREIGN KEY (IDTRANSACAO) REFERENCES TLOJPAGAMENTO (IDTRANSACAO);


/**
 * Lista de Fases do Pedido.
 * Fases sao containers para os statuses.
 *
 * TODO: Pre popular esta tabela com os valores padroes (inserts).
 */
CREATE TABLE TLOJPEDIDOFASES (
    IDFASE      VARCHAR(2) NOT NULL,
    /**
     * As fases pre-definidas pelo sistema sao:
     *   canceled = Pedido cancelado pelo administrador da loja.
     *   cart = O pedido foi adicionado ao carrinho.
     *   chechout = O pedido encontra-se em uma das etapas de fechamento do pedido.
     *              (acontece geralmente quando o comprador abandona a compra).
     *   pending = O fechamento do pedido foi concluido pelo comprador e esta aguardando processamento pela loja.
     *   completed = O Pedido foi concluido (geralmente significa que os produtos ja foram entregues).
     *
     */
    VALORFASE   VARCHAR(20) NOT NULL,
);

ALTER TABLE TLOJPEDIDOFASES ADD CONSTRAINT PK_TLOJPEDIDOFASES PRIMARY KEY (IDFASE);

/**
 * Lista de Statuses do Pedido.
 *
 * TODO: Pre popular esta tabela com os valores padroes.
 */
CREATE TABLE TLOJPEDIDOSTATUS (
    IDSTATUS   VARCHAR(2) NOT NULL,
    IDFASE     VARCHAR(2) NOT NULL,
    /**
     * Os status pre-definidas pelo sistema sao:
     *   canceled
     *     canceled = Pedido foi cancelado pelo administrador da loja.
     *   cart
     *     cart = Pedido esta no carrinho de compras.
     *   chechout
     *     checkout_checkout = Pagamento: Fechar pedido
     *     checkout_review = Pagamento: Revisao
     *     checkout_payment = Pagamento: Pagamento
     *     checkout_complete = Pagamento: Completo
     *   pending
     *     pending = Pedido foi concluido pelo comprador e aguarda acao por parte da loja.
     *     processing = A loja esta processando o pedido.
     *   completed
     *     completed = O pedido foi entregue.
     */
    VALORSTATUS   VARCHAR(20) NOT NULL,
);

ALTER TABLE TLOJPEDIDOSTATUS ADD CONSTRAINT PK_TLOJPEDIDOSTATUS PRIMARY KEY (IDSTATUS);
ALTER TABLE TLOJPEDIDOSTATUS ADD CONSTRAINT FK_TLOJPEDIDOSTATUS_1 FOREIGN KEY (IDFASE) REFERENCES TLOJPEDIDOFASES (IDFASE);

CREATE TABLE TLOJPAGAMENTO (
    /* Id da transacao de pagto junto a operadora de cartao de credito.*/
    IDTRANSACAO    INTEGER NOT NULL,
    /**
     * Status da transacao de pgto junto a operadora de Cartao de credito.
     *
     * Possiveis valores para este campo sao:
     * failure = A transacao de pgto falhou.
     * pending = A transacao de pgto esta pendente e depende de alguma acao para ser concluida.
     * success = A transacao de pgto foi concluida com sucesso.
     * canceled = A transacao de pgto foi extornada pelo administrador da loja.
     */
    PGTOSTATUS     VARCHAR(20) NOT NULL,
    /**
     * Codigo do Status da transacao junto a operadora de Cartao de credito.
     *
     * Os codigos da Cielo sao:
     * pending
     *   0 = Transacao foi criada (ainda falta ser autorizada e capturada).
     *   1 = Em progresso.
     *   2 = Autenticada (ainda falta ser autorizada e capturada).
     *   3 = Nao autenticada, quando autenticacao não for solicitada.
     *   4 = Autorizada ou ainda por ser capturada.
     *   10 = Sendo autenticada.
     * failure
     *   3 = Nao autenticada, quando autenticacao for solicitada.
     *   5 = Autorizacao foi negada.
     *   8 = Nao capturada.
     * success
     *   6 = Capturada.
     * canceled
     *   9 = Pgto foi extornado pela loja.
     *
     * Os codigos da Redecard sao:
     * Acessar https://github.com/drupalista-br/BrazilCards/blob/master/manuals/Manual%20Webservice.pdf
     * a partir da pagina 86.
     */
    PGTOSTATUSCODE VARCHAR(2),
    /**
     * Mensagem de Status da transacao enviada pela operadora de Cartao de credito,
     * juntamente com o codigo de status da transacao.
     */
    PGTOSTATUSMSG  VARCHAR(20),
);

ALTER TABLE TLOJPAGAMENTO ADD CONSTRAINT PK_TLOJPAGAMENTO PRIMARY KEY (IDTRANSACAO);

/**
 * Checagem de alteracoes de estoque ocorridas offline.
 * Agrupa o estoque atual de todas as unidades da empresa.
 */
CREATE TABLE TLOJESTOQUE (
    IDPRODUTO      VARCHAR(6) NOT NULL,
    ESTDISPONIVEL  NUMERIC(18,4),
    /**
     * Define se o registro sofreu alteracoes desde a ultima checagem.
     *
     * Possiveis valores para este campo sao:
     * 0 (zero) = O Drupal precisa atualizar o estoque online.
     * 1 (um) = O ESTDISPONIVEL nao foi alterado offline desde a ultima checagem.
     * 
     * Toda vez que o ESTDISPONIVEL for alterado pela aplicacao offline esta devera alterar o valor deste
     * campo para 0 (zero).
     * O Drupal ira mudar este valor para 1 (um) apos atualizar o estoque online.
     */
    ATUALIZADO     VARCHAR(1) NOT NULL,
);