	DECLARE 
		@CurrentDate			DATE = null --'2024-11-30'
	,	@FirstDayOfMonth		DATE
	,	@LastDayOfMonth			DATE
	,	@FirstDaySkFecha		VARCHAR(200)
	,	@LastDaySkFecha			VARCHAR(200)
	,	@Msg				VARCHAR(MAX)
	,	@Qt_Linhas			INT
	,	@Total_Linhas			INT = 0
	,	@QTDE_INSERT			INT = 0
	,	@DiasUteisSemFDS		INT
	,	@DiasUteisParaFimSemFDS 	INT
	,	@TotalDiasUteis			INT
	,	@FirstDayOfYear         	DATE
	,	@FirstDayPreviousMonth  	DATE
	,	@DiasSegParaFim			INT
	,	@DiasUteisSemSegunda		INT
	,	@DiasUteisParaFimSemSegunda 	INT
	,	@DiasSeg			INT
	,	@LastDayOfNextMonth 		DATE
	,	@LastDayOfNextMonthSkFecha 	VARCHAR(200)


	SET @CurrentDate			= CASE WHEN @CurrentDate IS NULL THEN DATEADD(DAY, -1, GETDATE() ) ELSE @CurrentDate END
	SET @FirstDayOfMonth			= DATEADD(DAY, 1 - DAY(@CurrentDate), @CurrentDate)
	SET @LastDayOfMonth			= EOMONTH(@CurrentDate)
	SET @FirstDaySkFecha			= convert(varchar, DATEADD(DAY, 1 - DAY(@CurrentDate), @CurrentDate), 112)
	SET @LastDaySkFecha			= convert(varchar, eomonth(@CurrentDate), 112)
	SET @DiasUteisSemFDS			= dbo.ContarDiasUteisSemFDS(@FirstDayOfMonth, @CurrentDate)
	SET @DiasUteisParaFimSemFDS		= dbo.ContarDiasUteisFaltantesSemFDS(@CurrentDate, @LastDayOfMonth)
	SET @TotalDiasUteis			= @DiasUteisSemFDS + @DiasUteisParaFimSemFDS
	SET @FirstDayOfYear			= DATEFROMPARTS(YEAR(@CurrentDate), 1, 1)
	SET @FirstDayPreviousMonth		= DATEADD(MONTH, -1, DATEADD(DAY, 1 - DAY(@CurrentDate), @CurrentDate))
	SET @DiasSegParaFim			= dbo.ContarSabadDomSeg(@CurrentDate, @LastDayOfMonth)
	SET @DiasUteisSemSegunda		= dbo.ContarDiasUteis(@FirstDayOfMonth, @CurrentDate)
	SET @DiasUteisParaFimSemSegunda 	= dbo.ContarDiasUteisFaltantes(@CurrentDate, @LastDayOfMonth)
	SET @DiasSeg				= dbo.ContarSabadDomSeg(@FirstDayOfMonth, @CurrentDate)
	SET @LastDayOfNextMonth			= EOMONTH(DATEADD(MONTH, 1, @CurrentDate))
	SET @LastDayOfNextMonthSkFecha		= convert(varchar, eomonth(@LastDayOfNextMonth), 112)

	--SELECT 
	--	@CurrentDate CurrentDate
	--,	@FirstDayOfMonth FirstDayOfMonth
	--,	@LastDayOfMonth LastDayOfMonth
	--,	@FirstDaySkFecha FirstDaySkFecha
	--,	@LastDaySkFecha LastDaySkFecha
	--,	@DiasUteisSemFDS DiasUteisSemFDS
	--,	@DiasUteisParaFimSemFDS DiasUteisParaFimSemFDS
	--,	@TotalDiasUteis TotalDiasUteis
	--,	@FirstDayOfYear FirstDayOfYear
	--,	@FirstDayPreviousMonth FirstDayPreviousMonth
	--,	@DiasSegParaFim DiasSegParaFim
	--,	@DiasUteisSemSegunda DiasUteisSemSegunda
	--,	@DiasUteisParaFimSemSegunda DiasUteisParaFimSemSegunda
	--,	@DiasSeg DiasSeg
	--,	@LastDayOfNextMonth LastDayOfNextMonth
	--,	@LastDayOfNextMonthSkFecha LastDayOfNextMonthSkFecha

	-- Capturando as propostas da conexion global
	-- Alteração dia 24-04-2025 - Feito por Diogo Pereira dos Santos
	-- Inclusão de processo para captura dados de Rechasada e mergem com a tabela #tmp_rds_produto_auto_proposta

drop table if exists #tmp_rds_produto_auto_proposta

    SELECT 
        A.IND_SISTEMA,
        A.NUM_PROPUESTA,
        A.NUM_COTIZACION,
        CAST(A.FEC_EMISION_SUPLEMENTO AS DATE) AS FEC_PROPUESTA,
        C.NOM_ESTADO AS NOM_ESTADO_PROPUESTA,
		D.TIPO_SUPLEMENTO AS TIPO_SUPLEMENTO_PROPUESTA,
		D.NOM_SUPLEMENTO AS NOM_SUPLEMENTO_PROPUESTA

	into #tmp_rds_produto_auto_proposta
    FROM FACT_CONEXION_GLOBAL_01096 A WITH (NOLOCK)
    INNER JOIN DIM_CG_PARAMETRO_419691 B WITH (NOLOCK) ON A.IND_DOCUMENTO = B.SK_CG_PARAMETRO
    INNER JOIN DIM_CG_ESTADO_COTIZACION_419691 C WITH (NOLOCK) ON A.SK_ESTADO_PROPUESTA = C.SK_ESTADO_COTIZACION
	LEFT JOIN DIM_SUPLEMENTO_419691 D WITH (NOLOCK) ON A.SK_SUPLEMENTO = D.SK_SUPLEMENTO
    WHERE 
		A.IND_SISTEMA IN ('TRONWEB')
        AND A.IND_LINEA_NEGOCIO = 'AUT'
        AND B.NOM_PARAMETRO = 'PROPUESTA'
		and A.SK_FECHA = @LastDaySkFecha
    GROUP BY 
        A.IND_SISTEMA, A.NUM_PROPUESTA, A.NUM_COTIZACION, A.FEC_EMISION_SUPLEMENTO, C.NOM_ESTADO, D.TIPO_SUPLEMENTO, D.NOM_SUPLEMENTO

-- Incluindo dados de rechazada

drop table if exists #tmp_rds_produto_auto_proposta_rechazada

    SELECT 
        A.IND_SISTEMA,
        A.NUM_PROPUESTA,
        A.NUM_COTIZACION,
        CAST(A.FEC_EMISION_SUPLEMENTO AS DATE) AS FEC_PROPUESTA,
        B.NOM_PARAMETRO AS NOM_ESTADO_PROPUESTA,
		D.TIPO_SUPLEMENTO AS TIPO_SUPLEMENTO_PROPUESTA,
		D.NOM_SUPLEMENTO AS NOM_SUPLEMENTO_PROPUESTA

	into #tmp_rds_produto_auto_proposta_rechazada
    FROM FACT_CONEXION_GLOBAL_01096 A WITH (NOLOCK)
    INNER JOIN DIM_CG_PARAMETRO_419691 B WITH (NOLOCK) ON A.SK_ESTADO_PROPUESTA = B.SK_CG_PARAMETRO
    INNER JOIN DIM_CG_ESTADO_COTIZACION_419691 C WITH (NOLOCK) ON A.SK_ESTADO_PROPUESTA = C.SK_ESTADO_COTIZACION
	LEFT JOIN DIM_SUPLEMENTO_419691 D WITH (NOLOCK) ON A.SK_SUPLEMENTO = D.SK_SUPLEMENTO
    WHERE 
		A.IND_SISTEMA IN ('TRONWEB')
        AND A.IND_LINEA_NEGOCIO = 'AUT'
        AND B.NOM_PARAMETRO = 'RECHAZADA'
		and A.SK_FECHA = @LastDaySkFecha
    GROUP BY 
        A.IND_SISTEMA, A.NUM_PROPUESTA, A.NUM_COTIZACION, A.FEC_EMISION_SUPLEMENTO, B.NOM_PARAMETRO, D.TIPO_SUPLEMENTO, D.NOM_SUPLEMENTO

	-- Realizar o Marge entre as tabelas e atualiza NOM_ESTADO_PROPUESTA
		MERGE INTO #tmp_rds_produto_auto_proposta AS target
		USING #tmp_rds_produto_auto_proposta_rechazada AS source
		ON target.IND_SISTEMA = source.IND_SISTEMA
		AND target.NUM_PROPUESTA = source.NUM_PROPUESTA
		AND target.NUM_COTIZACION = source.NUM_COTIZACION
		AND target.FEC_PROPUESTA = source.FEC_PROPUESTA

	-- Atualiza onde já existe
	WHEN MATCHED AND target.NOM_ESTADO_PROPUESTA NOT IN ('COM RESTRICAO', 'EM ANALISE') THEN
		UPDATE SET
			target.NOM_ESTADO_PROPUESTA = source.NOM_ESTADO_PROPUESTA

	-- Insere onde não existe
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (
			IND_SISTEMA,
			NUM_PROPUESTA,
			NUM_COTIZACION,
			FEC_PROPUESTA,
			NOM_ESTADO_PROPUESTA,
			TIPO_SUPLEMENTO_PROPUESTA,
			NOM_SUPLEMENTO_PROPUESTA
		)
		VALUES (
			source.IND_SISTEMA,
			source.NUM_PROPUESTA,
			source.NUM_COTIZACION,
			source.FEC_PROPUESTA,
			source.NOM_ESTADO_PROPUESTA,
			source.TIPO_SUPLEMENTO_PROPUESTA,
			source.NOM_SUPLEMENTO_PROPUESTA
		);

		-- Atualiza estados específicos para 'PENDENTE'
		UPDATE #tmp_rds_produto_auto_proposta
		SET NOM_ESTADO_PROPUESTA = 'PENDENTE'
		WHERE NOM_ESTADO_PROPUESTA IN ('COM RESTRICAO', 'EM ANALISE');

		-- Padronizando o nome RECHAZADA para RECUSADA
		UPDATE #tmp_rds_produto_auto_proposta
		SET NOM_ESTADO_PROPUESTA = 'RECUSADA'
		WHERE NOM_ESTADO_PROPUESTA = 'RECHAZADA';
