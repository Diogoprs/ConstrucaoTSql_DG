/****** Object:  StoredProcedure [dbo].[sp_GerarIndicadorProdutoVidaAnaliticoCarteiraRaiz]    Script Date: 07/04/2025 11:29:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_GerarIndicadorProdutoVidaAnaliticoCarteiraRaiz]
(
	@CurrentDate DATE = NULL -- '2025-04-03'
)
AS
BEGIN

	DECLARE 
		@FirstDayOfMonth             DATE,
		@LastDayOfMonth              DATE,
		@FirstDaySkFecha             VARCHAR(8),   -- Reduzido para 8 caracteres (yyyymmdd)
		@LastDaySkFecha              VARCHAR(8),
		@Msg                         VARCHAR(MAX),
		@Qt_Linhas                   INT,
		@Total_Linhas                INT = 0,
		@QTDE_INSERT                 INT = 0,
		@DiasUteisSemFDS             INT,
		@DiasUteisParaFimSemFDS      INT,
		@TotalDiasUteis              INT,
		@FirstDayOfYear              DATE,
		@FirstDayPreviousMonth       DATE,
		@DiasSegParaFim              INT,
		@DiasUteisSemSegunda         INT,
		@DiasUteisParaFimSemSegunda  INT,
		@DiasSeg                     INT,
		@LastDayOfNextMonth          DATE,
		@LastDayOfNextMonthSkFecha   VARCHAR(8),
		@NR_ANO_MES                  INT,
		@FirstDayOfMonthLastYear     DATE;

	-- Define @CurrentDate se estiver NULL
	SET @CurrentDate = ISNULL(@CurrentDate, DATEADD(DAY, -1, GETDATE()));

	-- Definição das datas principais
	SET @FirstDayOfMonth           = DATEADD(DAY, 1 - DAY(@CurrentDate), @CurrentDate);
	SET @LastDayOfMonth            = EOMONTH(@CurrentDate);
	SET @FirstDaySkFecha           = CONVERT(VARCHAR(8), @FirstDayOfMonth, 112);
	SET @LastDaySkFecha            = CONVERT(VARCHAR(8), @LastDayOfMonth, 112);
	SET @DiasUteisSemFDS           = dbo.ContarDiasUteisSemFDS(@FirstDayOfMonth, @CurrentDate);
	SET @DiasUteisParaFimSemFDS    = dbo.ContarDiasUteisFaltantesSemFDS(@CurrentDate, @LastDayOfMonth);
	SET @TotalDiasUteis            = @DiasUteisSemFDS + @DiasUteisParaFimSemFDS;
	SET @FirstDayOfYear            = DATEFROMPARTS(YEAR(@CurrentDate), 1, 1);
	SET @FirstDayPreviousMonth     = DATEADD(MONTH, -1, @FirstDayOfMonth);
	SET @DiasSegParaFim            = dbo.ContarSabadDomSeg(@CurrentDate, @LastDayOfMonth);
	SET @DiasUteisSemSegunda       = dbo.ContarDiasUteis(@FirstDayOfMonth, @CurrentDate);
	SET @DiasUteisParaFimSemSegunda= dbo.ContarDiasUteisFaltantes(@CurrentDate, @LastDayOfMonth);
	SET @DiasSeg                   = dbo.ContarSabadDomSeg(@FirstDayOfMonth, @CurrentDate);
	SET @LastDayOfNextMonth        = EOMONTH(DATEADD(MONTH, 1, @CurrentDate));
	SET @LastDayOfNextMonthSkFecha = CONVERT(VARCHAR(8), @LastDayOfNextMonth, 112);
	SET @NR_ANO_MES                = CONVERT(INT, FORMAT(@CurrentDate, 'yyyyMM'));
	SET @FirstDayOfMonthLastYear   = DATEADD(YEAR, -1, @FirstDayOfMonth);

	-- ====================================================================================================================================
	--
	--													INÍCIO DO CALCULO DE RAIZ
	--
	-- ====================================================================================================================================

	DROP TABLE IF EXISTS #tmp_Raiz;

	SELECT
			T1.RaizCpfCnpjCorretor
		,	T1.NomeRaizCorretor
		,	NULL AS NomeSetor
			------------------------------------------------------------
		,	T1.CodTerritorial
		,	T1.NomeTerritorial
		,	T1.CodSucursal
		,	T1.NomeSucursal
		,	T1.CodAssessor
		,	T1.NomeAssessor
		,	T1.CodCanal1
		,	T1.DescricaoCanal1
		,	T1.CodCanal2
		,	T1.DescricaoCanal2
		,	T1.CodCanal3
		,	T1.DescricaoCanal3
		,	T1.CodCanal4
		,	T1.DescricaoCanal4
		,	T1.NomeAtendimento
		,	T1.TipoAtendimentoId
		,	DtReferencia										= @FirstDayOfMonth
		,	DtProcessamento										= @CurrentDate

		,	QtdeApoliceTotal									= ISNULL(SUM(T1.QtdeApoliceTotal), 0)
		,	VrTicketMedioPremioLiquidoTotal						= ISNULL(CASE WHEN SUM(T1.QtdeApoliceTotal) = 0 THEN 0 ELSE SUM(T1.VrPremioLiquidoTotal) / SUM(T1.QtdeApoliceTotal) END, 0)
		,	VrPremioLiquidoTotal								= ISNULL(SUM(T1.VrPremioLiquidoTotal), 0)
		,	VrAtingimentoCancelamento							= ABS(ISNULL(CAST(CASE WHEN SUM(VrPremioLiquidoTotal) = 0 THEN 0 ELSE (SUM(VrPremioLiquidoCancelamento) / CAST(SUM(VrPremioLiquidoTotal) AS NUMERIC(18,2)) ) * 100 END AS NUMERIC(18,1)), 0))
		,	VrPremioLiquidoTotalMesAtualAnoAnterior				= ISNULL(SUM(T1.VrPremioLiquidoTotalMesAtualAnoAnterior), 0)
		,	VrCrescMesAtualxMesAtualAnoAnterior					= ISNULL(CAST(CASE WHEN SUM(T1.VrPremioLiquidoTotalMesAtualAnoAnterior) = 0 THEN 0 ELSE (SUM(T1.VrPremioLiquidoTotal) / SUM(T1.VrPremioLiquidoTotalMesAtualAnoAnterior) - 1) * 100 END AS NUMERIC(18,1)), 0)
		,	VrOrcado											= ISNULL(SUM(CAST(T1.VrOrcado AS NUMERIC(18,2))), 0)
		,	VrAtingimento										= ISNULL(CAST(CASE WHEN ISNULL(SUM(T1.VrOrcado), 0) = 0 THEN 0 ELSE (ISNULL(SUM(T1.VrPremioLiquidoTotal), 0) / ISNULL(SUM(T1.VrOrcado), 0)) * 100 END AS NUMERIC(18,1)), 0)  
		,	VrProjecaoAtingimento								= ISNULL(CAST(CASE WHEN ISNULL(SUM(T1.VrOrcado), 0) = 0 THEN 0 ELSE (ISNULL(SUM(T1.VrProjecaoPremioLiquidoTotal), 0) / ISNULL(SUM(T1.VrOrcado), 0)) * 100 END AS NUMERIC(18,1)), 0) 
		,	VrProjecaoPremioLiquidoTotal						= ISNULL(SUM(T1.VrProjecaoPremioLiquidoTotal), 0)
		,	VrPremioLiquidoCancelamento							= ISNULL(SUM(T1.VrPremioLiquidoCancelamento), 0)

		,	QtdeApoliceTotalAnoAcumulado						= ISNULL(SUM(T1.QtdeApoliceTotalAnoAcumulado), 0)
		,	VrTicketMedioPremioLiquidoTotalAnoAcumulado 		= ISNULL(CASE WHEN SUM(T1.QtdeApoliceTotalAnoAcumulado) = 0 THEN 0 ELSE SUM(T1.VrPremioLiquidoTotalAnoAcumulado) / SUM(T1.QtdeApoliceTotalAnoAcumulado) END, 0)
		,	VrPremioLiquidoTotalAnoAcumulado 					= ISNULL(SUM(T1.VrPremioLiquidoTotalAnoAcumulado), 0)
		,	VrAtingimentoCancelamentoAnoAcumulado 				= ABS(ISNULL(CAST(CASE WHEN SUM(T1.VrPremioLiquidoTotalAnoAcumulado) = 0 THEN 0 ELSE (SUM(T1.VrPremioLiquidoCancelamentoAnoAcumulado) / CAST(SUM(T1.VrPremioLiquidoTotalAnoAcumulado) AS NUMERIC(18,2)) ) * 100 END AS NUMERIC(18,1)), 0))
		,	VrOrcadoAnoAcumulado 								= ISNULL(SUM(CAST(T1.VrOrcadoAnoAcumulado AS NUMERIC(18,2))), 0)
		,	VrAtingimentoAnoAcumulado 							= ISNULL(CAST(CASE WHEN ISNULL(SUM(T1.VrOrcadoAnoAcumulado), 0) = 0 THEN 0 ELSE (ISNULL(SUM(T1.VrPremioLiquidoTotalAnoAcumulado), 0) / ISNULL(SUM(T1.VrOrcadoAnoAcumulado), 0)) * 100 END AS NUMERIC(18,1)), 0)
		,	VrPremioLiquidoCancelamentoAnoAcumulado 			= ISNULL(SUM(T1.VrPremioLiquidoCancelamentoAnoAcumulado), 0)
		,	VrPremioLiquidoTotalMesAtualAnoAnteriorAnoAcumulado = ISNULL(SUM(T1.VrPremioLiquidoTotalMesAtualAnoAnteriorAnoAcumulado), 0)
		,	VrCrescMesAtualxMesAtualAnoAnteriorAnoAcumulado 	= ISNULL(CAST(CASE WHEN SUM(T1.VrPremioLiquidoTotalMesAtualAnoAnteriorAnoAcumulado) = 0 THEN 0 ELSE (SUM(T1.VrPremioLiquidoTotalAnoAcumulado) / SUM(T1.VrPremioLiquidoTotalMesAtualAnoAnteriorAnoAcumulado) - 1) * 100 END AS NUMERIC(18,1)), 0)
		,	VrProjecaoAtingimentoAnoAcumulado 					= ISNULL(CAST(CASE WHEN ISNULL(SUM(T1.VrOrcadoAnoAcumulado), 0) = 0 THEN 0 ELSE (ISNULL(SUM(T1.VrProjecaoPremioLiquidoTotalAnoAcumulado), 0) / ISNULL(SUM(T1.VrOrcadoAnoAcumulado), 0)) * 100 END AS NUMERIC(18,1)), 0) 
		,	VrProjecaoPremioLiquidoTotalAnoAcumulado 			= ISNULL(SUM(T1.VrProjecaoPremioLiquidoTotalAnoAcumulado), 0)

		,	CAST(0 AS INT) FlagCorretorAbaixoMeta
		,	CAST(0 AS INT) FlagCorretorAbaixoMetaAnoAcumulado
		,	CAST(0 AS INT) FlagDecrescendoProducao
		,	CAST(0 AS INT) FlagDecrescendoProducaoAnoAcumulado

	INTO #tmp_Raiz
	FROM IndicadorProdutoVidaAnaliticoCarteiraCorretor T1
	WHERE T1.DtReferencia = @FirstDayOfMonth
	GROUP BY
			T1.RaizCpfCnpjCorretor
		,	T1.NomeRaizCorretor
			------------------------------------------------------------
		,	T1.CodTerritorial
		,	T1.NomeTerritorial
		,	T1.CodSucursal
		,	T1.NomeSucursal
		,	T1.CodAssessor
		,	T1.NomeAssessor
		,	T1.CodCanal1
		,	T1.DescricaoCanal1
		,	T1.CodCanal2
		,	T1.DescricaoCanal2
		,	T1.CodCanal3
		,	T1.DescricaoCanal3
		,	T1.CodCanal4
		,	T1.DescricaoCanal4
		,	T1.NomeAtendimento
		,	T1.TipoAtendimentoId;

	-----------------------------------------------------------------------------------------------
	-- Atualizando dados de filtros de decrescimento (FlagDecrescendoProducao e FlagCorretorAbaixoMeta)

	--FlagDecrescendoProducao
	UPDATE #tmp_Raiz
	SET FlagDecrescendoProducao = 1
	WHERE VrCrescMesAtualxMesAtualAnoAnterior < 0;

	--FlagCorretorAbaixoMeta
	UPDATE #tmp_Raiz
	SET FlagCorretorAbaixoMeta = 1
	WHERE VrAtingimento < 100;

	--FlagDecrescendoProducaoAnoAcumulado
	UPDATE #tmp_Raiz
	SET FlagDecrescendoProducaoAnoAcumulado = 1
	WHERE VrCrescMesAtualxMesAtualAnoAnteriorAnoAcumulado < 0;

	--FlagCorretorAbaixoMetaAnoAcumulado
	UPDATE #tmp_Raiz
	SET FlagCorretorAbaixoMetaAnoAcumulado = 1
	WHERE VrAtingimentoAnoAcumulado < 100;


	IF OBJECT_ID('dbo.IndicadorProdutoVidaAnaliticoCarteiraRaiz', 'U') IS NULL
	BEGIN
		-- Criação da tabela caso não exista
		CREATE TABLE dbo.IndicadorProdutoVidaAnaliticoCarteiraRaiz (
			RaizCpfCnpjCorretor VARCHAR(20),
			NomeRaizCorretor VARCHAR(200),
			NomeSetor VARCHAR(200),
			CodTerritorial bigint,
			NomeTerritorial VARCHAR(200),
			CodSucursal bigint,
			NomeSucursal VARCHAR(200),
			CodAssessor VARCHAR(200),
			NomeAssessor VARCHAR(200),
			CodCanal1 INT,
			DescricaoCanal1 VARCHAR(200),
			CodCanal2 INT,
			DescricaoCanal2 VARCHAR(200),
			CodCanal3 bigint,
			DescricaoCanal3 VARCHAR(200),
			CodCanal4 INT,
			DescricaoCanal4 VARCHAR(200),
			NomeAtendimento VARCHAR(200),
			TipoAtendimentoId INT,
			DtReferencia DATE,
			DtProcessamento DATE,

			FlagDecrescendoProducao INT,
			FlagCorretorAbaixoMeta INT,
			QtdeApoliceTotal INT,
			VrTicketMedioPremioLiquidoTotal NUMERIC(18,2),
			VrPremioLiquidoTotal NUMERIC(18,2),
			VrAtingimentoCancelamento NUMERIC(18,1),
			VrPremioLiquidoTotalMesAtualAnoAnterior NUMERIC(18,2),
			VrCrescMesAtualxMesAtualAnoAnterior NUMERIC(18,1),
			VrOrcado NUMERIC(18,2),
			VrAtingimento NUMERIC(18,1),
			VrProjecaoAtingimento NUMERIC(18,1),
			VrProjecaoPremioLiquidoTotal NUMERIC(18,2),
			VrPremioLiquidoCancelamento NUMERIC(18,2),
    
			QtdeApoliceTotalAnoAcumulado INT,
			VrTicketMedioPremioLiquidoTotalAnoAcumulado NUMERIC(18,2),
			VrPremioLiquidoTotalAnoAcumulado NUMERIC(18,2),
			VrAtingimentoCancelamentoAnoAcumulado NUMERIC(18,1),
			VrOrcadoAnoAcumulado NUMERIC(18,2),
			VrAtingimentoAnoAcumulado NUMERIC(18,1),
			VrPremioLiquidoCancelamentoAnoAcumulado NUMERIC(18,2),
			VrPremioLiquidoTotalMesAtualAnoAnteriorAnoAcumulado NUMERIC(18,2),
			VrCrescMesAtualxMesAtualAnoAnteriorAnoAcumulado NUMERIC(18,1),
			VrProjecaoAtingimentoAnoAcumulado NUMERIC(18,1),
			VrProjecaoPremioLiquidoTotalAnoAcumulado NUMERIC(18,2),
			FlagDecrescendoProducaoAnoAcumulado INT,
			FlagCorretorAbaixoMetaAnoAcumulado INT
		);
	END;

	-- Delete a base analitica
	WHILE (1=1)
	BEGIN
		DELETE TOP(100000)
		FROM dbo.IndicadorProdutoVidaAnaliticoCarteiraRaiz
		WHERE DtReferencia = @FirstDayOfMonth
		SET @Qt_Linhas = @@ROWCOUNT
		SET @Total_Linhas = @Total_Linhas + @Qt_Linhas
			IF (@Qt_Linhas = 0)
				BREAK
		SET @Msg = CONCAT('Quantidade de Linhas Apagadas: ', @Qt_Linhas, ' - Total Deletado: ', @Total_Linhas)
			RAISERROR(@Msg, 1, 1) WITH NOWAIT
	END

	INSERT INTO IndicadorProdutoVidaAnaliticoCarteiraRaiz
	(
		RaizCpfCnpjCorretor
	,	NomeRaizCorretor
	,	NomeSetor
	,	CodTerritorial
	,	NomeTerritorial
	,	CodSucursal
	,	NomeSucursal
	,	CodAssessor
	,	NomeAssessor
	,	CodCanal1
	,	DescricaoCanal1
	,	CodCanal2
	,	DescricaoCanal2
	,	CodCanal3
	,	DescricaoCanal3
	,	CodCanal4
	,	DescricaoCanal4
	,	NomeAtendimento
	,	TipoAtendimentoId
	,	DtReferencia
	,	DtProcessamento
		-------------------------------------------
	,	FlagDecrescendoProducao
	,	FlagCorretorAbaixoMeta
	,	QtdeApoliceTotal
	,	VrTicketMedioPremioLiquidoTotal
	,	VrPremioLiquidoTotal
	,	VrAtingimentoCancelamento
	,	VrPremioLiquidoTotalMesAtualAnoAnterior
	,	VrCrescMesAtualxMesAtualAnoAnterior
	,	VrOrcado
	,	VrAtingimento
	,	VrProjecaoAtingimento
	,	VrProjecaoPremioLiquidoTotal
	,	VrPremioLiquidoCancelamento
		-------------------------------------------
	,	QtdeApoliceTotalAnoAcumulado
	,	VrTicketMedioPremioLiquidoTotalAnoAcumulado
	,	VrPremioLiquidoTotalAnoAcumulado
	,	VrAtingimentoCancelamentoAnoAcumulado
	,	VrOrcadoAnoAcumulado
	,	VrAtingimentoAnoAcumulado
	,	VrPremioLiquidoCancelamentoAnoAcumulado
	,	VrPremioLiquidoTotalMesAtualAnoAnteriorAnoAcumulado
	,	VrCrescMesAtualxMesAtualAnoAnteriorAnoAcumulado
	,	VrProjecaoAtingimentoAnoAcumulado
	,	VrProjecaoPremioLiquidoTotalAnoAcumulado
	,	FlagDecrescendoProducaoAnoAcumulado
	,	FlagCorretorAbaixoMetaAnoAcumulado
	)
	SELECT
		RaizCpfCnpjCorretor
	,	NomeRaizCorretor
	,	NomeSetor
	,	CodTerritorial
	,	NomeTerritorial
	,	CodSucursal
	,	NomeSucursal
	,	CodAssessor
	,	NomeAssessor
	,	CodCanal1
	,	DescricaoCanal1
	,	CodCanal2
	,	DescricaoCanal2
	,	CodCanal3
	,	DescricaoCanal3
	,	CodCanal4
	,	DescricaoCanal4
	,	NomeAtendimento
	,	TipoAtendimentoId
	,	DtReferencia
	,	DtProcessamento
		-------------------------------------------
	,	FlagDecrescendoProducao
	,	FlagCorretorAbaixoMeta
	,	QtdeApoliceTotal
	,	VrTicketMedioPremioLiquidoTotal
	,	VrPremioLiquidoTotal
	,	VrAtingimentoCancelamento
	,	VrPremioLiquidoTotalMesAtualAnoAnterior
	,	VrCrescMesAtualxMesAtualAnoAnterior
	,	VrOrcado
	,	VrAtingimento
	,	VrProjecaoAtingimento
	,	VrProjecaoPremioLiquidoTotal
	,	VrPremioLiquidoCancelamento
		-------------------------------------------
	,	QtdeApoliceTotalAnoAcumulado
	,	VrTicketMedioPremioLiquidoTotalAnoAcumulado
	,	VrPremioLiquidoTotalAnoAcumulado
	,	VrAtingimentoCancelamentoAnoAcumulado
	,	VrOrcadoAnoAcumulado
	,	VrAtingimentoAnoAcumulado
	,	VrPremioLiquidoCancelamentoAnoAcumulado
	,	VrPremioLiquidoTotalMesAtualAnoAnteriorAnoAcumulado
	,	VrCrescMesAtualxMesAtualAnoAnteriorAnoAcumulado
	,	VrProjecaoAtingimentoAnoAcumulado
	,	VrProjecaoPremioLiquidoTotalAnoAcumulado
	,	FlagDecrescendoProducaoAnoAcumulado
	,	FlagCorretorAbaixoMetaAnoAcumulado
	FROM #tmp_Raiz

END
GO

------------------------------------------------------------------------------------------------------------------------------------------

/****** Object:  StoredProcedure [dbo].[sp_GerarIndicadorProdutoVidaAnaliticoCarteiraRaiz]    Script Date: 07/04/2025 11:29:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_GerarIndicadorProdutoVidaAnaliticoCarteiraRaiz]
(
	@CurrentDate DATE = NULL -- '2025-04-03'
)
AS
BEGIN

	DECLARE 
		@FirstDayOfMonth             DATE,
		@LastDayOfMonth              DATE,
		@FirstDaySkFecha             VARCHAR(8),   -- Reduzido para 8 caracteres (yyyymmdd)
		@LastDaySkFecha              VARCHAR(8),
		@Msg                         VARCHAR(MAX),
		@Qt_Linhas                   INT,
		@Total_Linhas                INT = 0,
		@QTDE_INSERT                 INT = 0,
		@DiasUteisSemFDS             INT,
		@DiasUteisParaFimSemFDS      INT,
		@TotalDiasUteis              INT,
		@FirstDayOfYear              DATE,
		@FirstDayPreviousMonth       DATE,
		@DiasSegParaFim              INT,
		@DiasUteisSemSegunda         INT,
		@DiasUteisParaFimSemSegunda  INT,
		@DiasSeg                     INT,
		@LastDayOfNextMonth          DATE,
		@LastDayOfNextMonthSkFecha   VARCHAR(8),
		@NR_ANO_MES                  INT,
		@FirstDayOfMonthLastYear     DATE;

	-- Define @CurrentDate se estiver NULL
	SET @CurrentDate = ISNULL(@CurrentDate, DATEADD(DAY, -1, GETDATE()));

	-- Definição das datas principais
	SET @FirstDayOfMonth           = DATEADD(DAY, 1 - DAY(@CurrentDate), @CurrentDate);
	SET @LastDayOfMonth            = EOMONTH(@CurrentDate);
	SET @FirstDaySkFecha           = CONVERT(VARCHAR(8), @FirstDayOfMonth, 112);
	SET @LastDaySkFecha            = CONVERT(VARCHAR(8), @LastDayOfMonth, 112);
	SET @DiasUteisSemFDS           = dbo.ContarDiasUteisSemFDS(@FirstDayOfMonth, @CurrentDate);
	SET @DiasUteisParaFimSemFDS    = dbo.ContarDiasUteisFaltantesSemFDS(@CurrentDate, @LastDayOfMonth);
	SET @TotalDiasUteis            = @DiasUteisSemFDS + @DiasUteisParaFimSemFDS;
	SET @FirstDayOfYear            = DATEFROMPARTS(YEAR(@CurrentDate), 1, 1);
	SET @FirstDayPreviousMonth     = DATEADD(MONTH, -1, @FirstDayOfMonth);
	SET @DiasSegParaFim            = dbo.ContarSabadDomSeg(@CurrentDate, @LastDayOfMonth);
	SET @DiasUteisSemSegunda       = dbo.ContarDiasUteis(@FirstDayOfMonth, @CurrentDate);
	SET @DiasUteisParaFimSemSegunda= dbo.ContarDiasUteisFaltantes(@CurrentDate, @LastDayOfMonth);
	SET @DiasSeg                   = dbo.ContarSabadDomSeg(@FirstDayOfMonth, @CurrentDate);
	SET @LastDayOfNextMonth        = EOMONTH(DATEADD(MONTH, 1, @CurrentDate));
	SET @LastDayOfNextMonthSkFecha = CONVERT(VARCHAR(8), @LastDayOfNextMonth, 112);
	SET @NR_ANO_MES                = CONVERT(INT, FORMAT(@CurrentDate, 'yyyyMM'));
	SET @FirstDayOfMonthLastYear   = DATEADD(YEAR, -1, @FirstDayOfMonth);

	-- ====================================================================================================================================
	--
	--													INÍCIO DO CALCULO DE RAIZ
	--
	-- ====================================================================================================================================

	DROP TABLE IF EXISTS #tmp_Raiz;

	SELECT
			T1.RaizCpfCnpjCorretor
		,	T1.NomeRaizCorretor
		,	NULL AS NomeSetor
			------------------------------------------------------------
		,	T1.CodTerritorial
		,	T1.NomeTerritorial
		,	T1.CodSucursal
		,	T1.NomeSucursal
		,	T1.CodAssessor
		,	T1.NomeAssessor
		,	T1.CodCanal1
		,	T1.DescricaoCanal1
		,	T1.CodCanal2
		,	T1.DescricaoCanal2
		,	T1.CodCanal3
		,	T1.DescricaoCanal3
		,	T1.CodCanal4
		,	T1.DescricaoCanal4
		,	T1.NomeAtendimento
		,	T1.TipoAtendimentoId
		,	DtReferencia										= @FirstDayOfMonth
		,	DtProcessamento										= @CurrentDate

		,	QtdeApoliceTotal									= ISNULL(SUM(T1.QtdeApoliceTotal), 0)
		,	VrTicketMedioPremioLiquidoTotal						= ISNULL(CASE WHEN SUM(T1.QtdeApoliceTotal) = 0 THEN 0 ELSE SUM(T1.VrPremioLiquidoTotal) / SUM(T1.QtdeApoliceTotal) END, 0)
		,	VrPremioLiquidoTotal								= ISNULL(SUM(T1.VrPremioLiquidoTotal), 0)
		,	VrAtingimentoCancelamento							= ABS(ISNULL(CAST(CASE WHEN SUM(VrPremioLiquidoTotal) = 0 THEN 0 ELSE (SUM(VrPremioLiquidoCancelamento) / CAST(SUM(VrPremioLiquidoTotal) AS NUMERIC(18,2)) ) * 100 END AS NUMERIC(18,1)), 0))
		,	VrPremioLiquidoTotalMesAtualAnoAnterior				= ISNULL(SUM(T1.VrPremioLiquidoTotalMesAtualAnoAnterior), 0)
		,	VrCrescMesAtualxMesAtualAnoAnterior					= ISNULL(CAST(CASE WHEN SUM(T1.VrPremioLiquidoTotalMesAtualAnoAnterior) = 0 THEN 0 ELSE (SUM(T1.VrPremioLiquidoTotal) / SUM(T1.VrPremioLiquidoTotalMesAtualAnoAnterior) - 1) * 100 END AS NUMERIC(18,1)), 0)
		,	VrOrcado											= ISNULL(SUM(CAST(T1.VrOrcado AS NUMERIC(18,2))), 0)
		,	VrAtingimento										= ISNULL(CAST(CASE WHEN ISNULL(SUM(T1.VrOrcado), 0) = 0 THEN 0 ELSE (ISNULL(SUM(T1.VrPremioLiquidoTotal), 0) / ISNULL(SUM(T1.VrOrcado), 0)) * 100 END AS NUMERIC(18,1)), 0)  
		,	VrProjecaoAtingimento								= ISNULL(CAST(CASE WHEN ISNULL(SUM(T1.VrOrcado), 0) = 0 THEN 0 ELSE (ISNULL(SUM(T1.VrProjecaoPremioLiquidoTotal), 0) / ISNULL(SUM(T1.VrOrcado), 0)) * 100 END AS NUMERIC(18,1)), 0) 
		,	VrProjecaoPremioLiquidoTotal						= ISNULL(SUM(T1.VrProjecaoPremioLiquidoTotal), 0)
		,	VrPremioLiquidoCancelamento							= ISNULL(SUM(T1.VrPremioLiquidoCancelamento), 0)

		,	QtdeApoliceTotalAnoAcumulado						= ISNULL(SUM(T1.QtdeApoliceTotalAnoAcumulado), 0)
		,	VrTicketMedioPremioLiquidoTotalAnoAcumulado 		= ISNULL(CASE WHEN SUM(T1.QtdeApoliceTotalAnoAcumulado) = 0 THEN 0 ELSE SUM(T1.VrPremioLiquidoTotalAnoAcumulado) / SUM(T1.QtdeApoliceTotalAnoAcumulado) END, 0)
		,	VrPremioLiquidoTotalAnoAcumulado 					= ISNULL(SUM(T1.VrPremioLiquidoTotalAnoAcumulado), 0)
		,	VrAtingimentoCancelamentoAnoAcumulado 				= ABS(ISNULL(CAST(CASE WHEN SUM(T1.VrPremioLiquidoTotalAnoAcumulado) = 0 THEN 0 ELSE (SUM(T1.VrPremioLiquidoCancelamentoAnoAcumulado) / CAST(SUM(T1.VrPremioLiquidoTotalAnoAcumulado) AS NUMERIC(18,2)) ) * 100 END AS NUMERIC(18,1)), 0))
		,	VrOrcadoAnoAcumulado 								= ISNULL(SUM(CAST(T1.VrOrcadoAnoAcumulado AS NUMERIC(18,2))), 0)
		,	VrAtingimentoAnoAcumulado 							= ISNULL(CAST(CASE WHEN ISNULL(SUM(T1.VrOrcadoAnoAcumulado), 0) = 0 THEN 0 ELSE (ISNULL(SUM(T1.VrPremioLiquidoTotalAnoAcumulado), 0) / ISNULL(SUM(T1.VrOrcadoAnoAcumulado), 0)) * 100 END AS NUMERIC(18,1)), 0)
		,	VrPremioLiquidoCancelamentoAnoAcumulado 			= ISNULL(SUM(T1.VrPremioLiquidoCancelamentoAnoAcumulado), 0)
		,	VrPremioLiquidoTotalMesAtualAnoAnteriorAnoAcumulado = ISNULL(SUM(T1.VrPremioLiquidoTotalMesAtualAnoAnteriorAnoAcumulado), 0)
		,	VrCrescMesAtualxMesAtualAnoAnteriorAnoAcumulado 	= ISNULL(CAST(CASE WHEN SUM(T1.VrPremioLiquidoTotalMesAtualAnoAnteriorAnoAcumulado) = 0 THEN 0 ELSE (SUM(T1.VrPremioLiquidoTotalAnoAcumulado) / SUM(T1.VrPremioLiquidoTotalMesAtualAnoAnteriorAnoAcumulado) - 1) * 100 END AS NUMERIC(18,1)), 0)
		,	VrProjecaoAtingimentoAnoAcumulado 					= ISNULL(CAST(CASE WHEN ISNULL(SUM(T1.VrOrcadoAnoAcumulado), 0) = 0 THEN 0 ELSE (ISNULL(SUM(T1.VrProjecaoPremioLiquidoTotalAnoAcumulado), 0) / ISNULL(SUM(T1.VrOrcadoAnoAcumulado), 0)) * 100 END AS NUMERIC(18,1)), 0) 
		,	VrProjecaoPremioLiquidoTotalAnoAcumulado 			= ISNULL(SUM(T1.VrProjecaoPremioLiquidoTotalAnoAcumulado), 0)

		,	CAST(0 AS INT) FlagCorretorAbaixoMeta
		,	CAST(0 AS INT) FlagCorretorAbaixoMetaAnoAcumulado
		,	CAST(0 AS INT) FlagDecrescendoProducao
		,	CAST(0 AS INT) FlagDecrescendoProducaoAnoAcumulado

	INTO #tmp_Raiz
	FROM IndicadorProdutoVidaAnaliticoCarteiraCorretor T1
	WHERE T1.DtReferencia = @FirstDayOfMonth
	GROUP BY
			T1.RaizCpfCnpjCorretor
		,	T1.NomeRaizCorretor
			------------------------------------------------------------
		,	T1.CodTerritorial
		,	T1.NomeTerritorial
		,	T1.CodSucursal
		,	T1.NomeSucursal
		,	T1.CodAssessor
		,	T1.NomeAssessor
		,	T1.CodCanal1
		,	T1.DescricaoCanal1
		,	T1.CodCanal2
		,	T1.DescricaoCanal2
		,	T1.CodCanal3
		,	T1.DescricaoCanal3
		,	T1.CodCanal4
		,	T1.DescricaoCanal4
		,	T1.NomeAtendimento
		,	T1.TipoAtendimentoId;

	-----------------------------------------------------------------------------------------------
	-- Atualizando dados de filtros de decrescimento (FlagDecrescendoProducao e FlagCorretorAbaixoMeta)

	--FlagDecrescendoProducao
	UPDATE #tmp_Raiz
	SET FlagDecrescendoProducao = 1
	WHERE VrCrescMesAtualxMesAtualAnoAnterior < 0;

	--FlagCorretorAbaixoMeta
	UPDATE #tmp_Raiz
	SET FlagCorretorAbaixoMeta = 1
	WHERE VrAtingimento < 100;

	--FlagDecrescendoProducaoAnoAcumulado
	UPDATE #tmp_Raiz
	SET FlagDecrescendoProducaoAnoAcumulado = 1
	WHERE VrCrescMesAtualxMesAtualAnoAnteriorAnoAcumulado < 0;

	--FlagCorretorAbaixoMetaAnoAcumulado
	UPDATE #tmp_Raiz
	SET FlagCorretorAbaixoMetaAnoAcumulado = 1
	WHERE VrAtingimentoAnoAcumulado < 100;


	IF OBJECT_ID('dbo.IndicadorProdutoVidaAnaliticoCarteiraRaiz', 'U') IS NULL
	BEGIN
		-- Criação da tabela caso não exista
		CREATE TABLE dbo.IndicadorProdutoVidaAnaliticoCarteiraRaiz (
			RaizCpfCnpjCorretor VARCHAR(20),
			NomeRaizCorretor VARCHAR(200),
			NomeSetor VARCHAR(200),
			CodTerritorial bigint,
			NomeTerritorial VARCHAR(200),
			CodSucursal bigint,
			NomeSucursal VARCHAR(200),
			CodAssessor VARCHAR(200),
			NomeAssessor VARCHAR(200),
			CodCanal1 INT,
			DescricaoCanal1 VARCHAR(200),
			CodCanal2 INT,
			DescricaoCanal2 VARCHAR(200),
			CodCanal3 bigint,
			DescricaoCanal3 VARCHAR(200),
			CodCanal4 INT,
			DescricaoCanal4 VARCHAR(200),
			NomeAtendimento VARCHAR(200),
			TipoAtendimentoId INT,
			DtReferencia DATE,
			DtProcessamento DATE,

			FlagDecrescendoProducao INT,
			FlagCorretorAbaixoMeta INT,
			QtdeApoliceTotal INT,
			VrTicketMedioPremioLiquidoTotal NUMERIC(18,2),
			VrPremioLiquidoTotal NUMERIC(18,2),
			VrAtingimentoCancelamento NUMERIC(18,1),
			VrPremioLiquidoTotalMesAtualAnoAnterior NUMERIC(18,2),
			VrCrescMesAtualxMesAtualAnoAnterior NUMERIC(18,1),
			VrOrcado NUMERIC(18,2),
			VrAtingimento NUMERIC(18,1),
			VrProjecaoAtingimento NUMERIC(18,1),
			VrProjecaoPremioLiquidoTotal NUMERIC(18,2),
			VrPremioLiquidoCancelamento NUMERIC(18,2),
    
			QtdeApoliceTotalAnoAcumulado INT,
			VrTicketMedioPremioLiquidoTotalAnoAcumulado NUMERIC(18,2),
			VrPremioLiquidoTotalAnoAcumulado NUMERIC(18,2),
			VrAtingimentoCancelamentoAnoAcumulado NUMERIC(18,1),
			VrOrcadoAnoAcumulado NUMERIC(18,2),
			VrAtingimentoAnoAcumulado NUMERIC(18,1),
			VrPremioLiquidoCancelamentoAnoAcumulado NUMERIC(18,2),
			VrPremioLiquidoTotalMesAtualAnoAnteriorAnoAcumulado NUMERIC(18,2),
			VrCrescMesAtualxMesAtualAnoAnteriorAnoAcumulado NUMERIC(18,1),
			VrProjecaoAtingimentoAnoAcumulado NUMERIC(18,1),
			VrProjecaoPremioLiquidoTotalAnoAcumulado NUMERIC(18,2),
			FlagDecrescendoProducaoAnoAcumulado INT,
			FlagCorretorAbaixoMetaAnoAcumulado INT
		);
	END;

	-- Delete a base analitica
	WHILE (1=1)
	BEGIN
		DELETE TOP(100000)
		FROM dbo.IndicadorProdutoVidaAnaliticoCarteiraRaiz
		WHERE DtReferencia = @FirstDayOfMonth
		SET @Qt_Linhas = @@ROWCOUNT
		SET @Total_Linhas = @Total_Linhas + @Qt_Linhas
			IF (@Qt_Linhas = 0)
				BREAK
		SET @Msg = CONCAT('Quantidade de Linhas Apagadas: ', @Qt_Linhas, ' - Total Deletado: ', @Total_Linhas)
			RAISERROR(@Msg, 1, 1) WITH NOWAIT
	END

	INSERT INTO IndicadorProdutoVidaAnaliticoCarteiraRaiz
	(
		RaizCpfCnpjCorretor
	,	NomeRaizCorretor
	,	NomeSetor
	,	CodTerritorial
	,	NomeTerritorial
	,	CodSucursal
	,	NomeSucursal
	,	CodAssessor
	,	NomeAssessor
	,	CodCanal1
	,	DescricaoCanal1
	,	CodCanal2
	,	DescricaoCanal2
	,	CodCanal3
	,	DescricaoCanal3
	,	CodCanal4
	,	DescricaoCanal4
	,	NomeAtendimento
	,	TipoAtendimentoId
	,	DtReferencia
	,	DtProcessamento
		-------------------------------------------
	,	FlagDecrescendoProducao
	,	FlagCorretorAbaixoMeta
	,	QtdeApoliceTotal
	,	VrTicketMedioPremioLiquidoTotal
	,	VrPremioLiquidoTotal
	,	VrAtingimentoCancelamento
	,	VrPremioLiquidoTotalMesAtualAnoAnterior
	,	VrCrescMesAtualxMesAtualAnoAnterior
	,	VrOrcado
	,	VrAtingimento
	,	VrProjecaoAtingimento
	,	VrProjecaoPremioLiquidoTotal
	,	VrPremioLiquidoCancelamento
		-------------------------------------------
	,	QtdeApoliceTotalAnoAcumulado
	,	VrTicketMedioPremioLiquidoTotalAnoAcumulado
	,	VrPremioLiquidoTotalAnoAcumulado
	,	VrAtingimentoCancelamentoAnoAcumulado
	,	VrOrcadoAnoAcumulado
	,	VrAtingimentoAnoAcumulado
	,	VrPremioLiquidoCancelamentoAnoAcumulado
	,	VrPremioLiquidoTotalMesAtualAnoAnteriorAnoAcumulado
	,	VrCrescMesAtualxMesAtualAnoAnteriorAnoAcumulado
	,	VrProjecaoAtingimentoAnoAcumulado
	,	VrProjecaoPremioLiquidoTotalAnoAcumulado
	,	FlagDecrescendoProducaoAnoAcumulado
	,	FlagCorretorAbaixoMetaAnoAcumulado
	)
	SELECT
		RaizCpfCnpjCorretor
	,	NomeRaizCorretor
	,	NomeSetor
	,	CodTerritorial
	,	NomeTerritorial
	,	CodSucursal
	,	NomeSucursal
	,	CodAssessor
	,	NomeAssessor
	,	CodCanal1
	,	DescricaoCanal1
	,	CodCanal2
	,	DescricaoCanal2
	,	CodCanal3
	,	DescricaoCanal3
	,	CodCanal4
	,	DescricaoCanal4
	,	NomeAtendimento
	,	TipoAtendimentoId
	,	DtReferencia
	,	DtProcessamento
		-------------------------------------------
	,	FlagDecrescendoProducao
	,	FlagCorretorAbaixoMeta
	,	QtdeApoliceTotal
	,	VrTicketMedioPremioLiquidoTotal
	,	VrPremioLiquidoTotal
	,	VrAtingimentoCancelamento
	,	VrPremioLiquidoTotalMesAtualAnoAnterior
	,	VrCrescMesAtualxMesAtualAnoAnterior
	,	VrOrcado
	,	VrAtingimento
	,	VrProjecaoAtingimento
	,	VrProjecaoPremioLiquidoTotal
	,	VrPremioLiquidoCancelamento
		-------------------------------------------
	,	QtdeApoliceTotalAnoAcumulado
	,	VrTicketMedioPremioLiquidoTotalAnoAcumulado
	,	VrPremioLiquidoTotalAnoAcumulado
	,	VrAtingimentoCancelamentoAnoAcumulado
	,	VrOrcadoAnoAcumulado
	,	VrAtingimentoAnoAcumulado
	,	VrPremioLiquidoCancelamentoAnoAcumulado
	,	VrPremioLiquidoTotalMesAtualAnoAnteriorAnoAcumulado
	,	VrCrescMesAtualxMesAtualAnoAnteriorAnoAcumulado
	,	VrProjecaoAtingimentoAnoAcumulado
	,	VrProjecaoPremioLiquidoTotalAnoAcumulado
	,	FlagDecrescendoProducaoAnoAcumulado
	,	FlagCorretorAbaixoMetaAnoAcumulado
	FROM #tmp_Raiz

END
GO
