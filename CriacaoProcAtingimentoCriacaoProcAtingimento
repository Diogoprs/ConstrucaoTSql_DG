/****** Object:  StoredProcedure [dbo].[sp_GerarIndicadorAtingimentoPremioLiquidoAuto_20250417]    Script Date: 17/04/2025 17:08:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_GerarIndicadorAtingimentoPremioLiquidoAuto]
(
	@CurrentDate DATE = NULL -- '2024-09-16'
)
AS
BEGIN

	-- ====================================================================================================================================
	-- Data da Criacao		Autor										Descricao
	-- =================	========================================	===================================================================
	-- ====================================================================================================================================
	--
	--											ATINGIMENTO PREMIO LIQUIDO - PRODUTO AUTO 
	--
	-- ====================================================================================================================================

	DECLARE 
		@FirstDayOfMonth		DATE
	,	@LastDayOfMonth			DATE
	,	@FirstDaySkFecha		VARCHAR(200)
	,	@LastDaySkFecha			VARCHAR(200)
	,	@Msg					VARCHAR(MAX)
	,	@Qt_Linhas				INT
	,	@Total_Linhas			INT = 0
	,	@QTDE_INSERT			INT = 0
	,	@DiasUteisSemFDS		INT
	,	@DiasUteisParaFimSemFDS INT
	,	@TotalDiasUteis			INT
	,	@FirstDayOfYear         DATE
	,	@FirstDayPreviousMonth  DATE
	,	@FirstDayPreviousYear  	DATE
	,	@FirstDayPreviousMonthPreviousYear	DATE
	,	@FirstDayOfMonthLastYear DATE


	SET @CurrentDate			= CASE WHEN @CurrentDate IS NULL THEN DATEADD(DAY, -1, GETDATE() ) ELSE @CurrentDate END
	SET @FirstDayOfMonth		= DATEADD(DAY, 1 - DAY(@CurrentDate), @CurrentDate)
	SET @LastDayOfMonth			= EOMONTH(@CurrentDate)
	SET @FirstDaySkFecha		= convert(varchar, DATEADD(DAY, 1 - DAY(@CurrentDate), @CurrentDate), 112)
	SET @LastDaySkFecha			= convert(varchar, eomonth(@CurrentDate), 112)
	SET @DiasUteisSemFDS		= dbo.ContarDiasUteisSemFDS(@FirstDayOfMonth, @CurrentDate)
	SET @DiasUteisParaFimSemFDS = dbo.ContarDiasUteisFaltantesSemFDS(@CurrentDate, @LastDayOfMonth)
	SET @TotalDiasUteis			= @DiasUteisSemFDS + @DiasUteisParaFimSemFDS
	SET @FirstDayOfYear			= DATEFROMPARTS(YEAR(@CurrentDate), 1, 1)
	SET @FirstDayPreviousMonth	= DATEADD(MONTH, -1, DATEADD(DAY, 1 - DAY(@CurrentDate), @CurrentDate))
	SET @FirstDayPreviousYear	= DATEFROMPARTS(YEAR(@CurrentDate) - 1, 1, 1)
	SET @FirstDayPreviousMonthPreviousYear = CASE WHEN MONTH(@CurrentDate) = 1 THEN DATEFROMPARTS(YEAR(@CurrentDate) - 1, 12, 1) ELSE DATEFROMPARTS(YEAR(@CurrentDate) - 1, MONTH(@CurrentDate) - 1, 1) END
	SET @FirstDayOfMonthLastYear = DATEADD(YEAR, -1, @FirstDayOfMonth)

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
	--,	@FirstDayPreviousYear FirstDayPreviousYear
	--,	@FirstDayPreviousMonthPreviousYear FirstDayPreviousMonthPreviousYear
	--,	@FirstDayOfMonthLastYear FirstDayOfMonthLastYear

	-- ====================================================================================================================================
	--
	--													GERANDO A TEMPORARIA 
	--
	-- ====================================================================================================================================

	-- ====================================================================================================================================
	-- Separando a base de tipo de atendimento

	DROP TABLE IF EXISTS #TMP_RDS_TIPO_ATENDIMENTO

	select CpfCnpj AS CodAssessor, MAX(TipoAtendimentoId) TipoAtendimentoId
	INTO #TMP_RDS_TIPO_ATENDIMENTO
	FROM dbo.Usuario U
	WHERE U.Ativo = 1
	AND U.CargoId = 2
	group by CpfCnpj, TipoAtendimentoId

	-- ====================================================================================================================================
	-- Capturando os corretores/ramo e setor que nao existem no mes atual

	drop table if exists #tmp_rds_base_corretor

	select distinct A.CodCorretor, A.NomeRamo, A.NomeSetor
	into #tmp_rds_base_corretor
	from
	(
		select distinct CodCorretor,  Upper(NomeRamo) as NomeRamo, NomeSetor 
		from IndicadorProdutoAutoSinteticoPremio WITH (NOLOCK)	
		WHERE DtReferencia between @FirstDayPreviousYear and @FirstDayPreviousMonth

		union

		select distinct CodCorretor, Upper(NomeUnidade) as NomeRamo, NomeSetor 
		from dbo.tbOrcado with (nolock)
		where NrAnoMes = @FirstDayOfMonth
		and NomeUnidade = 'Automovel'

		union

		select distinct CodCorretor,  Upper(NomeRamo) as NomeRamo, NomeSetor 
		from IndicadorProdutoAutoSinteticoCotacao WITH (NOLOCK)	
		WHERE DtReferencia = @FirstDayOfMonth

		union

		select distinct CodCorretor,  Upper(NomeRamo) as NomeRamo, NomeSetor 
		from IndicadorProdutoAutoSinteticoCotacao WITH (NOLOCK)	
		WHERE DtReferencia between @FirstDayPreviousYear and @FirstDayPreviousMonth

		union

		select distinct CodCorretor,  Upper(NomeRamo) as NomeRamo, NomeSetor 
		FROM dbo.IndicadorProdutoAutoSinteticoRenovacao t1 with (nolock)
		WHERE t1.DtReferencia = @FirstDayOfMonth

		union

		select distinct CodCorretor,  Upper(NomeRamo) as NomeRamo, NomeSetor 
		FROM dbo.IndicadorProdutoAutoSinteticoRenovacao with (nolock)
		WHERE DtReferencia between @FirstDayPreviousYear and @FirstDayPreviousMonth

		union

		select distinct CodCorretor,  'AUTOMOVEL' NomeRamo, 'Indeterminado' NomeSetor 
		FROM dbo.HierarquiaComercialUnificada with (nolock)
		where CodCorretor not in (
									select distinct CodCorretor 
									from IndicadorProdutoAutoSinteticoPremio WITH (NOLOCK) 
									WHERE DtReferencia = @FirstDayOfMonth
							     )
		
	) A
	EXCEPT
	select distinct CodCorretor, NomeRamo, NomeSetor 
	from IndicadorProdutoAutoSinteticoPremio WITH (NOLOCK)
	WHERE DtReferencia = @FirstDayOfMonth 

	-- ====================================================================================================================================
	-- Enriquecendo os corretores com a informacao da hierarquia comercial e canal

	DROP TABLE IF EXISTS #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO

	SELECT
		DtReferencia												= @FirstDayOfMonth
	,	DtProcessamento												= @CurrentDate
	,	CodCorretor													= T1.CodCorretor
	,	NomeCorretor												= T2.NomeCorretor
	,	RaizCpfCnpjCorretor											= T2.RaizCpfCnpjCorretor
	,	CodAssessor													= T2.CodAssessor
	,	NomeAssessor												= T2.NomeAssessor
	,	CodSucursal													= T2.CodSucursal
	,	NomeSucursal												= T2.NomeSucursal
	,	CodTerritorial												= T2.CodTerritorial
	,	NomeTerritorial												= T2.NomeTerritorial
	,	CodCanal1													= T3.COD_CONSOLIDADO_CANAL 
	,	DescricaoCanal1												= T3.DESCR_CONSOLIDADO_CANAL 
	,	CodCanal2													= T3.COD_GRUPO_CANAL 
	,	DescricaoCanal2												= T3.DESC_GRUPO_CANAL 
	,	CodCanal3													= T3.COD_GERENTE_CANAL 
	,	DescricaoCanal3												= T3.DESC_GERENTE_CANAL 
	,	CodCanal4													= T3.COD_CONVENIO 
	,	DescricaoCanal4												= T3.DESC_CONVENIO 
	,	TipoAtendimentoId											= CAST(NULL AS INT)
	,	NomeAtendimento												= CAST(NULL AS VARCHAR(200))
	,	NomeRamo													= T1.NomeRamo
	,	NomeSetor													= T1.NomeSetor
	-- =======================================================================================
	-- Mes Atual: 
	---- Sintetico Premio
	,	VrPremioLiquidoApoliceNovaProducao							= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoNovaProducao							= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoApoliceRenovacao								= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoRenovacao								= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoTotal										= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeApoliceApoliceNovaProducao								= CAST('0' AS INT)
	,	QtdeApoliceEndossoNovaProducao								= CAST('0' AS INT)
	,	QtdeApoliceApoliceRenovacao									= CAST('0' AS INT)
	,	QtdeApoliceEndossoRenovacao									= CAST('0' AS INT)
	,	QtdeApoliceTotal											= CAST('0' AS INT)
	,	VrProjecaoIndividualPrimeiraSemana							= CAST('0.00' AS NUMERIC(18,2))
	,	VrProjecaoIndividualSemSegunda								= CAST('0.00' AS NUMERIC(18,2))
	,	VrProjecaoIndividualComSegunda								= CAST('0.00' AS NUMERIC(18,2))
	,	VrProjecaoIndividual										= CAST('0.00' AS NUMERIC(18,2))
	,	VrProjecaoCaminhao											= CAST('0.00' AS NUMERIC(18,2))
	,	VrProjecaoFrota												= CAST('0.00' AS NUMERIC(18,2))
	,	VrProjecaoLiquidoTotal										= CAST('0.00' AS NUMERIC(18,2))
	---- Sintetico Cotacao
	,	VrPremioCotacaoRecusada										= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoLiquida										= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoTotal										= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeCotacaoRecusada											= CAST('0' AS INT)
	,	QtdeCotacaoLiquida											= CAST('0' AS INT)
	,	QtdeCotacaoTotal											= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoRecusada									= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoLiquida									= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoTotal										= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoRecusada						= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoLiquida						= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoTotal							= CAST('0' AS INT)
	,	QtdePropostaEmitida											= CAST('0' AS INT)
	,	QtdePropostaPendente										= CAST('0' AS INT)
	,	QtdePropostaTotal											= CAST('0' AS INT)
	,	QtdeCotacaoApoliceTotal										= CAST('0' AS INT)
	-- =======================================================================================
	-- Mes Atual Ano Anterior (MesAtualAnoAnterior)
	---- Sintetico Premio
	,	VrPremioLiquidoApoliceNovaProducaoMesAtualAnoAnterior		= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoNovaProducaoMesAtualAnoAnterior		= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoApoliceRenovacaoMesAtualAnoAnterior			= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoRenovacaoMesAtualAnoAnterior			= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoTotalMesAtualAnoAnterior						= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeApoliceApoliceNovaProducaoMesAtualAnoAnterior			= CAST('0' AS INT)
	,	QtdeApoliceEndossoNovaProducaoMesAtualAnoAnterior			= CAST('0' AS INT)
	,	QtdeApoliceApoliceRenovacaoMesAtualAnoAnterior				= CAST('0' AS INT)
	,	QtdeApoliceEndossoRenovacaoMesAtualAnoAnterior				= CAST('0' AS INT)
	,	QtdeApoliceTotalMesAtualAnoAnterior							= CAST('0' AS INT)
	---- Sintetico Cotacao
	,	VrPremioCotacaoRecusadaMesAtualAnoAnterior					= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoLiquidaMesAtualAnoAnterior					= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoTotalMesAtualAnoAnterior						= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeCotacaoRecusadaMesAtualAnoAnterior						= CAST('0' AS INT)
	,	QtdeCotacaoLiquidaMesAtualAnoAnterior						= CAST('0' AS INT)
	,	QtdeCotacaoTotalMesAtualAnoAnterior							= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoRecusadaMesAtualAnoAnterior				= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoLiquidaMesAtualAnoAnterior				= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoTotalMesAtualAnoAnterior					= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoRecusadaMesAtualAnoAnterior	= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoLiquidaMesAtualAnoAnterior	= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoTotalMesAtualAnoAnterior		= CAST('0' AS INT)
	,	QtdePropostaEmitidaMesAtualAnoAnterior						= CAST('0' AS INT)
	,	QtdePropostaPendenteMesAtualAnoAnterior						= CAST('0' AS INT)
	,	QtdePropostaTotalMesAtualAnoAnterior						= CAST('0' AS INT)
	,	QtdeCotacaoApoliceTotalMesAtualAnoAnterior					= CAST('0' AS INT)
	-- =======================================================================================
	-- Mes Anterior (MesAnterior)
	---- Sintetico Premio
	,	VrPremioLiquidoApoliceNovaProducaoMesAnterior				= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoNovaProducaoMesAnterior				= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoApoliceRenovacaoMesAnterior					= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoRenovacaoMesAnterior					= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoTotalMesAnterior								= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeApoliceApoliceNovaProducaoMesAnterior					= CAST('0' AS INT)
	,	QtdeApoliceEndossoNovaProducaoMesAnterior					= CAST('0' AS INT)
	,	QtdeApoliceApoliceRenovacaoMesAnterior						= CAST('0' AS INT)
	,	QtdeApoliceEndossoRenovacaoMesAnterior						= CAST('0' AS INT)
	,	QtdeApoliceTotalMesAnterior									= CAST('0' AS INT)
	---- Sintetico Cotacao
	,	VrPremioCotacaoRecusadaMesAnterior							= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoLiquidaMesAnterior							= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoTotalMesAnterior								= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeCotacaoRecusadaMesAnterior								= CAST('0' AS INT)
	,	QtdeCotacaoLiquidaMesAnterior								= CAST('0' AS INT)
	,	QtdeCotacaoTotalMesAnterior									= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoRecusadaMesAnterior						= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoLiquidaMesAnterior						= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoTotalMesAnterior							= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoRecusadaMesAnterior			= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoLiquidaMesAnterior			= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoTotalMesAnterior				= CAST('0' AS INT)
	,	QtdePropostaEmitidaMesAnterior								= CAST('0' AS INT)
	,	QtdePropostaPendenteMesAnterior								= CAST('0' AS INT)
	,	QtdePropostaTotalMesAnterior								= CAST('0' AS INT)
	,	QtdeCotacaoApoliceTotalMesAnterior							= CAST('0' AS INT)
	-- =======================================================================================
	-- Mes Anterior Ano Anterior (MesAnteriorAnoAnterior)
	---- Sintetico Premio
	,	VrPremioLiquidoApoliceNovaProducaoMesAnteriorAnoAnterior		= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoNovaProducaoMesAnteriorAnoAnterior		= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoApoliceRenovacaoMesAnteriorAnoAnterior			= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoRenovacaoMesAnteriorAnoAnterior			= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoTotalMesAnteriorAnoAnterior						= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeApoliceApoliceNovaProducaoMesAnteriorAnoAnterior			= CAST('0' AS INT)
	,	QtdeApoliceEndossoNovaProducaoMesAnteriorAnoAnterior			= CAST('0' AS INT)
	,	QtdeApoliceApoliceRenovacaoMesAnteriorAnoAnterior				= CAST('0' AS INT)
	,	QtdeApoliceEndossoRenovacaoMesAnteriorAnoAnterior				= CAST('0' AS INT)
	,	QtdeApoliceTotalMesAnteriorAnoAnterior							= CAST('0' AS INT)
	---- Sintetico Cotacao
	,	VrPremioCotacaoRecusadaMesAnteriorAnoAnterior					= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoLiquidaMesAnteriorAnoAnterior					= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoTotalMesAnteriorAnoAnterior						= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeCotacaoRecusadaMesAnteriorAnoAnterior						= CAST('0' AS INT)
	,	QtdeCotacaoLiquidaMesAnteriorAnoAnterior						= CAST('0' AS INT)
	,	QtdeCotacaoTotalMesAnteriorAnoAnterior							= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoRecusadaMesAnteriorAnoAnterior				= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoLiquidaMesAnteriorAnoAnterior					= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoTotalMesAnteriorAnoAnterior					= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoRecusadaMesAnteriorAnoAnterior	= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoLiquidaMesAnteriorAnoAnterior		= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoTotalMesAnteriorAnoAnterior		= CAST('0' AS INT)
	,	QtdePropostaEmitidaMesAnteriorAnoAnterior						= CAST('0' AS INT)
	,	QtdePropostaPendenteMesAnteriorAnoAnterior						= CAST('0' AS INT)
	,	QtdePropostaTotalMesAnteriorAnoAnterior							= CAST('0' AS INT)
	,	QtdeCotacaoApoliceTotalMesAnteriorAnoAnterior					= CAST('0' AS INT)
	-- =======================================================================================
	-- Ano Acumulado (De Jan at� M-1) (AnoAcumulado)
	---- Sintetico Premio
	,	VrPremioLiquidoApoliceNovaProducaoAnoAcumulado					= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoNovaProducaoAnoAcumulado					= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoApoliceRenovacaoAnoAcumulado						= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoRenovacaoAnoAcumulado						= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoTotalAnoAcumulado								= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeApoliceApoliceNovaProducaoAnoAcumulado						= CAST('0' AS INT)
	,	QtdeApoliceEndossoNovaProducaoAnoAcumulado						= CAST('0' AS INT)
	,	QtdeApoliceApoliceRenovacaoAnoAcumulado							= CAST('0' AS INT)
	,	QtdeApoliceEndossoRenovacaoAnoAcumulado							= CAST('0' AS INT)
	,	QtdeApoliceTotalAnoAcumulado									= CAST('0' AS INT)
	---- Sintetico Cotacao
	,	VrPremioCotacaoRecusadaAnoAcumulado								= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoLiquidaAnoAcumulado								= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoTotalAnoAcumulado								= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeCotacaoRecusadaAnoAcumulado									= CAST('0' AS INT)
	,	QtdeCotacaoLiquidaAnoAcumulado									= CAST('0' AS INT)
	,	QtdeCotacaoTotalAnoAcumulado									= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoRecusadaAnoAcumulado							= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoLiquidaAnoAcumulado							= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoTotalAnoAcumulado								= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoRecusadaAnoAcumulado				= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoLiquidaAnoAcumulado				= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoTotalAnoAcumulado					= CAST('0' AS INT)
	,	QtdePropostaEmitidaAnoAcumulado									= CAST('0' AS INT)
	,	QtdePropostaPendenteAnoAcumulado								= CAST('0' AS INT)
	,	QtdePropostaTotalAnoAcumulado									= CAST('0' AS INT)
	,	QtdeCotacaoApoliceTotalAnoAcumulado								= CAST('0' AS INT)
	-- =======================================================================================
	-- Ano Anterior Acumulado (De Jan at� M-1) (AnoAnteriorAcumulado)
	---- Sintetico Premio
	,	VrPremioLiquidoApoliceNovaProducaoAnoAnteriorAcumulado			= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoNovaProducaoAnoAnteriorAcumulado			= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoApoliceRenovacaoAnoAnteriorAcumulado				= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoRenovacaoAnoAnteriorAcumulado				= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoTotalAnoAnteriorAcumulado						= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeApoliceApoliceNovaProducaoAnoAnteriorAcumulado				= CAST('0' AS INT)
	,	QtdeApoliceEndossoNovaProducaoAnoAnteriorAcumulado				= CAST('0' AS INT)
	,	QtdeApoliceApoliceRenovacaoAnoAnteriorAcumulado					= CAST('0' AS INT)
	,	QtdeApoliceEndossoRenovacaoAnoAnteriorAcumulado					= CAST('0' AS INT)
	,	QtdeApoliceTotalAnoAnteriorAcumulado							= CAST('0' AS INT)
	---- Sintetico Cotacao
	,	VrPremioCotacaoRecusadaAnoAnteriorAcumulado						= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoLiquidaAnoAnteriorAcumulado						= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoTotalAnoAnteriorAcumulado						= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeCotacaoRecusadaAnoAnteriorAcumulado							= CAST('0' AS INT)
	,	QtdeCotacaoLiquidaAnoAnteriorAcumulado							= CAST('0' AS INT)
	,	QtdeCotacaoTotalAnoAnteriorAcumulado							= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoRecusadaAnoAnteriorAcumulado					= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoLiquidaAnoAnteriorAcumulado					= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoTotalAnoAnteriorAcumulado						= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoRecusadaAnoAnteriorAcumulado		= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoLiquidaAnoAnteriorAcumulado		= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoTotalAnoAnteriorAcumulado			= CAST('0' AS INT)
	,	QtdePropostaEmitidaAnoAnteriorAcumulado							= CAST('0' AS INT)
	,	QtdePropostaPendenteAnoAnteriorAcumulado						= CAST('0' AS INT)
	,	QtdePropostaTotalAnoAnteriorAcumulado							= CAST('0' AS INT)
	,	QtdeCotacaoApoliceTotalAnoAnteriorAcumulado						= CAST('0' AS INT)
	-- =======================================================================================
	-- Valor do Orcado Mes Atual
	,	VrOrcado														= CAST('0.00' AS NUMERIC(18,2))
	,	VrOrcadoAnoAcumulado											= CAST('0.00' AS NUMERIC(18,2))
	-- =======================================================================================
	-- Mes Atual: 
	---- Sintetico Renovacao
	,	QtdePolizaEsp													= CAST('0' AS INT)	-- Conceito: QTD Renova��es Esperadas
	,	QtdeOfertada													= CAST('0' AS INT)	-- Conceito: QTD Renova��es Ofertadas
	,	QtdePolizaRen													= CAST('0' AS INT)	-- Conceito: QTD Renova��es Efetivadas
	,	QtdePolizaEspParcial											= CAST('0' AS INT)	-- Conceito: QTD Renova��es Esperadas
	,	QtdeOfertadaParcial												= CAST('0' AS INT)	-- Conceito: QTD Renova��es Ofertadas
	,	QtdePolizaRenParcial											= CAST('0' AS INT)	-- Conceito: QTD Renova��es Efetivadas
	-- =======================================================================================
	-- Mes Anterior (MesAnterior)
	,	QtdePolizaEspMesAnterior										= CAST('0' AS INT)	-- Conceito: QTD Renova��es Esperadas
	,	QtdeOfertadaMesAnterior											= CAST('0' AS INT)	-- Conceito: QTD Renova��es Ofertadas
	,	QtdePolizaRenMesAnterior										= CAST('0' AS INT)	-- Conceito: QTD Renova��es Efetivadas
	-- =======================================================================================
	-- Mes Atual: 
	---- Sintetico Renovacao
	,	ImpPrimaCarteraEsp												= CAST('0.00' AS NUMERIC(18,2)) -- Premio Renovacao Esperada
	,	ImpPrimaRenGarantizadaEsp										= CAST('0.00' AS NUMERIC(18,2)) -- Premio Renovacao Ofertada
	,	ImpPrimaCarteraRen												= CAST('0.00' AS NUMERIC(18,2)) -- Premio Renovacao Efetivada

	INTO #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO
	FROM #tmp_rds_base_corretor T1
	LEFT JOIN dbo.HierarquiaComercialUnificada T2 WITH (NOLOCK) 
		ON T1.CodCorretor = T2.CodCorretor
	LEFT JOIN dbo.CanalUnificado T3 WITH (NOLOCK) 
		ON T3.COD_CONVENIO = T2.CodConvenio

	UNION ALL

	SELECT
		DtReferencia												= @FirstDayOfMonth
	,	DtProcessamento												= @CurrentDate
	,	CodCorretor													= T1.CodCorretor
	,	NomeCorretor												= T1.NomeCorretor
	,	RaizCpfCnpjCorretor											= T1.RaizCpfCnpjCorretor
	,	CodAssessor													= T1.CodAssessor
	,	NomeAssessor												= T1.NomeAssessor
	,	CodSucursal													= T1.CodSucursal
	,	NomeSucursal												= T1.NomeSucursal
	,	CodTerritorial												= T1.CodTerritorial
	,	NomeTerritorial												= T1.NomeTerritorial
	,	CodCanal1													= T1.CodCanal1 
	,	DescricaoCanal1												= T1.DescricaoCanal1 
	,	CodCanal2													= T1.CodCanal2 
	,	DescricaoCanal2												= T1.DescricaoCanal2 
	,	CodCanal3													= T1.CodCanal3 
	,	DescricaoCanal3												= T1.DescricaoCanal3 
	,	CodCanal4													= T1.CodCanal4 
	,	DescricaoCanal4												= T1.DescricaoCanal4 
	,	TipoAtendimentoId											= T1.TipoAtendimentoId
	,	NomeAtendimento												= T1.NomeAtendimento
	,	NomeRamo													= T1.NomeRamo
	,	NomeSetor													= T1.NomeSetor
	-- =======================================================================================
	-- Mes Atual: 
	---- Sintetico Premio
	,	VrPremioLiquidoApoliceNovaProducao							= CAST(T1.VrPremioLiquidoApoliceNovaProducao AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoNovaProducao							= CAST(T1.VrPremioLiquidoEndossoNovaProducao AS NUMERIC(18,2))
	,	VrPremioLiquidoApoliceRenovacao								= CAST(T1.VrPremioLiquidoApoliceRenovacao AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoRenovacao								= CAST(T1.VrPremioLiquidoEndossoRenovacao AS NUMERIC(18,2))
	,	VrPremioLiquidoTotal										= CAST(T1.VrPremioLiquidoTotal AS NUMERIC(18,2))
	,	QtdeApoliceApoliceNovaProducao								= CAST(T1.QtdeApoliceApoliceNovaProducao AS INT)
	,	QtdeApoliceEndossoNovaProducao								= CAST(T1.QtdeApoliceEndossoNovaProducao AS INT)
	,	QtdeApoliceApoliceRenovacao									= CAST(T1.QtdeApoliceApoliceRenovacao AS INT)
	,	QtdeApoliceEndossoRenovacao									= CAST(T1.QtdeApoliceEndossoRenovacao AS INT)
	,	QtdeApoliceTotal											= CAST(T1.QtdeApoliceTotal AS INT)
	,	VrProjecaoIndividualPrimeiraSemana							= CAST(T1.VrProjecaoIndividualPrimeiraSemana AS NUMERIC(18,2))
	,	VrProjecaoIndividualSemSegunda								= CAST(T1.VrProjecaoIndividualSemSegunda AS NUMERIC(18,2))
	,	VrProjecaoIndividualComSegunda								= CAST(T1.VrProjecaoIndividualComSegunda AS NUMERIC(18,2))
	,	VrProjecaoIndividual										= CAST(T1.VrProjecaoIndividual AS NUMERIC(18,2))
	,	VrProjecaoCaminhao											= CAST(T1.VrProjecaoCaminhao AS NUMERIC(18,2))
	,	VrProjecaoFrota												= CAST(T1.VrProjecaoFrota AS NUMERIC(18,2))
	,	VrProjecaoLiquidoTotal										= CAST(T1.VrProjecaoLiquidoTotal AS NUMERIC(18,2))
	---- Sintetico Cotacao
	,	VrPremioCotacaoRecusada										= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoLiquida										= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoTotal										= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeCotacaoRecusada											= CAST('0' AS INT)
	,	QtdeCotacaoLiquida											= CAST('0' AS INT)
	,	QtdeCotacaoTotal											= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoRecusada									= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoLiquida									= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoTotal										= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoRecusada						= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoLiquida						= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoTotal							= CAST('0' AS INT)
	,	QtdePropostaEmitida											= CAST('0' AS INT)
	,	QtdePropostaPendente										= CAST('0' AS INT)
	,	QtdePropostaTotal											= CAST('0' AS INT)
	,	QtdeCotacaoApoliceTotal										= CAST('0' AS INT)
	-- =======================================================================================
	-- Mes Atual Ano Anterior (MesAtualAnoAnterior)
	---- Sintetico Premio
	,	VrPremioLiquidoApoliceNovaProducaoMesAtualAnoAnterior		= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoNovaProducaoMesAtualAnoAnterior		= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoApoliceRenovacaoMesAtualAnoAnterior			= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoRenovacaoMesAtualAnoAnterior			= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoTotalMesAtualAnoAnterior						= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeApoliceApoliceNovaProducaoMesAtualAnoAnterior			= CAST('0' AS INT)
	,	QtdeApoliceEndossoNovaProducaoMesAtualAnoAnterior			= CAST('0' AS INT)
	,	QtdeApoliceApoliceRenovacaoMesAtualAnoAnterior				= CAST('0' AS INT)
	,	QtdeApoliceEndossoRenovacaoMesAtualAnoAnterior				= CAST('0' AS INT)
	,	QtdeApoliceTotalMesAtualAnoAnterior							= CAST('0' AS INT)
	---- Sintetico Cotacao
	,	VrPremioCotacaoRecusadaMesAtualAnoAnterior					= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoLiquidaMesAtualAnoAnterior					= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoTotalMesAtualAnoAnterior						= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeCotacaoRecusadaMesAtualAnoAnterior						= CAST('0' AS INT)
	,	QtdeCotacaoLiquidaMesAtualAnoAnterior						= CAST('0' AS INT)
	,	QtdeCotacaoTotalMesAtualAnoAnterior							= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoRecusadaMesAtualAnoAnterior				= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoLiquidaMesAtualAnoAnterior				= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoTotalMesAtualAnoAnterior					= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoRecusadaMesAtualAnoAnterior	= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoLiquidaMesAtualAnoAnterior	= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoTotalMesAtualAnoAnterior		= CAST('0' AS INT)
	,	QtdePropostaEmitidaMesAtualAnoAnterior						= CAST('0' AS INT)
	,	QtdePropostaPendenteMesAtualAnoAnterior						= CAST('0' AS INT)
	,	QtdePropostaTotalMesAtualAnoAnterior						= CAST('0' AS INT)
	,	QtdeCotacaoApoliceTotalMesAtualAnoAnterior					= CAST('0' AS INT)
	-- =======================================================================================
	-- Mes Anterior (MesAnterior)
	---- Sintetico Premio
	,	VrPremioLiquidoApoliceNovaProducaoMesAnterior				= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoNovaProducaoMesAnterior				= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoApoliceRenovacaoMesAnterior					= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoRenovacaoMesAnterior					= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoTotalMesAnterior								= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeApoliceApoliceNovaProducaoMesAnterior					= CAST('0' AS INT)
	,	QtdeApoliceEndossoNovaProducaoMesAnterior					= CAST('0' AS INT)
	,	QtdeApoliceApoliceRenovacaoMesAnterior						= CAST('0' AS INT)
	,	QtdeApoliceEndossoRenovacaoMesAnterior						= CAST('0' AS INT)
	,	QtdeApoliceTotalMesAnterior									= CAST('0' AS INT)
	---- Sintetico Cotacao
	,	VrPremioCotacaoRecusadaMesAnterior							= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoLiquidaMesAnterior							= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoTotalMesAnterior								= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeCotacaoRecusadaMesAnterior								= CAST('0' AS INT)
	,	QtdeCotacaoLiquidaMesAnterior								= CAST('0' AS INT)
	,	QtdeCotacaoTotalMesAnterior									= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoRecusadaMesAnterior						= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoLiquidaMesAnterior						= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoTotalMesAnterior							= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoRecusadaMesAnterior			= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoLiquidaMesAnterior			= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoTotalMesAnterior				= CAST('0' AS INT)
	,	QtdePropostaEmitidaMesAnterior								= CAST('0' AS INT)
	,	QtdePropostaPendenteMesAnterior								= CAST('0' AS INT)
	,	QtdePropostaTotalMesAnterior								= CAST('0' AS INT)
	,	QtdeCotacaoApoliceTotalMesAnterior							= CAST('0' AS INT)
	-- =======================================================================================
	-- Mes Anterior Ano Anterior (MesAnteriorAnoAnterior)
	---- Sintetico Premio
	,	VrPremioLiquidoApoliceNovaProducaoMesAnteriorAnoAnterior		= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoNovaProducaoMesAnteriorAnoAnterior		= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoApoliceRenovacaoMesAnteriorAnoAnterior			= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoRenovacaoMesAnteriorAnoAnterior			= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoTotalMesAnteriorAnoAnterior						= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeApoliceApoliceNovaProducaoMesAnteriorAnoAnterior			= CAST('0' AS INT)
	,	QtdeApoliceEndossoNovaProducaoMesAnteriorAnoAnterior			= CAST('0' AS INT)
	,	QtdeApoliceApoliceRenovacaoMesAnteriorAnoAnterior				= CAST('0' AS INT)
	,	QtdeApoliceEndossoRenovacaoMesAnteriorAnoAnterior				= CAST('0' AS INT)
	,	QtdeApoliceTotalMesAnteriorAnoAnterior							= CAST('0' AS INT)
	---- Sintetico Cotacao
	,	VrPremioCotacaoRecusadaMesAnteriorAnoAnterior					= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoLiquidaMesAnteriorAnoAnterior					= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoTotalMesAnteriorAnoAnterior						= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeCotacaoRecusadaMesAnteriorAnoAnterior						= CAST('0' AS INT)
	,	QtdeCotacaoLiquidaMesAnteriorAnoAnterior						= CAST('0' AS INT)
	,	QtdeCotacaoTotalMesAnteriorAnoAnterior							= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoRecusadaMesAnteriorAnoAnterior				= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoLiquidaMesAnteriorAnoAnterior					= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoTotalMesAnteriorAnoAnterior					= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoRecusadaMesAnteriorAnoAnterior	= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoLiquidaMesAnteriorAnoAnterior		= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoTotalMesAnteriorAnoAnterior		= CAST('0' AS INT)
	,	QtdePropostaEmitidaMesAnteriorAnoAnterior						= CAST('0' AS INT)
	,	QtdePropostaPendenteMesAnteriorAnoAnterior						= CAST('0' AS INT)
	,	QtdePropostaTotalMesAnteriorAnoAnterior							= CAST('0' AS INT)
	,	QtdeCotacaoApoliceTotalMesAnteriorAnoAnterior					= CAST('0' AS INT)
	-- =======================================================================================
	-- Ano Acumulado (De Jan at� M-1) (AnoAcumulado)
	---- Sintetico Premio
	,	VrPremioLiquidoApoliceNovaProducaoAnoAcumulado					= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoNovaProducaoAnoAcumulado					= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoApoliceRenovacaoAnoAcumulado						= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoRenovacaoAnoAcumulado						= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoTotalAnoAcumulado								= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeApoliceApoliceNovaProducaoAnoAcumulado						= CAST('0' AS INT)
	,	QtdeApoliceEndossoNovaProducaoAnoAcumulado						= CAST('0' AS INT)
	,	QtdeApoliceApoliceRenovacaoAnoAcumulado							= CAST('0' AS INT)
	,	QtdeApoliceEndossoRenovacaoAnoAcumulado							= CAST('0' AS INT)
	,	QtdeApoliceTotalAnoAcumulado									= CAST('0' AS INT)
	---- Sintetico Cotacao
	,	VrPremioCotacaoRecusadaAnoAcumulado								= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoLiquidaAnoAcumulado								= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoTotalAnoAcumulado								= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeCotacaoRecusadaAnoAcumulado									= CAST('0' AS INT)
	,	QtdeCotacaoLiquidaAnoAcumulado									= CAST('0' AS INT)
	,	QtdeCotacaoTotalAnoAcumulado									= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoRecusadaAnoAcumulado							= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoLiquidaAnoAcumulado							= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoTotalAnoAcumulado								= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoRecusadaAnoAcumulado				= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoLiquidaAnoAcumulado				= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoTotalAnoAcumulado					= CAST('0' AS INT)
	,	QtdePropostaEmitidaAnoAcumulado									= CAST('0' AS INT)
	,	QtdePropostaPendenteAnoAcumulado								= CAST('0' AS INT)
	,	QtdePropostaTotalAnoAcumulado									= CAST('0' AS INT)
	,	QtdeCotacaoApoliceTotalAnoAcumulado								= CAST('0' AS INT)
	-- =======================================================================================
	-- Ano Anterior Acumulado (De Jan at� M-1) (AnoAnteriorAcumulado)
	---- Sintetico Premio
	,	VrPremioLiquidoApoliceNovaProducaoAnoAnteriorAcumulado			= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoNovaProducaoAnoAnteriorAcumulado			= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoApoliceRenovacaoAnoAnteriorAcumulado				= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoRenovacaoAnoAnteriorAcumulado				= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioLiquidoTotalAnoAnteriorAcumulado						= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeApoliceApoliceNovaProducaoAnoAnteriorAcumulado				= CAST('0' AS INT)
	,	QtdeApoliceEndossoNovaProducaoAnoAnteriorAcumulado				= CAST('0' AS INT)
	,	QtdeApoliceApoliceRenovacaoAnoAnteriorAcumulado					= CAST('0' AS INT)
	,	QtdeApoliceEndossoRenovacaoAnoAnteriorAcumulado					= CAST('0' AS INT)
	,	QtdeApoliceTotalAnoAnteriorAcumulado							= CAST('0' AS INT)
	---- Sintetico Cotacao
	,	VrPremioCotacaoRecusadaAnoAnteriorAcumulado						= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoLiquidaAnoAnteriorAcumulado						= CAST('0.00' AS NUMERIC(18,2))
	,	VrPremioCotacaoTotalAnoAnteriorAcumulado						= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeCotacaoRecusadaAnoAnteriorAcumulado							= CAST('0' AS INT)
	,	QtdeCotacaoLiquidaAnoAnteriorAcumulado							= CAST('0' AS INT)
	,	QtdeCotacaoTotalAnoAnteriorAcumulado							= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoRecusadaAnoAnteriorAcumulado					= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoLiquidaAnoAnteriorAcumulado					= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoTotalAnoAnteriorAcumulado						= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoRecusadaAnoAnteriorAcumulado		= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoLiquidaAnoAnteriorAcumulado		= CAST('0' AS INT)
	,	QtdeCotacaoEsforcoMulticalculoTotalAnoAnteriorAcumulado			= CAST('0' AS INT)
	,	QtdePropostaEmitidaAnoAnteriorAcumulado							= CAST('0' AS INT)
	,	QtdePropostaPendenteAnoAnteriorAcumulado						= CAST('0' AS INT)
	,	QtdePropostaTotalAnoAnteriorAcumulado							= CAST('0' AS INT)
	,	QtdeCotacaoApoliceTotalAnoAnteriorAcumulado						= CAST('0' AS INT)
	-- =======================================================================================
	-- Valor do Orcado Mes Atual
	,	VrOrcado														= CAST('0.00' AS NUMERIC(18,2))
	,	VrOrcadoAnoAcumulado											= CAST('0.00' AS NUMERIC(18,2))
	-- =======================================================================================
	-- Mes Atual: 
	---- Sintetico Renovacao
	,	QtdePolizaEsp													= CAST('0' AS INT)	-- Conceito: QTD Renova��es Esperadas
	,	QtdeOfertada													= CAST('0' AS INT)	-- Conceito: QTD Renova��es Ofertadas
	,	QtdePolizaRen													= CAST('0' AS INT)	-- Conceito: QTD Renova��es Efetivadas
	,	QtdePolizaEspParcial											= CAST('0' AS INT)	-- Conceito: QTD Renova��es Esperadas
	,	QtdeOfertadaParcial												= CAST('0' AS INT)	-- Conceito: QTD Renova��es Ofertadas
	,	QtdePolizaRenParcial											= CAST('0' AS INT)	-- Conceito: QTD Renova��es Efetivadas
	-- =======================================================================================
	-- Mes Anterior (MesAnterior)
	,	QtdePolizaEspMesAnterior										= CAST('0' AS INT)	-- Conceito: QTD Renova��es Esperadas
	,	QtdeOfertadaMesAnterior											= CAST('0' AS INT)	-- Conceito: QTD Renova��es Ofertadas
	,	QtdePolizaRenMesAnterior										= CAST('0' AS INT)	-- Conceito: QTD Renova��es Efetivadas
	-- =======================================================================================
	-- Mes Atual: 
	---- Sintetico Renovacao
	,	ImpPrimaCarteraEsp												= CAST('0.00' AS NUMERIC(18,2)) -- Premio Renovacao Esperada
	,	ImpPrimaRenGarantizadaEsp										= CAST('0.00' AS NUMERIC(18,2)) -- Premio Renovacao Ofertada
	,	ImpPrimaCarteraRen												= CAST('0.00' AS NUMERIC(18,2)) -- Premio Renovacao Efetivada

	from IndicadorProdutoAutoSinteticoPremio T1 WITH (NOLOCK)
	WHERE T1.DtReferencia = @FirstDayOfMonth

	-- ====================================================================================================================================
	--
	--													REMARCACAO HIERARQUIA COMERCIAL
	--
	-- ====================================================================================================================================

	-- ====================================================================================================================================
	-- Remarcacao da base de hierarquia comercial
	
	drop table if exists #tmp_rds_remarcacao_hierarquia

	select *
	into #tmp_rds_remarcacao_hierarquia
	from
	(

		select SEQ = ROW_NUMBER() OVER(PARTITION BY codcorretor ORDER BY DtReferencia desc), *
		from HierarquiaComercialUnificadaMensalizada
		where DtReferencia between @FirstDayOfYear and @FirstDayOfMonth

	) t1
	where t1.SEQ = 1

	-- ====================================================================================================================================
	-- Atualizacao

	update t1
	set 
		t1.NomeCorretor				= T2.NomeCorretor
	,	t1.RaizCpfCnpjCorretor		= T2.RaizCpfCnpjCorretor
	,	t1.CodAssessor				= T2.CodAssessor
	,	t1.NomeAssessor				= T2.NomeAssessor
	,	t1.CodSucursal				= T2.CodSucursal
	,	t1.NomeSucursal				= T2.NomeSucursal
	,	t1.CodTerritorial			= T2.CodTerritorial
	,	t1.NomeTerritorial			= T2.NomeTerritorial
	,	t1.CodCanal1				= T3.COD_CONSOLIDADO_CANAL 
	,	t1.DescricaoCanal1			= T3.DESCR_CONSOLIDADO_CANAL 
	,	t1.CodCanal2				= T3.COD_GRUPO_CANAL 
	,	t1.DescricaoCanal2			= T3.DESC_GRUPO_CANAL 
	,	t1.CodCanal3				= T3.COD_GERENTE_CANAL 
	,	t1.DescricaoCanal3			= T3.DESC_GERENTE_CANAL 
	,	t1.CodCanal4				= T3.COD_CONVENIO 
	,	t1.DescricaoCanal4			= T3.DESC_CONVENIO 

	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO t1
	left join #tmp_rds_remarcacao_hierarquia t2 WITH (NOLOCK) 
		on t1.CodCorretor = t2.CodCorretor
	LEFT JOIN dbo.CanalUnificado T3 WITH (NOLOCK) 
		ON T3.COD_CONVENIO = T2.CodConvenio
	where t1.CodTerritorial is null

	-- ====================================================================================================================================
	-- Remarcacao da base de hierarquia comercial final

	drop table if exists #tmp_rds_remarcacao_hierarquia_final

	select *
	into #tmp_rds_remarcacao_hierarquia_final
	from
	(

		select SEQ = ROW_NUMBER() OVER(PARTITION BY codcorretor ORDER BY DtReferencia desc), *
		from HierarquiaComercialUnificadaMensalizada

	) t1
	where t1.SEQ = 1


	update t1
	set 
		t1.NomeCorretor				= T2.NomeCorretor
	,	t1.RaizCpfCnpjCorretor		= T2.RaizCpfCnpjCorretor
	,	t1.CodAssessor				= T2.CodAssessor
	,	t1.NomeAssessor				= T2.NomeAssessor
	,	t1.CodSucursal				= T2.CodSucursal
	,	t1.NomeSucursal				= T2.NomeSucursal
	,	t1.CodTerritorial			= T2.CodTerritorial
	,	t1.NomeTerritorial			= T2.NomeTerritorial
	,	t1.CodCanal1				= T3.COD_CONSOLIDADO_CANAL 
	,	t1.DescricaoCanal1			= T3.DESCR_CONSOLIDADO_CANAL 
	,	t1.CodCanal2				= T3.COD_GRUPO_CANAL 
	,	t1.DescricaoCanal2			= T3.DESC_GRUPO_CANAL 
	,	t1.CodCanal3				= T3.COD_GERENTE_CANAL 
	,	t1.DescricaoCanal3			= T3.DESC_GERENTE_CANAL 
	,	t1.CodCanal4				= T3.COD_CONVENIO 
	,	t1.DescricaoCanal4			= T3.DESC_CONVENIO 

	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO t1
	left join #tmp_rds_remarcacao_hierarquia_final t2 WITH (NOLOCK) 
		on t1.CodCorretor = t2.CodCorretor
	LEFT JOIN dbo.CanalUnificado T3 WITH (NOLOCK) 
		ON T3.COD_CONVENIO = T2.CodConvenio
	where t1.CodTerritorial is null

	-- ====================================================================================================================================
	--
	--												ATUALIZANDO O TIPO DE ATENDIMENTO
	--
	-- ====================================================================================================================================

	-- ====================================================================================================================================
	-- Atualizando o codigo de atendimento

	update t1
	set t1.TipoAtendimentoId = t2.TipoAtendimentoId
	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO t1
	inner join #TMP_RDS_TIPO_ATENDIMENTO t2 WITH (NOLOCK) 
		on t1.CodAssessor = t2.CodAssessor
	where t1.TipoAtendimentoId is null

	-- ====================================================================================================================================
	-- Atualizando o nome do atendimento

	update t1
	set t1.NomeAtendimento = t2.Nome
	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO t1
	inner join TipoAtendimento t2 on t1.TipoAtendimentoId = t2.Id
	where t1.NomeAtendimento is null

	-- ====================================================================================================================================
	--
	--																MES ATUAL 
	--
	-- ====================================================================================================================================

	-- ====================================================================================================================================
	-- Sintetico Cotacao - Mes Atual

	DROP TABLE IF EXISTS #TMP_RDS_IndicadorProdutoAutoSinteticoCotacaoMesAtual

	SELECT
		DtReferencia												= T1.DtReferencia
	,	CodCorretor													= T1.CodCorretor
	,	NomeRamo													= T1.NomeRamo
	,	NomeSetor													= T1.NomeSetor
	,	VrPremioCotacaoRecusada										= SUM(CAST(T1.VrPremioCotacaoRecusada AS NUMERIC(18,2)))
	,	VrPremioCotacaoLiquida										= SUM(CAST(T1.VrPremioCotacaoLiquida AS NUMERIC(18,2)))
	,	VrPremioCotacaoTotal										= SUM(CAST(T1.VrPremioLiquidoTotal AS NUMERIC(18,2)))
	,	QtdeCotacaoRecusada											= SUM(CAST(T1.QtdeCotacaoRecusada AS INT))
	,	QtdeCotacaoLiquida											= SUM(CAST(T1.QtdeCotacaoLiquida AS INT))
	,	QtdeCotacaoTotal											= SUM(CAST(T1.QtdeCotacaoTotal AS INT))
	,	QtdeCotacaoEsforcoRecusada									= SUM(CAST(T1.QtdeCotacaoEsforcoRecusada AS INT))
	,	QtdeCotacaoEsforcoLiquida									= SUM(CAST(T1.QtdeCotacaoEsforcoLiquida AS INT))
	,	QtdeCotacaoEsforcoTotal										= SUM(CAST(T1.QtdeCotacaoEsforcoTotal AS INT))
	,	QtdeCotacaoEsforcoMulticalculoRecusada						= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoRecusada AS INT))
	,	QtdeCotacaoEsforcoMulticalculoLiquida						= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoLiquida AS INT))
	,	QtdeCotacaoEsforcoMulticalculoTotal							= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoTotal AS INT))
	,	QtdePropostaEmitida											= SUM(CAST(T1.QtdePropostaEmitida AS INT))
	,	QtdePropostaPendente										= SUM(CAST(T1.QtdePropostaPendente AS INT))
	,	QtdePropostaTotal											= SUM(CAST(T1.QtdePropostaTotal AS INT))
	,	QtdeCotacaoApoliceTotal										= SUM(CAST(T1.QtdeApoliceTotal AS INT))

	INTO #TMP_RDS_IndicadorProdutoAutoSinteticoCotacaoMesAtual
	FROM IndicadorProdutoAutoSinteticoCotacao T1
	WHERE T1.DtReferencia = @FirstDayOfMonth 
	GROUP BY
		T1.DtReferencia
	,	T1.CodCorretor
	,	T1.NomeRamo
	,	T1.NomeSetor

	-- ====================================================================================================================================
	-- Sintetico Cotacao - Mes Atual: Update

	update t1
	set	t1.VrPremioCotacaoRecusada					= t2.VrPremioCotacaoRecusada
	,	t1.VrPremioCotacaoLiquida					= t2.VrPremioCotacaoLiquida
	,	t1.VrPremioCotacaoTotal						= t2.VrPremioCotacaoTotal
	,	t1.QtdeCotacaoRecusada						= t2.QtdeCotacaoRecusada
	,	t1.QtdeCotacaoLiquida						= t2.QtdeCotacaoLiquida
	,	t1.QtdeCotacaoTotal							= t2.QtdeCotacaoTotal
	,	t1.QtdeCotacaoEsforcoRecusada				= t2.QtdeCotacaoEsforcoRecusada
	,	t1.QtdeCotacaoEsforcoLiquida				= t2.QtdeCotacaoEsforcoLiquida
	,	t1.QtdeCotacaoEsforcoTotal					= t2.QtdeCotacaoEsforcoTotal
	,	t1.QtdeCotacaoEsforcoMulticalculoRecusada	= t2.QtdeCotacaoEsforcoMulticalculoRecusada
	,	t1.QtdeCotacaoEsforcoMulticalculoLiquida	= t2.QtdeCotacaoEsforcoMulticalculoLiquida
	,	t1.QtdeCotacaoEsforcoMulticalculoTotal		= t2.QtdeCotacaoEsforcoMulticalculoTotal
	,	t1.QtdePropostaEmitida						= t2.QtdePropostaEmitida
	,	t1.QtdePropostaPendente						= t2.QtdePropostaPendente
	,	t1.QtdePropostaTotal						= t2.QtdePropostaTotal
	,	t1.QtdeCotacaoApoliceTotal					= t2.QtdeCotacaoApoliceTotal

	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO t1
	inner join #TMP_RDS_IndicadorProdutoAutoSinteticoCotacaoMesAtual t2 WITH (NOLOCK) 
		on t1.CodCorretor = t2.CodCorretor
		and t1.NomeRamo = t2.NomeRamo
		and t1.NomeSetor = t2.NomeSetor
	WHERE T2.DtReferencia = @FirstDayOfMonth

	-- ====================================================================================================================================
	-- Sintetico Renovacao - Mes Atual: Update

	update t1
	set	
		QtdePolizaEsp				= CAST(t2.QtdePolizaEsp AS INT)	-- Conceito: QTD Renova��es Esperadas
	,	QtdeOfertada				= CAST(t2.QtdeOfertada AS INT)	-- Conceito: QTD Renova��es Ofertadas
	,	QtdePolizaRen				= CAST(t2.QtdePolizaRen AS INT)	-- Conceito: QTD Renova��es Efetivadas
	,	QtdePolizaEspParcial		= CAST(t2.QtdePolizaEspParcial AS INT)	-- Conceito: QTD Renova��es Esperadas
	,	QtdeOfertadaParcial			= CAST(t2.QtdeOfertadaParcial AS INT)	-- Conceito: QTD Renova��es Ofertadas
	,	QtdePolizaRenParcial		= CAST(t2.QtdePolizaRenParcial AS INT)	-- Conceito: QTD Renova��es Efetivadas
	,	ImpPrimaCarteraEsp			= CAST(T2.ImpPrimaCarteraEsp AS NUMERIC(18,2) )
	,	ImpPrimaRenGarantizadaEsp	= CAST(T2.ImpPrimaRenGarantizadaEsp AS NUMERIC(18,2) )
	,	ImpPrimaCarteraRen			= CAST(T2.ImpPrimaCarteraRen AS NUMERIC(18,2) )

	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO t1
	inner join IndicadorProdutoAutoSinteticoRenovacao t2 WITH (NOLOCK) 
		on t1.CodCorretor = t2.CodCorretor
		and t1.NomeRamo = t2.NomeRamo
		and t1.NomeSetor = t2.NomeSetor
	WHERE T2.DtReferencia = @FirstDayOfMonth

	-- ====================================================================================================================================
	--
	--														MES ATUAL ANO ANTERIOR
	--
	-- ====================================================================================================================================

	-- ====================================================================================================================================
	-- Sintetico Cotacao - Mes Atual Ano Anterior

	DROP TABLE IF EXISTS #TMP_RDS_IndicadorProdutoAutoSinteticoCotacaoMesAtualAnoAnterior

	SELECT
		DtReferencia												= T1.DtReferencia
	,	CodCorretor													= T1.CodCorretor
	,	NomeRamo													= T1.NomeRamo
	,	NomeSetor													= T1.NomeSetor
	,	VrPremioCotacaoRecusada										= SUM(CAST(T1.VrPremioCotacaoRecusada AS NUMERIC(18,2)))
	,	VrPremioCotacaoLiquida										= SUM(CAST(T1.VrPremioCotacaoLiquida AS NUMERIC(18,2)))
	,	VrPremioCotacaoTotal										= SUM(CAST(T1.VrPremioLiquidoTotal AS NUMERIC(18,2)))
	,	QtdeCotacaoRecusada											= SUM(CAST(T1.QtdeCotacaoRecusada AS INT))
	,	QtdeCotacaoLiquida											= SUM(CAST(T1.QtdeCotacaoLiquida AS INT))
	,	QtdeCotacaoTotal											= SUM(CAST(T1.QtdeCotacaoTotal AS INT))
	,	QtdeCotacaoEsforcoRecusada									= SUM(CAST(T1.QtdeCotacaoEsforcoRecusada AS INT))
	,	QtdeCotacaoEsforcoLiquida									= SUM(CAST(T1.QtdeCotacaoEsforcoLiquida AS INT))
	,	QtdeCotacaoEsforcoTotal										= SUM(CAST(T1.QtdeCotacaoEsforcoTotal AS INT))
	,	QtdeCotacaoEsforcoMulticalculoRecusada						= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoRecusada AS INT))
	,	QtdeCotacaoEsforcoMulticalculoLiquida						= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoLiquida AS INT))
	,	QtdeCotacaoEsforcoMulticalculoTotal							= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoTotal AS INT))
	,	QtdePropostaEmitida											= SUM(CAST(T1.QtdePropostaEmitida AS INT))
	,	QtdePropostaPendente										= SUM(CAST(T1.QtdePropostaPendente AS INT))
	,	QtdePropostaTotal											= SUM(CAST(T1.QtdePropostaTotal AS INT))
	,	QtdeCotacaoApoliceTotal										= SUM(CAST(T1.QtdeApoliceTotal AS INT))

	INTO #TMP_RDS_IndicadorProdutoAutoSinteticoCotacaoMesAtualAnoAnterior
	FROM IndicadorProdutoAutoSinteticoCotacao T1
	WHERE T1.DtReferencia = @FirstDayOfMonthLastYear 
	GROUP BY
		T1.DtReferencia
	,	T1.CodCorretor
	,	T1.NomeRamo
	,	T1.NomeSetor

	-- ====================================================================================================================================
	-- Sintetico Cotacao - Mes Atual Ano Anterior: Update

	update t1
	set	t1.VrPremioCotacaoRecusadaMesAtualAnoAnterior					= t2.VrPremioCotacaoRecusada
	,	t1.VrPremioCotacaoLiquidaMesAtualAnoAnterior					= t2.VrPremioCotacaoLiquida
	,	t1.VrPremioCotacaoTotalMesAtualAnoAnterior						= t2.VrPremioCotacaoTotal
	,	t1.QtdeCotacaoRecusadaMesAtualAnoAnterior						= t2.QtdeCotacaoRecusada
	,	t1.QtdeCotacaoLiquidaMesAtualAnoAnterior						= t2.QtdeCotacaoLiquida
	,	t1.QtdeCotacaoTotalMesAtualAnoAnterior							= t2.QtdeCotacaoTotal
	,	t1.QtdeCotacaoEsforcoRecusadaMesAtualAnoAnterior				= t2.QtdeCotacaoEsforcoRecusada
	,	t1.QtdeCotacaoEsforcoLiquidaMesAtualAnoAnterior					= t2.QtdeCotacaoEsforcoLiquida
	,	t1.QtdeCotacaoEsforcoTotalMesAtualAnoAnterior					= t2.QtdeCotacaoEsforcoTotal
	,	t1.QtdeCotacaoEsforcoMulticalculoRecusadaMesAtualAnoAnterior	= t2.QtdeCotacaoEsforcoMulticalculoRecusada
	,	t1.QtdeCotacaoEsforcoMulticalculoLiquidaMesAtualAnoAnterior		= t2.QtdeCotacaoEsforcoMulticalculoLiquida
	,	t1.QtdeCotacaoEsforcoMulticalculoTotalMesAtualAnoAnterior		= t2.QtdeCotacaoEsforcoMulticalculoTotal
	,	t1.QtdePropostaEmitidaMesAtualAnoAnterior						= t2.QtdePropostaEmitida
	,	t1.QtdePropostaPendenteMesAtualAnoAnterior						= t2.QtdePropostaPendente
	,	t1.QtdePropostaTotalMesAtualAnoAnterior							= t2.QtdePropostaTotal
	,	t1.QtdeCotacaoApoliceTotalMesAtualAnoAnterior					= t2.QtdeCotacaoApoliceTotal

	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO t1
	inner join #TMP_RDS_IndicadorProdutoAutoSinteticoCotacaoMesAtualAnoAnterior t2 WITH (NOLOCK) 
		on t1.CodCorretor = t2.CodCorretor
		and t1.NomeRamo = t2.NomeRamo
		and t1.NomeSetor = t2.NomeSetor
	WHERE T2.DtReferencia = @FirstDayOfMonthLastYear

	-- ====================================================================================================================================
	-- Sintetico Premio - Mes Atual Ano Anterior: Update

	update t1
	set	VrPremioLiquidoApoliceNovaProducaoMesAtualAnoAnterior	= CAST(t2.VrPremioLiquidoApoliceNovaProducao AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoNovaProducaoMesAtualAnoAnterior	= CAST(t2.VrPremioLiquidoEndossoNovaProducao AS NUMERIC(18,2))
	,	VrPremioLiquidoApoliceRenovacaoMesAtualAnoAnterior		= CAST(t2.VrPremioLiquidoApoliceRenovacao AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoRenovacaoMesAtualAnoAnterior		= CAST(t2.VrPremioLiquidoEndossoRenovacao AS NUMERIC(18,2))
	,	VrPremioLiquidoTotalMesAtualAnoAnterior					= CAST(t2.VrPremioLiquidoTotal AS NUMERIC(18,2))
	,	QtdeApoliceApoliceNovaProducaoMesAtualAnoAnterior		= CAST(t2.QtdeApoliceApoliceNovaProducao AS INT)
	,	QtdeApoliceEndossoNovaProducaoMesAtualAnoAnterior		= CAST(t2.QtdeApoliceEndossoNovaProducao AS INT)
	,	QtdeApoliceApoliceRenovacaoMesAtualAnoAnterior			= CAST(t2.QtdeApoliceApoliceRenovacao AS INT)
	,	QtdeApoliceEndossoRenovacaoMesAtualAnoAnterior			= CAST(t2.QtdeApoliceEndossoRenovacao AS INT)
	,	QtdeApoliceTotalMesAtualAnoAnterior						= CAST(t2.QtdeApoliceTotal AS INT)

	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO t1
	inner join IndicadorProdutoAutoSinteticoPremio t2 WITH (NOLOCK) 
		on t1.CodCorretor = t2.CodCorretor
		and t1.NomeRamo = t2.NomeRamo
		and t1.NomeSetor = t2.NomeSetor
	WHERE T2.DtReferencia = @FirstDayOfMonthLastYear

	-- ====================================================================================================================================
	--
	--														MES ANTERIOR
	--
	-- ====================================================================================================================================

	-- ====================================================================================================================================
	-- Sintetico Cotacao - Mes Anterior

	DROP TABLE IF EXISTS #TMP_RDS_IndicadorProdutoAutoSinteticoCotacaoMesAnterior

	SELECT
		DtReferencia												= T1.DtReferencia
	,	CodCorretor													= T1.CodCorretor
	,	NomeRamo													= T1.NomeRamo
	,	NomeSetor													= T1.NomeSetor
	,	VrPremioCotacaoRecusada										= SUM(CAST(T1.VrPremioCotacaoRecusada AS NUMERIC(18,2)))
	,	VrPremioCotacaoLiquida										= SUM(CAST(T1.VrPremioCotacaoLiquida AS NUMERIC(18,2)))
	,	VrPremioCotacaoTotal										= SUM(CAST(T1.VrPremioLiquidoTotal AS NUMERIC(18,2)))
	,	QtdeCotacaoRecusada											= SUM(CAST(T1.QtdeCotacaoRecusada AS INT))
	,	QtdeCotacaoLiquida											= SUM(CAST(T1.QtdeCotacaoLiquida AS INT))
	,	QtdeCotacaoTotal											= SUM(CAST(T1.QtdeCotacaoTotal AS INT))
	,	QtdeCotacaoEsforcoRecusada									= SUM(CAST(T1.QtdeCotacaoEsforcoRecusada AS INT))
	,	QtdeCotacaoEsforcoLiquida									= SUM(CAST(T1.QtdeCotacaoEsforcoLiquida AS INT))
	,	QtdeCotacaoEsforcoTotal										= SUM(CAST(T1.QtdeCotacaoEsforcoTotal AS INT))
	,	QtdeCotacaoEsforcoMulticalculoRecusada						= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoRecusada AS INT))
	,	QtdeCotacaoEsforcoMulticalculoLiquida						= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoLiquida AS INT))
	,	QtdeCotacaoEsforcoMulticalculoTotal							= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoTotal AS INT))
	,	QtdePropostaEmitida											= SUM(CAST(T1.QtdePropostaEmitida AS INT))
	,	QtdePropostaPendente										= SUM(CAST(T1.QtdePropostaPendente AS INT))
	,	QtdePropostaTotal											= SUM(CAST(T1.QtdePropostaTotal AS INT))
	,	QtdeCotacaoApoliceTotal										= SUM(CAST(T1.QtdeApoliceTotal AS INT))

	INTO #TMP_RDS_IndicadorProdutoAutoSinteticoCotacaoMesAnterior
	FROM IndicadorProdutoAutoSinteticoCotacao T1
	WHERE T1.DtReferencia = @FirstDayPreviousMonth 
	GROUP BY
		T1.DtReferencia
	,	T1.CodCorretor
	,	T1.NomeRamo
	,	T1.NomeSetor

	-- ====================================================================================================================================
	-- Sintetico Cotacao - Mes Anterior: Update

	update t1
	set	t1.VrPremioCotacaoRecusadaMesAnterior					= t2.VrPremioCotacaoRecusada
	,	t1.VrPremioCotacaoLiquidaMesAnterior					= t2.VrPremioCotacaoLiquida
	,	t1.VrPremioCotacaoTotalMesAnterior						= t2.VrPremioCotacaoTotal
	,	t1.QtdeCotacaoRecusadaMesAnterior						= t2.QtdeCotacaoRecusada
	,	t1.QtdeCotacaoLiquidaMesAnterior						= t2.QtdeCotacaoLiquida
	,	t1.QtdeCotacaoTotalMesAnterior							= t2.QtdeCotacaoTotal
	,	t1.QtdeCotacaoEsforcoRecusadaMesAnterior				= t2.QtdeCotacaoEsforcoRecusada
	,	t1.QtdeCotacaoEsforcoLiquidaMesAnterior					= t2.QtdeCotacaoEsforcoLiquida
	,	t1.QtdeCotacaoEsforcoTotalMesAnterior					= t2.QtdeCotacaoEsforcoTotal
	,	t1.QtdeCotacaoEsforcoMulticalculoRecusadaMesAnterior	= t2.QtdeCotacaoEsforcoMulticalculoRecusada
	,	t1.QtdeCotacaoEsforcoMulticalculoLiquidaMesAnterior		= t2.QtdeCotacaoEsforcoMulticalculoLiquida
	,	t1.QtdeCotacaoEsforcoMulticalculoTotalMesAnterior		= t2.QtdeCotacaoEsforcoMulticalculoTotal
	,	t1.QtdePropostaEmitidaMesAnterior						= t2.QtdePropostaEmitida
	,	t1.QtdePropostaPendenteMesAnterior						= t2.QtdePropostaPendente
	,	t1.QtdePropostaTotalMesAnterior							= t2.QtdePropostaTotal
	,	t1.QtdeCotacaoApoliceTotalMesAnterior					= t2.QtdeCotacaoApoliceTotal

	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO t1
	inner join #TMP_RDS_IndicadorProdutoAutoSinteticoCotacaoMesAnterior t2 WITH (NOLOCK) 
		on t1.CodCorretor = t2.CodCorretor
		and t1.NomeRamo = t2.NomeRamo
		and t1.NomeSetor = t2.NomeSetor
	WHERE T2.DtReferencia = @FirstDayPreviousMonth

	-- ====================================================================================================================================
	-- Sintetico Premio - Mes Anterior: Update

	update t1
	set	VrPremioLiquidoApoliceNovaProducaoMesAnterior	= CAST(t2.VrPremioLiquidoApoliceNovaProducao AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoNovaProducaoMesAnterior	= CAST(t2.VrPremioLiquidoEndossoNovaProducao AS NUMERIC(18,2))
	,	VrPremioLiquidoApoliceRenovacaoMesAnterior		= CAST(t2.VrPremioLiquidoApoliceRenovacao AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoRenovacaoMesAnterior		= CAST(t2.VrPremioLiquidoEndossoRenovacao AS NUMERIC(18,2))
	,	VrPremioLiquidoTotalMesAnterior					= CAST(t2.VrPremioLiquidoTotal AS NUMERIC(18,2))
	,	QtdeApoliceApoliceNovaProducaoMesAnterior		= CAST(t2.QtdeApoliceApoliceNovaProducao AS INT)
	,	QtdeApoliceEndossoNovaProducaoMesAnterior		= CAST(t2.QtdeApoliceEndossoNovaProducao AS INT)
	,	QtdeApoliceApoliceRenovacaoMesAnterior			= CAST(t2.QtdeApoliceApoliceRenovacao AS INT)
	,	QtdeApoliceEndossoRenovacaoMesAnterior			= CAST(t2.QtdeApoliceEndossoRenovacao AS INT)
	,	QtdeApoliceTotalMesAnterior						= CAST(t2.QtdeApoliceTotal AS INT)

	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO t1
	inner join IndicadorProdutoAutoSinteticoPremio t2 WITH (NOLOCK) 
		on t1.CodCorretor = t2.CodCorretor
		and t1.NomeRamo = t2.NomeRamo
		and t1.NomeSetor = t2.NomeSetor
	WHERE T2.DtReferencia = @FirstDayPreviousMonth

	-- ====================================================================================================================================
	-- Sintetico Renovacao - Mes Atual: Update

	update t1
	set	
		QtdePolizaEspMesAnterior		= CAST(t2.QtdePolizaEsp AS INT)	-- Conceito: QTD Renova��es Esperadas
	,	QtdeOfertadaMesAnterior			= CAST(t2.QtdeOfertada AS INT)	-- Conceito: QTD Renova��es Ofertadas
	,	QtdePolizaRenMesAnterior		= CAST(t2.QtdePolizaRen AS INT)	-- Conceito: QTD Renova��es Efetivadas

	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO t1
	inner join IndicadorProdutoAutoSinteticoRenovacao t2 WITH (NOLOCK) 
		on t1.CodCorretor = t2.CodCorretor
		and t1.NomeRamo = t2.NomeRamo
		and t1.NomeSetor = t2.NomeSetor
	WHERE T2.DtReferencia = @FirstDayPreviousMonth

	-- ====================================================================================================================================
	--
	--													MES ANTERIOR ANO ANTERIOR
	--
	-- ====================================================================================================================================

	-- ====================================================================================================================================
	-- Sintetico Cotacao - Mes Anterior Ano Anterior

	DROP TABLE IF EXISTS #TMP_RDS_IndicadorProdutoAutoSinteticoCotacaoMesAnteriorAnoAnterior

	SELECT
		DtReferencia												= T1.DtReferencia
	,	CodCorretor													= T1.CodCorretor
	,	NomeRamo													= T1.NomeRamo
	,	NomeSetor													= T1.NomeSetor
	,	VrPremioCotacaoRecusada										= SUM(CAST(T1.VrPremioCotacaoRecusada AS NUMERIC(18,2)))
	,	VrPremioCotacaoLiquida										= SUM(CAST(T1.VrPremioCotacaoLiquida AS NUMERIC(18,2)))
	,	VrPremioCotacaoTotal										= SUM(CAST(T1.VrPremioLiquidoTotal AS NUMERIC(18,2)))
	,	QtdeCotacaoRecusada											= SUM(CAST(T1.QtdeCotacaoRecusada AS INT))
	,	QtdeCotacaoLiquida											= SUM(CAST(T1.QtdeCotacaoLiquida AS INT))
	,	QtdeCotacaoTotal											= SUM(CAST(T1.QtdeCotacaoTotal AS INT))
	,	QtdeCotacaoEsforcoRecusada									= SUM(CAST(T1.QtdeCotacaoEsforcoRecusada AS INT))
	,	QtdeCotacaoEsforcoLiquida									= SUM(CAST(T1.QtdeCotacaoEsforcoLiquida AS INT))
	,	QtdeCotacaoEsforcoTotal										= SUM(CAST(T1.QtdeCotacaoEsforcoTotal AS INT))
	,	QtdeCotacaoEsforcoMulticalculoRecusada						= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoRecusada AS INT))
	,	QtdeCotacaoEsforcoMulticalculoLiquida						= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoLiquida AS INT))
	,	QtdeCotacaoEsforcoMulticalculoTotal							= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoTotal AS INT))
	,	QtdePropostaEmitida											= SUM(CAST(T1.QtdePropostaEmitida AS INT))
	,	QtdePropostaPendente										= SUM(CAST(T1.QtdePropostaPendente AS INT))
	,	QtdePropostaTotal											= SUM(CAST(T1.QtdePropostaTotal AS INT))
	,	QtdeCotacaoApoliceTotal										= SUM(CAST(T1.QtdeApoliceTotal AS INT))

	INTO #TMP_RDS_IndicadorProdutoAutoSinteticoCotacaoMesAnteriorAnoAnterior
	FROM IndicadorProdutoAutoSinteticoCotacao T1
	WHERE T1.DtReferencia = @FirstDayPreviousMonthPreviousYear 
	GROUP BY
		T1.DtReferencia
	,	T1.CodCorretor
	,	T1.NomeRamo
	,	T1.NomeSetor

	-- ====================================================================================================================================
	-- Sintetico Cotacao - Mes Anterior Ano Anterior: Update

	update t1
	set	t1.VrPremioCotacaoRecusadaMesAnteriorAnoAnterior					= t2.VrPremioCotacaoRecusada
	,	t1.VrPremioCotacaoLiquidaMesAnteriorAnoAnterior						= t2.VrPremioCotacaoLiquida
	,	t1.VrPremioCotacaoTotalMesAnteriorAnoAnterior						= t2.VrPremioCotacaoTotal
	,	t1.QtdeCotacaoRecusadaMesAnteriorAnoAnterior						= t2.QtdeCotacaoRecusada
	,	t1.QtdeCotacaoLiquidaMesAnteriorAnoAnterior							= t2.QtdeCotacaoLiquida
	,	t1.QtdeCotacaoTotalMesAnteriorAnoAnterior							= t2.QtdeCotacaoTotal
	,	t1.QtdeCotacaoEsforcoRecusadaMesAnteriorAnoAnterior					= t2.QtdeCotacaoEsforcoRecusada
	,	t1.QtdeCotacaoEsforcoLiquidaMesAnteriorAnoAnterior					= t2.QtdeCotacaoEsforcoLiquida
	,	t1.QtdeCotacaoEsforcoTotalMesAnteriorAnoAnterior					= t2.QtdeCotacaoEsforcoTotal
	,	t1.QtdeCotacaoEsforcoMulticalculoRecusadaMesAnteriorAnoAnterior		= t2.QtdeCotacaoEsforcoMulticalculoRecusada
	,	t1.QtdeCotacaoEsforcoMulticalculoLiquidaMesAnteriorAnoAnterior		= t2.QtdeCotacaoEsforcoMulticalculoLiquida
	,	t1.QtdeCotacaoEsforcoMulticalculoTotalMesAnteriorAnoAnterior		= t2.QtdeCotacaoEsforcoMulticalculoTotal
	,	t1.QtdePropostaEmitidaMesAnteriorAnoAnterior						= t2.QtdePropostaEmitida
	,	t1.QtdePropostaPendenteMesAnteriorAnoAnterior						= t2.QtdePropostaPendente
	,	t1.QtdePropostaTotalMesAnteriorAnoAnterior							= t2.QtdePropostaTotal
	,	t1.QtdeCotacaoApoliceTotalMesAnteriorAnoAnterior					= t2.QtdeCotacaoApoliceTotal

	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO t1
	inner join #TMP_RDS_IndicadorProdutoAutoSinteticoCotacaoMesAnteriorAnoAnterior t2 WITH (NOLOCK) 
		on t1.CodCorretor = t2.CodCorretor
		and t1.NomeRamo = t2.NomeRamo
		and t1.NomeSetor = t2.NomeSetor
	WHERE T2.DtReferencia = @FirstDayPreviousMonthPreviousYear

	-- ====================================================================================================================================
	-- Sintetico Premio - Mes Anterior Ano Anterior: Update

	update t1
	set	VrPremioLiquidoApoliceNovaProducaoMesAnteriorAnoAnterior	= CAST(t2.VrPremioLiquidoApoliceNovaProducao AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoNovaProducaoMesAnteriorAnoAnterior	= CAST(t2.VrPremioLiquidoEndossoNovaProducao AS NUMERIC(18,2))
	,	VrPremioLiquidoApoliceRenovacaoMesAnteriorAnoAnterior		= CAST(t2.VrPremioLiquidoApoliceRenovacao AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoRenovacaoMesAnteriorAnoAnterior		= CAST(t2.VrPremioLiquidoEndossoRenovacao AS NUMERIC(18,2))
	,	VrPremioLiquidoTotalMesAnteriorAnoAnterior					= CAST(t2.VrPremioLiquidoTotal AS NUMERIC(18,2))
	,	QtdeApoliceApoliceNovaProducaoMesAnteriorAnoAnterior		= CAST(t2.QtdeApoliceApoliceNovaProducao AS INT)
	,	QtdeApoliceEndossoNovaProducaoMesAnteriorAnoAnterior		= CAST(t2.QtdeApoliceEndossoNovaProducao AS INT)
	,	QtdeApoliceApoliceRenovacaoMesAnteriorAnoAnterior			= CAST(t2.QtdeApoliceApoliceRenovacao AS INT)
	,	QtdeApoliceEndossoRenovacaoMesAnteriorAnoAnterior			= CAST(t2.QtdeApoliceEndossoRenovacao AS INT)
	,	QtdeApoliceTotalMesAnteriorAnoAnterior						= CAST(t2.QtdeApoliceTotal AS INT)

	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO t1
	inner join IndicadorProdutoAutoSinteticoPremio t2 WITH (NOLOCK) 
		on t1.CodCorretor = t2.CodCorretor
		and t1.NomeRamo = t2.NomeRamo
		and t1.NomeSetor = t2.NomeSetor
	WHERE T2.DtReferencia = @FirstDayPreviousMonthPreviousYear

	-- ====================================================================================================================================
	--
	--															ANO ACUMULADO
	--
	-- ====================================================================================================================================

	-- ====================================================================================================================================
	-- Sintetico Cotacao - Ano Acumulado (De Jan at� M-1)

	DROP TABLE IF EXISTS #TMP_RDS_IndicadorProdutoAutoSinteticoCotacaoAnoAcumulado

	SELECT
		CodCorretor													= T1.CodCorretor
	,	NomeRamo													= T1.NomeRamo
	,	NomeSetor													= T1.NomeSetor
	,	VrPremioCotacaoRecusada										= SUM(CAST(T1.VrPremioCotacaoRecusada AS NUMERIC(18,2)))
	,	VrPremioCotacaoLiquida										= SUM(CAST(T1.VrPremioCotacaoLiquida AS NUMERIC(18,2)))
	,	VrPremioCotacaoTotal										= SUM(CAST(T1.VrPremioLiquidoTotal AS NUMERIC(18,2)))
	,	QtdeCotacaoRecusada											= SUM(CAST(T1.QtdeCotacaoRecusada AS INT))
	,	QtdeCotacaoLiquida											= SUM(CAST(T1.QtdeCotacaoLiquida AS INT))
	,	QtdeCotacaoTotal											= SUM(CAST(T1.QtdeCotacaoTotal AS INT))
	,	QtdeCotacaoEsforcoRecusada									= SUM(CAST(T1.QtdeCotacaoEsforcoRecusada AS INT))
	,	QtdeCotacaoEsforcoLiquida									= SUM(CAST(T1.QtdeCotacaoEsforcoLiquida AS INT))
	,	QtdeCotacaoEsforcoTotal										= SUM(CAST(T1.QtdeCotacaoEsforcoTotal AS INT))
	,	QtdeCotacaoEsforcoMulticalculoRecusada						= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoRecusada AS INT))
	,	QtdeCotacaoEsforcoMulticalculoLiquida						= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoLiquida AS INT))
	,	QtdeCotacaoEsforcoMulticalculoTotal							= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoTotal AS INT))
	,	QtdePropostaEmitida											= SUM(CAST(T1.QtdePropostaEmitida AS INT))
	,	QtdePropostaPendente										= SUM(CAST(T1.QtdePropostaPendente AS INT))
	,	QtdePropostaTotal											= SUM(CAST(T1.QtdePropostaTotal AS INT))
	,	QtdeCotacaoApoliceTotal										= SUM(CAST(T1.QtdeApoliceTotal AS INT))

	INTO #TMP_RDS_IndicadorProdutoAutoSinteticoCotacaoAnoAcumulado
	FROM IndicadorProdutoAutoSinteticoCotacao T1
	WHERE T1.DtReferencia between @FirstDayOfYear and CASE WHEN @FirstDayOfYear > @FirstDayPreviousMonth THEN @FirstDayOfYear ELSE @FirstDayPreviousMonth END
	GROUP BY
		T1.CodCorretor
	,	T1.NomeRamo
	,	T1.NomeSetor

	-- ====================================================================================================================================
	-- Sintetico Cotacao - Ano Acumulado (De Jan at� M-1): Update

	update t1
	set	t1.VrPremioCotacaoRecusadaAnoAcumulado					= t2.VrPremioCotacaoRecusada
	,	t1.VrPremioCotacaoLiquidaAnoAcumulado					= t2.VrPremioCotacaoLiquida
	,	t1.VrPremioCotacaoTotalAnoAcumulado						= t2.VrPremioCotacaoTotal
	,	t1.QtdeCotacaoRecusadaAnoAcumulado						= t2.QtdeCotacaoRecusada
	,	t1.QtdeCotacaoLiquidaAnoAcumulado						= t2.QtdeCotacaoLiquida
	,	t1.QtdeCotacaoTotalAnoAcumulado							= t2.QtdeCotacaoTotal
	,	t1.QtdeCotacaoEsforcoRecusadaAnoAcumulado				= t2.QtdeCotacaoEsforcoRecusada
	,	t1.QtdeCotacaoEsforcoLiquidaAnoAcumulado				= t2.QtdeCotacaoEsforcoLiquida
	,	t1.QtdeCotacaoEsforcoTotalAnoAcumulado					= t2.QtdeCotacaoEsforcoTotal
	,	t1.QtdeCotacaoEsforcoMulticalculoRecusadaAnoAcumulado	= t2.QtdeCotacaoEsforcoMulticalculoRecusada
	,	t1.QtdeCotacaoEsforcoMulticalculoLiquidaAnoAcumulado	= t2.QtdeCotacaoEsforcoMulticalculoLiquida
	,	t1.QtdeCotacaoEsforcoMulticalculoTotalAnoAcumulado		= t2.QtdeCotacaoEsforcoMulticalculoTotal
	,	t1.QtdePropostaEmitidaAnoAcumulado						= t2.QtdePropostaEmitida
	,	t1.QtdePropostaPendenteAnoAcumulado						= t2.QtdePropostaPendente
	,	t1.QtdePropostaTotalAnoAcumulado						= t2.QtdePropostaTotal
	,	t1.QtdeCotacaoApoliceTotalAnoAcumulado					= t2.QtdeCotacaoApoliceTotal

	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO t1
	inner join #TMP_RDS_IndicadorProdutoAutoSinteticoCotacaoAnoAcumulado t2 WITH (NOLOCK) 
		on t1.CodCorretor = t2.CodCorretor
		and t1.NomeRamo = t2.NomeRamo
		and t1.NomeSetor = t2.NomeSetor

	-- ====================================================================================================================================
	-- Sintetico Premio - Ano Acumulado (De Jan at� M-1): Base temporaria

	DROP TABLE IF EXISTS #TMP_RDS_IndicadorProdutoAutoSinteticoPremioAnoAcumulado

	select 
		CodCorretor							= T1.CodCorretor
	,	NomeRamo							= T1.NomeRamo
	,	NomeSetor							= T1.NomeSetor
	,	VrPremioLiquidoApoliceNovaProducao	= SUM(CAST(T1.VrPremioLiquidoApoliceNovaProducao AS NUMERIC(18,2)) )
	,	VrPremioLiquidoEndossoNovaProducao	= SUM(CAST(T1.VrPremioLiquidoEndossoNovaProducao AS NUMERIC(18,2)) )
	,	VrPremioLiquidoApoliceRenovacao		= SUM(CAST(T1.VrPremioLiquidoApoliceRenovacao AS NUMERIC(18,2)) )
	,	VrPremioLiquidoEndossoRenovacao		= SUM(CAST(T1.VrPremioLiquidoEndossoRenovacao AS NUMERIC(18,2)) )
	,	VrPremioLiquidoTotal				= SUM(CAST(T1.VrPremioLiquidoTotal AS NUMERIC(18,2)) )
	,	QtdeApoliceApoliceNovaProducao		= SUM(CAST(T1.QtdeApoliceApoliceNovaProducao AS INT) )
	,	QtdeApoliceEndossoNovaProducao		= SUM(CAST(T1.QtdeApoliceEndossoNovaProducao AS INT) )
	,	QtdeApoliceApoliceRenovacao			= SUM(CAST(T1.QtdeApoliceApoliceRenovacao AS INT) )
	,	QtdeApoliceEndossoRenovacao			= SUM(CAST(T1.QtdeApoliceEndossoRenovacao AS INT) )
	,	QtdeApoliceTotal					= SUM(CAST(T1.QtdeApoliceTotal AS INT) )

	into #TMP_RDS_IndicadorProdutoAutoSinteticoPremioAnoAcumulado
	FROM IndicadorProdutoAutoSinteticoPremio T1 WITH (NOLOCK)
	WHERE T1.DtReferencia between @FirstDayOfYear and CASE WHEN @FirstDayOfYear > @FirstDayPreviousMonth THEN @FirstDayOfYear ELSE @FirstDayPreviousMonth END
	GROUP BY
		T1.CodCorretor
	,	T1.NomeRamo
	,	T1.NomeSetor

	-- ====================================================================================================================================
	-- Sintetico Premio - Ano Acumulado (De Jan at� M-1): Update

	update t1
	set	VrPremioLiquidoApoliceNovaProducaoAnoAcumulado	= CAST(t2.VrPremioLiquidoApoliceNovaProducao AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoNovaProducaoAnoAcumulado	= CAST(t2.VrPremioLiquidoEndossoNovaProducao AS NUMERIC(18,2))
	,	VrPremioLiquidoApoliceRenovacaoAnoAcumulado		= CAST(t2.VrPremioLiquidoApoliceRenovacao AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoRenovacaoAnoAcumulado		= CAST(t2.VrPremioLiquidoEndossoRenovacao AS NUMERIC(18,2))
	,	VrPremioLiquidoTotalAnoAcumulado				= CAST(t2.VrPremioLiquidoTotal AS NUMERIC(18,2))
	,	QtdeApoliceApoliceNovaProducaoAnoAcumulado		= CAST(t2.QtdeApoliceApoliceNovaProducao AS INT)
	,	QtdeApoliceEndossoNovaProducaoAnoAcumulado		= CAST(t2.QtdeApoliceEndossoNovaProducao AS INT)
	,	QtdeApoliceApoliceRenovacaoAnoAcumulado			= CAST(t2.QtdeApoliceApoliceRenovacao AS INT)
	,	QtdeApoliceEndossoRenovacaoAnoAcumulado			= CAST(t2.QtdeApoliceEndossoRenovacao AS INT)
	,	QtdeApoliceTotalAnoAcumulado					= CAST(t2.QtdeApoliceTotal AS INT)

	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO t1
	inner join #TMP_RDS_IndicadorProdutoAutoSinteticoPremioAnoAcumulado t2 WITH (NOLOCK) 
		on t1.CodCorretor = t2.CodCorretor
		and t1.NomeRamo = t2.NomeRamo
		and t1.NomeSetor = t2.NomeSetor

	-- ====================================================================================================================================
	--
	--															ANO ANTERIOR ACUMULADO
	--
	-- ====================================================================================================================================

	-- ====================================================================================================================================
	-- Sintetico Cotacao - Ano Anterior Acumulado (De Jan at� M-1)
		
	DROP TABLE IF EXISTS #TMP_RDS_IndicadorProdutoAutoSinteticoCotacaoAnoAnteriorAcumulado

	SELECT
		CodCorretor													= T1.CodCorretor
	,	NomeRamo													= T1.NomeRamo
	,	NomeSetor													= T1.NomeSetor
	,	VrPremioCotacaoRecusada										= SUM(CAST(T1.VrPremioCotacaoRecusada AS NUMERIC(18,2)))
	,	VrPremioCotacaoLiquida										= SUM(CAST(T1.VrPremioCotacaoLiquida AS NUMERIC(18,2)))
	,	VrPremioCotacaoTotal										= SUM(CAST(T1.VrPremioLiquidoTotal AS NUMERIC(18,2)))
	,	QtdeCotacaoRecusada											= SUM(CAST(T1.QtdeCotacaoRecusada AS INT))
	,	QtdeCotacaoLiquida											= SUM(CAST(T1.QtdeCotacaoLiquida AS INT))
	,	QtdeCotacaoTotal											= SUM(CAST(T1.QtdeCotacaoTotal AS INT))
	,	QtdeCotacaoEsforcoRecusada									= SUM(CAST(T1.QtdeCotacaoEsforcoRecusada AS INT))
	,	QtdeCotacaoEsforcoLiquida									= SUM(CAST(T1.QtdeCotacaoEsforcoLiquida AS INT))
	,	QtdeCotacaoEsforcoTotal										= SUM(CAST(T1.QtdeCotacaoEsforcoTotal AS INT))
	,	QtdeCotacaoEsforcoMulticalculoRecusada						= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoRecusada AS INT))
	,	QtdeCotacaoEsforcoMulticalculoLiquida						= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoLiquida AS INT))
	,	QtdeCotacaoEsforcoMulticalculoTotal							= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoTotal AS INT))
	,	QtdePropostaEmitida											= SUM(CAST(T1.QtdePropostaEmitida AS INT))
	,	QtdePropostaPendente										= SUM(CAST(T1.QtdePropostaPendente AS INT))
	,	QtdePropostaTotal											= SUM(CAST(T1.QtdePropostaTotal AS INT))
	,	QtdeCotacaoApoliceTotal										= SUM(CAST(T1.QtdeApoliceTotal AS INT))

	INTO #TMP_RDS_IndicadorProdutoAutoSinteticoCotacaoAnoAnteriorAcumulado
	FROM IndicadorProdutoAutoSinteticoCotacao T1
	WHERE T1.DtReferencia between @FirstDayPreviousYear and @FirstDayPreviousMonthPreviousYear 
	GROUP BY
		T1.CodCorretor
	,	T1.NomeRamo
	,	T1.NomeSetor

	-- ====================================================================================================================================
	-- Sintetico Cotacao - Ano Anterior Acumulado (De Jan at� M-1): Update

	update t1
	set	t1.VrPremioCotacaoRecusadaAnoAnteriorAcumulado					= t2.VrPremioCotacaoRecusada
	,	t1.VrPremioCotacaoLiquidaAnoAnteriorAcumulado					= t2.VrPremioCotacaoLiquida
	,	t1.VrPremioCotacaoTotalAnoAnteriorAcumulado						= t2.VrPremioCotacaoTotal
	,	t1.QtdeCotacaoRecusadaAnoAnteriorAcumulado						= t2.QtdeCotacaoRecusada
	,	t1.QtdeCotacaoLiquidaAnoAnteriorAcumulado						= t2.QtdeCotacaoLiquida
	,	t1.QtdeCotacaoTotalAnoAnteriorAcumulado							= t2.QtdeCotacaoTotal
	,	t1.QtdeCotacaoEsforcoRecusadaAnoAnteriorAcumulado				= t2.QtdeCotacaoEsforcoRecusada
	,	t1.QtdeCotacaoEsforcoLiquidaAnoAnteriorAcumulado				= t2.QtdeCotacaoEsforcoLiquida
	,	t1.QtdeCotacaoEsforcoTotalAnoAnteriorAcumulado					= t2.QtdeCotacaoEsforcoTotal
	,	t1.QtdeCotacaoEsforcoMulticalculoRecusadaAnoAnteriorAcumulado	= t2.QtdeCotacaoEsforcoMulticalculoRecusada
	,	t1.QtdeCotacaoEsforcoMulticalculoLiquidaAnoAnteriorAcumulado	= t2.QtdeCotacaoEsforcoMulticalculoLiquida
	,	t1.QtdeCotacaoEsforcoMulticalculoTotalAnoAnteriorAcumulado		= t2.QtdeCotacaoEsforcoMulticalculoTotal
	,	t1.QtdePropostaEmitidaAnoAnteriorAcumulado						= t2.QtdePropostaEmitida
	,	t1.QtdePropostaPendenteAnoAnteriorAcumulado						= t2.QtdePropostaPendente
	,	t1.QtdePropostaTotalAnoAnteriorAcumulado						= t2.QtdePropostaTotal
	,	t1.QtdeCotacaoApoliceTotalAnoAnteriorAcumulado					= t2.QtdeCotacaoApoliceTotal

	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO t1
	inner join #TMP_RDS_IndicadorProdutoAutoSinteticoCotacaoAnoAnteriorAcumulado t2 WITH (NOLOCK) 
		on t1.CodCorretor = t2.CodCorretor
		and t1.NomeRamo = t2.NomeRamo
		and t1.NomeSetor = t2.NomeSetor

	-- ====================================================================================================================================
	-- Sintetico Premio - Ano Anterior Acumulado (De Jan at� M-1): Base temporaria

	DROP TABLE IF EXISTS #TMP_RDS_IndicadorProdutoAutoSinteticoPremioAnoAnteriorAcumulado

	select 
		CodCorretor							= T1.CodCorretor
	,	NomeRamo							= T1.NomeRamo
	,	NomeSetor							= T1.NomeSetor
	,	VrPremioLiquidoApoliceNovaProducao	= SUM(CAST(T1.VrPremioLiquidoApoliceNovaProducao AS NUMERIC(18,2)) )
	,	VrPremioLiquidoEndossoNovaProducao	= SUM(CAST(T1.VrPremioLiquidoEndossoNovaProducao AS NUMERIC(18,2)) )
	,	VrPremioLiquidoApoliceRenovacao		= SUM(CAST(T1.VrPremioLiquidoApoliceRenovacao AS NUMERIC(18,2)) )
	,	VrPremioLiquidoEndossoRenovacao		= SUM(CAST(T1.VrPremioLiquidoEndossoRenovacao AS NUMERIC(18,2)) )
	,	VrPremioLiquidoTotal				= SUM(CAST(T1.VrPremioLiquidoTotal AS NUMERIC(18,2)) )
	,	QtdeApoliceApoliceNovaProducao		= SUM(CAST(T1.QtdeApoliceApoliceNovaProducao AS INT) )
	,	QtdeApoliceEndossoNovaProducao		= SUM(CAST(T1.QtdeApoliceEndossoNovaProducao AS INT) )
	,	QtdeApoliceApoliceRenovacao			= SUM(CAST(T1.QtdeApoliceApoliceRenovacao AS INT) )
	,	QtdeApoliceEndossoRenovacao			= SUM(CAST(T1.QtdeApoliceEndossoRenovacao AS INT) )
	,	QtdeApoliceTotal					= SUM(CAST(T1.QtdeApoliceTotal AS INT) )

	into #TMP_RDS_IndicadorProdutoAutoSinteticoPremioAnoAnteriorAcumulado
	FROM IndicadorProdutoAutoSinteticoPremio T1 WITH (NOLOCK)
	WHERE T1.DtReferencia between @FirstDayPreviousYear and @FirstDayPreviousMonthPreviousYear
	GROUP BY
		T1.CodCorretor
	,	T1.NomeRamo
	,	T1.NomeSetor

	-- ====================================================================================================================================
	-- Sintetico Premio - Ano Anterior Acumulado (De Jan at� M-1): Update

	update t1
	set	VrPremioLiquidoApoliceNovaProducaoAnoAnteriorAcumulado	= CAST(t2.VrPremioLiquidoApoliceNovaProducao AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoNovaProducaoAnoAnteriorAcumulado	= CAST(t2.VrPremioLiquidoEndossoNovaProducao AS NUMERIC(18,2))
	,	VrPremioLiquidoApoliceRenovacaoAnoAnteriorAcumulado		= CAST(t2.VrPremioLiquidoApoliceRenovacao AS NUMERIC(18,2))
	,	VrPremioLiquidoEndossoRenovacaoAnoAnteriorAcumulado		= CAST(t2.VrPremioLiquidoEndossoRenovacao AS NUMERIC(18,2))
	,	VrPremioLiquidoTotalAnoAnteriorAcumulado				= CAST(t2.VrPremioLiquidoTotal AS NUMERIC(18,2))
	,	QtdeApoliceApoliceNovaProducaoAnoAnteriorAcumulado		= CAST(t2.QtdeApoliceApoliceNovaProducao AS INT)
	,	QtdeApoliceEndossoNovaProducaoAnoAnteriorAcumulado		= CAST(t2.QtdeApoliceEndossoNovaProducao AS INT)
	,	QtdeApoliceApoliceRenovacaoAnoAnteriorAcumulado			= CAST(t2.QtdeApoliceApoliceRenovacao AS INT)
	,	QtdeApoliceEndossoRenovacaoAnoAnteriorAcumulado			= CAST(t2.QtdeApoliceEndossoRenovacao AS INT)
	,	QtdeApoliceTotalAnoAnteriorAcumulado					= CAST(t2.QtdeApoliceTotal AS INT)

	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO t1
	inner join #TMP_RDS_IndicadorProdutoAutoSinteticoPremioAnoAnteriorAcumulado t2 WITH (NOLOCK) 
		on t1.CodCorretor = t2.CodCorretor
		and t1.NomeRamo = t2.NomeRamo
		and t1.NomeSetor = t2.NomeSetor

	-- ====================================================================================================================================
	--
	--												ATUALIZANDO O VALOR DO ORCADO
	--
	-- ====================================================================================================================================

	-- ====================================================================================================================================
	-- Agregando a base Orcado: Mes Atual

	drop table if exists #tmp_rds_Orcado_Mes_Atual

	select 
		NrAnoMes		= t1.NrAnoMes
	,	CodCorretor		= t1.CodCorretor
	,	NomeUnidade		= t1.NomeUnidade
	,	NomeSetor		= t1.NomeSetor
	,	VrOrcado		= sum(t1.VrOrcado)  

	into #tmp_rds_Orcado_Mes_Atual
	from dbo.tbOrcado t1
	inner join dbo.HierarquiaComercialUnificada t2 on t1.CodCorretor = t2.CodCorretor
	where t1.NomeUnidade = 'Automovel'
	and t1.NrAnoMes = @FirstDayOfMonth
	group by 
		t1.NrAnoMes
	,	t1.CodCorretor
	,	t1.NomeUnidade
	,	t1.NomeSetor

	-- ====================================================================================================================================
	-- Agregando a base Orcado: Ano Acumulado

	drop table if exists #tmp_rds_Orcado_Ano_Acumulado

	select 
		CodCorretor		= t1.CodCorretor
	,	NomeUnidade		= t1.NomeUnidade
	,	NomeSetor		= t1.NomeSetor
	,	VrOrcado		= sum(t1.VrOrcado)  

	into #tmp_rds_Orcado_Ano_Acumulado
	from dbo.tbOrcado t1
	inner join dbo.HierarquiaComercialUnificada t2 on t1.CodCorretor = t2.CodCorretor
	where t1.NomeUnidade = 'Automovel'
	and t1.NrAnoMes between @FirstDayOfYear and CASE WHEN @FirstDayOfYear > @FirstDayPreviousMonth THEN @FirstDayOfYear ELSE @FirstDayPreviousMonth END
	group by 
		t1.CodCorretor
	,	t1.NomeUnidade
	,	t1.NomeSetor

	-- ====================================================================================================================================
	-- Atualizando a base: Mes Atual

	update t1
	set	t1.VrOrcado	= t2.VrOrcado
	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO t1
	inner join #tmp_rds_Orcado_Mes_Atual t2 WITH (NOLOCK) 
		on t1.CodCorretor = t2.CodCorretor
		and t1.NomeRamo = t2.NomeUnidade
		and t1.NomeSetor = t2.NomeSetor

	-- ====================================================================================================================================
	-- Atualizando a base: Ano Acumulado
	
	update t1
	set	t1.VrOrcadoAnoAcumulado	= t2.VrOrcado
	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO t1
	inner join #tmp_rds_Orcado_Ano_Acumulado t2 WITH (NOLOCK) 
		on t1.CodCorretor = t2.CodCorretor
		and t1.NomeRamo = t2.NomeUnidade
		and t1.NomeSetor = t2.NomeSetor

	-- ====================================================================================================================================
	--
	--														TEMPORARIA FINAL
	--
	-- ====================================================================================================================================

	-- ====================================================================================================================================
	-- Agregando a temporaria final

	DROP TABLE IF EXISTS #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO_FINAL

	SELECT
		DtReferencia												= T1.DtReferencia
	,	DtProcessamento												= T1.DtProcessamento
	,	CodCorretor													= T1.CodCorretor
	,	NomeCorretor												= T1.NomeCorretor
	,	RaizCpfCnpjCorretor											= T1.RaizCpfCnpjCorretor
	,	CodAssessor													= T1.CodAssessor
	,	NomeAssessor												= T1.NomeAssessor
	,	CodSucursal													= T1.CodSucursal
	,	NomeSucursal												= T1.NomeSucursal
	,	CodTerritorial												= T1.CodTerritorial
	,	NomeTerritorial												= T1.NomeTerritorial
	,	CodCanal1													= T1.CodCanal1 
	,	DescricaoCanal1												= T1.DescricaoCanal1 
	,	CodCanal2													= T1.CodCanal2 
	,	DescricaoCanal2												= T1.DescricaoCanal2 
	,	CodCanal3													= T1.CodCanal3 
	,	DescricaoCanal3												= T1.DescricaoCanal3 
	,	CodCanal4													= T1.CodCanal4 
	,	DescricaoCanal4												= T1.DescricaoCanal4 
	,	TipoAtendimentoId											= T1.TipoAtendimentoId
	,	NomeAtendimento												= T1.NomeAtendimento
	,	NomeRamo													= T1.NomeRamo
	,	NomeSetor													= T1.NomeSetor
	-- =======================================================================================
	-- Mes Atual: 
	---- Sintetico Premio
	,	VrPremioLiquidoApoliceNovaProducao							= SUM(CAST(T1.VrPremioLiquidoApoliceNovaProducao AS NUMERIC(18,2)))
	,	VrPremioLiquidoEndossoNovaProducao							= SUM(CAST(T1.VrPremioLiquidoEndossoNovaProducao AS NUMERIC(18,2)))
	,	VrPremioLiquidoApoliceRenovacao								= SUM(CAST(T1.VrPremioLiquidoApoliceRenovacao AS NUMERIC(18,2)))
	,	VrPremioLiquidoEndossoRenovacao								= SUM(CAST(T1.VrPremioLiquidoEndossoRenovacao AS NUMERIC(18,2)))
	,	VrPremioLiquidoTotal										= SUM(CAST(T1.VrPremioLiquidoTotal AS NUMERIC(18,2)))
	,	QtdeApoliceApoliceNovaProducao								= SUM(CAST(T1.QtdeApoliceApoliceNovaProducao AS INT))
	,	QtdeApoliceEndossoNovaProducao								= SUM(CAST(T1.QtdeApoliceEndossoNovaProducao AS INT))
	,	QtdeApoliceApoliceRenovacao									= SUM(CAST(T1.QtdeApoliceApoliceRenovacao AS INT))
	,	QtdeApoliceEndossoRenovacao									= SUM(CAST(T1.QtdeApoliceEndossoRenovacao AS INT))
	,	QtdeApoliceTotal											= SUM(CAST(T1.QtdeApoliceTotal AS INT))
	,	VrProjecaoIndividualPrimeiraSemana							= SUM(CAST(T1.VrProjecaoIndividualPrimeiraSemana AS NUMERIC(18,2)))
	,	VrProjecaoIndividualSemSegunda								= SUM(CAST(T1.VrProjecaoIndividualSemSegunda AS NUMERIC(18,2)))
	,	VrProjecaoIndividualComSegunda								= SUM(CAST(T1.VrProjecaoIndividualComSegunda AS NUMERIC(18,2)))
	,	VrProjecaoIndividual										= SUM(CAST(T1.VrProjecaoIndividual AS NUMERIC(18,2)))
	,	VrProjecaoCaminhao											= SUM(CAST(T1.VrProjecaoCaminhao AS NUMERIC(18,2)))
	,	VrProjecaoFrota												= SUM(CAST(T1.VrProjecaoFrota AS NUMERIC(18,2)))
	,	VrProjecaoLiquidoTotal										= SUM(CAST(T1.VrProjecaoLiquidoTotal AS NUMERIC(18,2)))
	---- Sintetico Cotacao
	,	VrPremioCotacaoRecusada										= SUM(CAST(T1.VrPremioCotacaoRecusada AS NUMERIC(18,2)))
	,	VrPremioCotacaoLiquida										= SUM(CAST(T1.VrPremioCotacaoLiquida AS NUMERIC(18,2)))
	,	VrPremioCotacaoTotal										= SUM(CAST(T1.VrPremioCotacaoTotal AS NUMERIC(18,2)))
	,	QtdeCotacaoRecusada											= SUM(CAST(T1.QtdeCotacaoRecusada AS INT))
	,	QtdeCotacaoLiquida											= SUM(CAST(T1.QtdeCotacaoLiquida AS INT))
	,	QtdeCotacaoTotal											= SUM(CAST(T1.QtdeCotacaoTotal AS INT))
	,	QtdeCotacaoEsforcoRecusada									= SUM(CAST(T1.QtdeCotacaoEsforcoRecusada AS INT))
	,	QtdeCotacaoEsforcoLiquida									= SUM(CAST(T1.QtdeCotacaoEsforcoLiquida AS INT))
	,	QtdeCotacaoEsforcoTotal										= SUM(CAST(T1.QtdeCotacaoEsforcoTotal AS INT))
	,	QtdeCotacaoEsforcoMulticalculoRecusada						= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoRecusada AS INT))
	,	QtdeCotacaoEsforcoMulticalculoLiquida						= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoLiquida AS INT))
	,	QtdeCotacaoEsforcoMulticalculoTotal							= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoTotal AS INT))
	,	QtdePropostaEmitida											= SUM(CAST(T1.QtdePropostaEmitida AS INT))
	,	QtdePropostaPendente										= SUM(CAST(T1.QtdePropostaPendente AS INT))
	,	QtdePropostaTotal											= SUM(CAST(T1.QtdePropostaTotal AS INT))
	,	QtdeCotacaoApoliceTotal										= SUM(CAST(T1.QtdeCotacaoApoliceTotal AS INT))
	-- =======================================================================================
	-- Mes Atual Ano Anterior (MesAtualAnoAnterior)
	---- Sintetico Premio
	,	VrPremioLiquidoApoliceNovaProducaoMesAtualAnoAnterior		= SUM(CAST(T1.VrPremioLiquidoApoliceNovaProducaoMesAtualAnoAnterior AS NUMERIC(18,2)))
	,	VrPremioLiquidoEndossoNovaProducaoMesAtualAnoAnterior		= SUM(CAST(T1.VrPremioLiquidoEndossoNovaProducaoMesAtualAnoAnterior AS NUMERIC(18,2)))
	,	VrPremioLiquidoApoliceRenovacaoMesAtualAnoAnterior			= SUM(CAST(T1.VrPremioLiquidoApoliceRenovacaoMesAtualAnoAnterior AS NUMERIC(18,2)))
	,	VrPremioLiquidoEndossoRenovacaoMesAtualAnoAnterior			= SUM(CAST(T1.VrPremioLiquidoEndossoRenovacaoMesAtualAnoAnterior AS NUMERIC(18,2)))
	,	VrPremioLiquidoTotalMesAtualAnoAnterior						= SUM(CAST(T1.VrPremioLiquidoTotalMesAtualAnoAnterior AS NUMERIC(18,2)))
	,	QtdeApoliceApoliceNovaProducaoMesAtualAnoAnterior			= SUM(CAST(T1.QtdeApoliceApoliceNovaProducaoMesAtualAnoAnterior AS INT))
	,	QtdeApoliceEndossoNovaProducaoMesAtualAnoAnterior			= SUM(CAST(T1.QtdeApoliceEndossoNovaProducaoMesAtualAnoAnterior AS INT))
	,	QtdeApoliceApoliceRenovacaoMesAtualAnoAnterior				= SUM(CAST(T1.QtdeApoliceApoliceRenovacaoMesAtualAnoAnterior AS INT))
	,	QtdeApoliceEndossoRenovacaoMesAtualAnoAnterior				= SUM(CAST(T1.QtdeApoliceEndossoRenovacaoMesAtualAnoAnterior AS INT))
	,	QtdeApoliceTotalMesAtualAnoAnterior							= SUM(CAST(T1.QtdeApoliceTotalMesAtualAnoAnterior AS INT))
	---- Sintetico Cotacao
	,	VrPremioCotacaoRecusadaMesAtualAnoAnterior					= SUM(CAST(T1.VrPremioCotacaoRecusadaMesAtualAnoAnterior AS NUMERIC(18,2)))
	,	VrPremioCotacaoLiquidaMesAtualAnoAnterior					= SUM(CAST(T1.VrPremioCotacaoLiquidaMesAtualAnoAnterior AS NUMERIC(18,2)))
	,	VrPremioCotacaoTotalMesAtualAnoAnterior						= SUM(CAST(T1.VrPremioCotacaoTotalMesAtualAnoAnterior AS NUMERIC(18,2)))
	,	QtdeCotacaoRecusadaMesAtualAnoAnterior						= SUM(CAST(T1.QtdeCotacaoRecusadaMesAtualAnoAnterior AS INT))
	,	QtdeCotacaoLiquidaMesAtualAnoAnterior						= SUM(CAST(T1.QtdeCotacaoLiquidaMesAtualAnoAnterior AS INT))
	,	QtdeCotacaoTotalMesAtualAnoAnterior							= SUM(CAST(T1.QtdeCotacaoTotalMesAtualAnoAnterior AS INT))
	,	QtdeCotacaoEsforcoRecusadaMesAtualAnoAnterior				= SUM(CAST(T1.QtdeCotacaoEsforcoRecusadaMesAtualAnoAnterior AS INT))
	,	QtdeCotacaoEsforcoLiquidaMesAtualAnoAnterior				= SUM(CAST(T1.QtdeCotacaoEsforcoLiquidaMesAtualAnoAnterior AS INT))
	,	QtdeCotacaoEsforcoTotalMesAtualAnoAnterior					= SUM(CAST(T1.QtdeCotacaoEsforcoTotalMesAtualAnoAnterior AS INT))
	,	QtdeCotacaoEsforcoMulticalculoRecusadaMesAtualAnoAnterior	= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoRecusadaMesAtualAnoAnterior AS INT))
	,	QtdeCotacaoEsforcoMulticalculoLiquidaMesAtualAnoAnterior	= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoLiquidaMesAtualAnoAnterior AS INT))
	,	QtdeCotacaoEsforcoMulticalculoTotalMesAtualAnoAnterior		= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoTotalMesAtualAnoAnterior AS INT))
	,	QtdePropostaEmitidaMesAtualAnoAnterior						= SUM(CAST(T1.QtdePropostaEmitidaMesAtualAnoAnterior AS INT))
	,	QtdePropostaPendenteMesAtualAnoAnterior						= SUM(CAST(T1.QtdePropostaPendenteMesAtualAnoAnterior AS INT))
	,	QtdePropostaTotalMesAtualAnoAnterior						= SUM(CAST(T1.QtdePropostaTotalMesAtualAnoAnterior AS INT))
	,	QtdeCotacaoApoliceTotalMesAtualAnoAnterior					= SUM(CAST(T1.QtdeCotacaoApoliceTotalMesAtualAnoAnterior AS INT))
	-- =======================================================================================
	-- Mes Anterior (MesAnterior)
	---- Sintetico Premio
	,	VrPremioLiquidoApoliceNovaProducaoMesAnterior				= SUM(CAST(T1.VrPremioLiquidoApoliceNovaProducaoMesAnterior AS NUMERIC(18,2)))
	,	VrPremioLiquidoEndossoNovaProducaoMesAnterior				= SUM(CAST(T1.VrPremioLiquidoEndossoNovaProducaoMesAnterior AS NUMERIC(18,2)))
	,	VrPremioLiquidoApoliceRenovacaoMesAnterior					= SUM(CAST(T1.VrPremioLiquidoApoliceRenovacaoMesAnterior AS NUMERIC(18,2)))
	,	VrPremioLiquidoEndossoRenovacaoMesAnterior					= SUM(CAST(T1.VrPremioLiquidoEndossoRenovacaoMesAnterior AS NUMERIC(18,2)))
	,	VrPremioLiquidoTotalMesAnterior								= SUM(CAST(T1.VrPremioLiquidoTotalMesAnterior AS NUMERIC(18,2)))
	,	QtdeApoliceApoliceNovaProducaoMesAnterior					= SUM(CAST(T1.QtdeApoliceApoliceNovaProducaoMesAnterior AS INT))
	,	QtdeApoliceEndossoNovaProducaoMesAnterior					= SUM(CAST(T1.QtdeApoliceEndossoNovaProducaoMesAnterior AS INT))
	,	QtdeApoliceApoliceRenovacaoMesAnterior						= SUM(CAST(T1.QtdeApoliceApoliceRenovacaoMesAnterior AS INT))
	,	QtdeApoliceEndossoRenovacaoMesAnterior						= SUM(CAST(T1.QtdeApoliceEndossoRenovacaoMesAnterior AS INT))
	,	QtdeApoliceTotalMesAnterior									= SUM(CAST(T1.QtdeApoliceTotalMesAnterior AS INT))
	---- Sintetico Cotacao
	,	VrPremioCotacaoRecusadaMesAnterior							= SUM(CAST(T1.VrPremioCotacaoRecusadaMesAnterior AS NUMERIC(18,2)))
	,	VrPremioCotacaoLiquidaMesAnterior							= SUM(CAST(T1.VrPremioCotacaoLiquidaMesAnterior AS NUMERIC(18,2)))
	,	VrPremioCotacaoTotalMesAnterior								= SUM(CAST(T1.VrPremioCotacaoTotalMesAnterior AS NUMERIC(18,2)))
	,	QtdeCotacaoRecusadaMesAnterior								= SUM(CAST(T1.QtdeCotacaoRecusadaMesAnterior AS INT))
	,	QtdeCotacaoLiquidaMesAnterior								= SUM(CAST(T1.QtdeCotacaoLiquidaMesAnterior AS INT))
	,	QtdeCotacaoTotalMesAnterior									= SUM(CAST(T1.QtdeCotacaoTotalMesAnterior AS INT))
	,	QtdeCotacaoEsforcoRecusadaMesAnterior						= SUM(CAST(T1.QtdeCotacaoEsforcoRecusadaMesAnterior AS INT))
	,	QtdeCotacaoEsforcoLiquidaMesAnterior						= SUM(CAST(T1.QtdeCotacaoEsforcoLiquidaMesAnterior AS INT))
	,	QtdeCotacaoEsforcoTotalMesAnterior							= SUM(CAST(T1.QtdeCotacaoEsforcoTotalMesAnterior AS INT))
	,	QtdeCotacaoEsforcoMulticalculoRecusadaMesAnterior			= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoRecusadaMesAnterior AS INT))
	,	QtdeCotacaoEsforcoMulticalculoLiquidaMesAnterior			= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoLiquidaMesAnterior AS INT))
	,	QtdeCotacaoEsforcoMulticalculoTotalMesAnterior				= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoTotalMesAnterior AS INT))
	,	QtdePropostaEmitidaMesAnterior								= SUM(CAST(T1.QtdePropostaEmitidaMesAnterior AS INT))
	,	QtdePropostaPendenteMesAnterior								= SUM(CAST(T1.QtdePropostaPendenteMesAnterior AS INT))
	,	QtdePropostaTotalMesAnterior								= SUM(CAST(T1.QtdePropostaTotalMesAnterior AS INT))
	,	QtdeCotacaoApoliceTotalMesAnterior							= SUM(CAST(T1.QtdeCotacaoApoliceTotalMesAnterior AS INT))
	-- =======================================================================================
	-- Mes Anterior Ano Anterior (MesAnteriorAnoAnterior)
	---- Sintetico Premio
	,	VrPremioLiquidoApoliceNovaProducaoMesAnteriorAnoAnterior		= SUM(CAST(T1.VrPremioLiquidoApoliceNovaProducaoMesAnteriorAnoAnterior AS NUMERIC(18,2)))
	,	VrPremioLiquidoEndossoNovaProducaoMesAnteriorAnoAnterior		= SUM(CAST(T1.VrPremioLiquidoEndossoNovaProducaoMesAnteriorAnoAnterior AS NUMERIC(18,2)))
	,	VrPremioLiquidoApoliceRenovacaoMesAnteriorAnoAnterior			= SUM(CAST(T1.VrPremioLiquidoApoliceRenovacaoMesAnteriorAnoAnterior AS NUMERIC(18,2)))
	,	VrPremioLiquidoEndossoRenovacaoMesAnteriorAnoAnterior			= SUM(CAST(T1.VrPremioLiquidoEndossoRenovacaoMesAnteriorAnoAnterior AS NUMERIC(18,2)))
	,	VrPremioLiquidoTotalMesAnteriorAnoAnterior						= SUM(CAST(T1.VrPremioLiquidoTotalMesAnteriorAnoAnterior AS NUMERIC(18,2)))
	,	QtdeApoliceApoliceNovaProducaoMesAnteriorAnoAnterior			= SUM(CAST(T1.QtdeApoliceApoliceNovaProducaoMesAnteriorAnoAnterior AS INT))
	,	QtdeApoliceEndossoNovaProducaoMesAnteriorAnoAnterior			= SUM(CAST(T1.QtdeApoliceEndossoNovaProducaoMesAnteriorAnoAnterior AS INT))
	,	QtdeApoliceApoliceRenovacaoMesAnteriorAnoAnterior				= SUM(CAST(T1.QtdeApoliceApoliceRenovacaoMesAnteriorAnoAnterior AS INT))
	,	QtdeApoliceEndossoRenovacaoMesAnteriorAnoAnterior				= SUM(CAST(T1.QtdeApoliceEndossoRenovacaoMesAnteriorAnoAnterior AS INT))
	,	QtdeApoliceTotalMesAnteriorAnoAnterior							= SUM(CAST(T1.QtdeApoliceTotalMesAnteriorAnoAnterior AS INT))
	---- Sintetico Cotacao
	,	VrPremioCotacaoRecusadaMesAnteriorAnoAnterior					= SUM(CAST(T1.VrPremioCotacaoRecusadaMesAnteriorAnoAnterior AS NUMERIC(18,2)))
	,	VrPremioCotacaoLiquidaMesAnteriorAnoAnterior					= SUM(CAST(T1.VrPremioCotacaoLiquidaMesAnteriorAnoAnterior AS NUMERIC(18,2)))
	,	VrPremioCotacaoTotalMesAnteriorAnoAnterior						= SUM(CAST(T1.VrPremioCotacaoTotalMesAnteriorAnoAnterior AS NUMERIC(18,2)))
	,	QtdeCotacaoRecusadaMesAnteriorAnoAnterior						= SUM(CAST(T1.QtdeCotacaoRecusadaMesAnteriorAnoAnterior AS INT))
	,	QtdeCotacaoLiquidaMesAnteriorAnoAnterior						= SUM(CAST(T1.QtdeCotacaoLiquidaMesAnteriorAnoAnterior AS INT))
	,	QtdeCotacaoTotalMesAnteriorAnoAnterior							= SUM(CAST(T1.QtdeCotacaoTotalMesAnteriorAnoAnterior AS INT))
	,	QtdeCotacaoEsforcoRecusadaMesAnteriorAnoAnterior				= SUM(CAST(T1.QtdeCotacaoEsforcoRecusadaMesAnteriorAnoAnterior AS INT))
	,	QtdeCotacaoEsforcoLiquidaMesAnteriorAnoAnterior					= SUM(CAST(T1.QtdeCotacaoEsforcoLiquidaMesAnteriorAnoAnterior AS INT))
	,	QtdeCotacaoEsforcoTotalMesAnteriorAnoAnterior					= SUM(CAST(T1.QtdeCotacaoEsforcoTotalMesAnteriorAnoAnterior AS INT))
	,	QtdeCotacaoEsforcoMulticalculoRecusadaMesAnteriorAnoAnterior	= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoRecusadaMesAnteriorAnoAnterior AS INT))
	,	QtdeCotacaoEsforcoMulticalculoLiquidaMesAnteriorAnoAnterior		= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoLiquidaMesAnteriorAnoAnterior AS INT))
	,	QtdeCotacaoEsforcoMulticalculoTotalMesAnteriorAnoAnterior		= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoTotalMesAnteriorAnoAnterior AS INT))
	,	QtdePropostaEmitidaMesAnteriorAnoAnterior						= SUM(CAST(T1.QtdePropostaEmitidaMesAnteriorAnoAnterior AS INT))
	,	QtdePropostaPendenteMesAnteriorAnoAnterior						= SUM(CAST(T1.QtdePropostaPendenteMesAnteriorAnoAnterior AS INT))
	,	QtdePropostaTotalMesAnteriorAnoAnterior							= SUM(CAST(T1.QtdePropostaTotalMesAnteriorAnoAnterior AS INT))
	,	QtdeCotacaoApoliceTotalMesAnteriorAnoAnterior					= SUM(CAST(T1.QtdeCotacaoApoliceTotalMesAnteriorAnoAnterior AS INT))
	-- =======================================================================================
	-- Ano Acumulado (De Jan at� M-1) (AnoAcumulado)
	---- Sintetico Premio
	,	VrPremioLiquidoApoliceNovaProducaoAnoAcumulado					= SUM(CAST(T1.VrPremioLiquidoApoliceNovaProducaoAnoAcumulado AS NUMERIC(18,2)))
	,	VrPremioLiquidoEndossoNovaProducaoAnoAcumulado					= SUM(CAST(T1.VrPremioLiquidoEndossoNovaProducaoAnoAcumulado AS NUMERIC(18,2)))
	,	VrPremioLiquidoApoliceRenovacaoAnoAcumulado						= SUM(CAST(T1.VrPremioLiquidoApoliceRenovacaoAnoAcumulado AS NUMERIC(18,2)))
	,	VrPremioLiquidoEndossoRenovacaoAnoAcumulado						= SUM(CAST(T1.VrPremioLiquidoEndossoRenovacaoAnoAcumulado AS NUMERIC(18,2)))
	,	VrPremioLiquidoTotalAnoAcumulado								= SUM(CAST(T1.VrPremioLiquidoTotalAnoAcumulado AS NUMERIC(18,2)))
	,	QtdeApoliceApoliceNovaProducaoAnoAcumulado						= SUM(CAST(T1.QtdeApoliceApoliceNovaProducaoAnoAcumulado AS INT))
	,	QtdeApoliceEndossoNovaProducaoAnoAcumulado						= SUM(CAST(T1.QtdeApoliceEndossoNovaProducaoAnoAcumulado AS INT))
	,	QtdeApoliceApoliceRenovacaoAnoAcumulado							= SUM(CAST(T1.QtdeApoliceApoliceRenovacaoAnoAcumulado AS INT))
	,	QtdeApoliceEndossoRenovacaoAnoAcumulado							= SUM(CAST(T1.QtdeApoliceEndossoRenovacaoAnoAcumulado AS INT))
	,	QtdeApoliceTotalAnoAcumulado									= SUM(CAST(T1.QtdeApoliceTotalAnoAcumulado AS INT))
	---- Sintetico Cotacao
	,	VrPremioCotacaoRecusadaAnoAcumulado								= SUM(CAST(T1.VrPremioCotacaoRecusadaAnoAcumulado AS NUMERIC(18,2)))
	,	VrPremioCotacaoLiquidaAnoAcumulado								= SUM(CAST(T1.VrPremioCotacaoLiquidaAnoAcumulado AS NUMERIC(18,2)))
	,	VrPremioCotacaoTotalAnoAcumulado								= SUM(CAST(T1.VrPremioCotacaoTotalAnoAcumulado AS NUMERIC(18,2)))
	,	QtdeCotacaoRecusadaAnoAcumulado									= SUM(CAST(T1.QtdeCotacaoRecusadaAnoAcumulado AS INT))
	,	QtdeCotacaoLiquidaAnoAcumulado									= SUM(CAST(T1.QtdeCotacaoLiquidaAnoAcumulado AS INT))
	,	QtdeCotacaoTotalAnoAcumulado									= SUM(CAST(T1.QtdeCotacaoTotalAnoAcumulado AS INT))
	,	QtdeCotacaoEsforcoRecusadaAnoAcumulado							= SUM(CAST(T1.QtdeCotacaoEsforcoRecusadaAnoAcumulado AS INT))
	,	QtdeCotacaoEsforcoLiquidaAnoAcumulado							= SUM(CAST(T1.QtdeCotacaoEsforcoLiquidaAnoAcumulado AS INT))
	,	QtdeCotacaoEsforcoTotalAnoAcumulado								= SUM(CAST(T1.QtdeCotacaoEsforcoTotalAnoAcumulado AS INT))
	,	QtdeCotacaoEsforcoMulticalculoRecusadaAnoAcumulado				= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoRecusadaAnoAcumulado AS INT))
	,	QtdeCotacaoEsforcoMulticalculoLiquidaAnoAcumulado				= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoLiquidaAnoAcumulado AS INT))
	,	QtdeCotacaoEsforcoMulticalculoTotalAnoAcumulado					= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoTotalAnoAcumulado AS INT))
	,	QtdePropostaEmitidaAnoAcumulado									= SUM(CAST(T1.QtdePropostaEmitidaAnoAcumulado AS INT))
	,	QtdePropostaPendenteAnoAcumulado								= SUM(CAST(T1.QtdePropostaPendenteAnoAcumulado AS INT))
	,	QtdePropostaTotalAnoAcumulado									= SUM(CAST(T1.QtdePropostaTotalAnoAcumulado AS INT))
	,	QtdeCotacaoApoliceTotalAnoAcumulado								= SUM(CAST(T1.QtdeCotacaoApoliceTotalAnoAcumulado AS INT))
	-- =======================================================================================
	-- Ano Anterior Acumulado (De Jan at� M-1) (AnoAnteriorAcumulado)
	---- Sintetico Premio
	,	VrPremioLiquidoApoliceNovaProducaoAnoAnteriorAcumulado			= SUM(CAST(T1.VrPremioLiquidoApoliceNovaProducaoAnoAnteriorAcumulado AS NUMERIC(18,2)))
	,	VrPremioLiquidoEndossoNovaProducaoAnoAnteriorAcumulado			= SUM(CAST(T1.VrPremioLiquidoEndossoNovaProducaoAnoAnteriorAcumulado AS NUMERIC(18,2)))
	,	VrPremioLiquidoApoliceRenovacaoAnoAnteriorAcumulado				= SUM(CAST(T1.VrPremioLiquidoApoliceRenovacaoAnoAnteriorAcumulado AS NUMERIC(18,2)))
	,	VrPremioLiquidoEndossoRenovacaoAnoAnteriorAcumulado				= SUM(CAST(T1.VrPremioLiquidoEndossoRenovacaoAnoAnteriorAcumulado AS NUMERIC(18,2)))
	,	VrPremioLiquidoTotalAnoAnteriorAcumulado						= SUM(CAST(T1.VrPremioLiquidoTotalAnoAnteriorAcumulado AS NUMERIC(18,2)))
	,	QtdeApoliceApoliceNovaProducaoAnoAnteriorAcumulado				= SUM(CAST(T1.QtdeApoliceApoliceNovaProducaoAnoAnteriorAcumulado AS INT))
	,	QtdeApoliceEndossoNovaProducaoAnoAnteriorAcumulado				= SUM(CAST(T1.QtdeApoliceEndossoNovaProducaoAnoAnteriorAcumulado AS INT))
	,	QtdeApoliceApoliceRenovacaoAnoAnteriorAcumulado					= SUM(CAST(T1.QtdeApoliceApoliceRenovacaoAnoAnteriorAcumulado AS INT))
	,	QtdeApoliceEndossoRenovacaoAnoAnteriorAcumulado					= SUM(CAST(T1.QtdeApoliceEndossoRenovacaoAnoAnteriorAcumulado AS INT))
	,	QtdeApoliceTotalAnoAnteriorAcumulado							= SUM(CAST(T1.QtdeApoliceTotalAnoAnteriorAcumulado AS INT))
	---- Sintetico Cotacao
	,	VrPremioCotacaoRecusadaAnoAnteriorAcumulado						= SUM(CAST(T1.VrPremioCotacaoRecusadaAnoAnteriorAcumulado AS NUMERIC(18,2)))
	,	VrPremioCotacaoLiquidaAnoAnteriorAcumulado						= SUM(CAST(T1.VrPremioCotacaoLiquidaAnoAnteriorAcumulado AS NUMERIC(18,2)))
	,	VrPremioCotacaoTotalAnoAnteriorAcumulado						= SUM(CAST(T1.VrPremioCotacaoTotalAnoAnteriorAcumulado AS NUMERIC(18,2)))
	,	QtdeCotacaoRecusadaAnoAnteriorAcumulado							= SUM(CAST(T1.QtdeCotacaoRecusadaAnoAnteriorAcumulado AS INT))
	,	QtdeCotacaoLiquidaAnoAnteriorAcumulado							= SUM(CAST(T1.QtdeCotacaoLiquidaAnoAnteriorAcumulado AS INT))
	,	QtdeCotacaoTotalAnoAnteriorAcumulado							= SUM(CAST(T1.QtdeCotacaoTotalAnoAnteriorAcumulado AS INT))
	,	QtdeCotacaoEsforcoRecusadaAnoAnteriorAcumulado					= SUM(CAST(T1.QtdeCotacaoEsforcoRecusadaAnoAnteriorAcumulado AS INT))
	,	QtdeCotacaoEsforcoLiquidaAnoAnteriorAcumulado					= SUM(CAST(T1.QtdeCotacaoEsforcoLiquidaAnoAnteriorAcumulado AS INT))
	,	QtdeCotacaoEsforcoTotalAnoAnteriorAcumulado						= SUM(CAST(T1.QtdeCotacaoEsforcoTotalAnoAnteriorAcumulado AS INT))
	,	QtdeCotacaoEsforcoMulticalculoRecusadaAnoAnteriorAcumulado		= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoRecusadaAnoAnteriorAcumulado AS INT))
	,	QtdeCotacaoEsforcoMulticalculoLiquidaAnoAnteriorAcumulado		= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoLiquidaAnoAnteriorAcumulado AS INT))
	,	QtdeCotacaoEsforcoMulticalculoTotalAnoAnteriorAcumulado			= SUM(CAST(T1.QtdeCotacaoEsforcoMulticalculoTotalAnoAnteriorAcumulado AS INT))
	,	QtdePropostaEmitidaAnoAnteriorAcumulado							= SUM(CAST(T1.QtdePropostaEmitidaAnoAnteriorAcumulado AS INT))
	,	QtdePropostaPendenteAnoAnteriorAcumulado						= SUM(CAST(T1.QtdePropostaPendenteAnoAnteriorAcumulado AS INT))
	,	QtdePropostaTotalAnoAnteriorAcumulado							= SUM(CAST(T1.QtdePropostaTotalAnoAnteriorAcumulado AS INT))
	,	QtdeCotacaoApoliceTotalAnoAnteriorAcumulado						= SUM(CAST(T1.QtdeCotacaoApoliceTotalAnoAnteriorAcumulado AS INT))
	-- =======================================================================================
	-- Valor do Orcado Mes Atual
	,	VrOrcado														= SUM(CAST(T1.VrOrcado AS NUMERIC(18,2)))
	,	VrOrcadoAnoAcumulado											= SUM(CAST(T1.VrOrcadoAnoAcumulado AS NUMERIC(18,2)))
	-- =======================================================================================
	-- Mes Atual: 
	---- Sintetico Renovacao
	,	QtdePolizaEsp													= SUM(CAST(QtdePolizaEsp AS INT))			-- Conceito: QTD Renova��es Esperadas
	,	QtdeOfertada													= SUM(CAST(QtdeOfertada AS INT))			-- Conceito: QTD Renova��es Ofertadas
	,	QtdePolizaRen													= SUM(CAST(QtdePolizaRen AS INT))			-- Conceito: QTD Renova��es Efetivadas
	,	QtdePolizaEspParcial											= SUM(CAST(QtdePolizaEspParcial AS INT))	-- Conceito: QTD Renova��es Esperadas
	,	QtdeOfertadaParcial												= SUM(CAST(QtdeOfertadaParcial AS INT))		-- Conceito: QTD Renova��es Ofertadas
	,	QtdePolizaRenParcial											= SUM(CAST(QtdePolizaRenParcial AS INT))	-- Conceito: QTD Renova��es Efetivadas
	-- =======================================================================================
	-- Mes Anterior (MesAnterior)
	---- Sintetico Renovacao
	,	QtdePolizaEspMesAnterior										= SUM(CAST(QtdePolizaEspMesAnterior AS INT))		-- Conceito: QTD Renova��es Esperadas
	,	QtdeOfertadaMesAnterior											= SUM(CAST(QtdeOfertadaMesAnterior AS INT))			-- Conceito: QTD Renova��es Ofertadas
	,	QtdePolizaRenMesAnterior										= SUM(CAST(QtdePolizaRenMesAnterior AS INT))		-- Conceito: QTD Renova��es Efetivadas
	-- =======================================================================================
	-- Calculando o Ticket Medio
	,	VrTicketMedio													= CAST('0.00' AS NUMERIC(18,2))
	,	QtdePropostaProjetado											= CAST('0' AS INT)
	,	IndiceConversaoReal												= CAST('0.00' AS NUMERIC(18,2))
	,	IndiceConversaoRecusadas										= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeCotacaoProposta												= CAST('0' AS INT)
	,	QtdeCotacaoAgravoRecusa											= CAST('0' AS INT)
	,	QtdeCotacaoProjetado											= CAST('0' AS INT)
	,	QtdeCotacaoProjetadoRelogio										= CAST('0' AS NUMERIC(18,4))
	,	QtdePropostaProjetadoRelogio									= CAST('0' AS NUMERIC(18,4))
	-- =======================================================================================
	-- Mes Atual: 
	---- Sintetico Renovacao
	,	ImpPrimaCarteraEsp												= SUM(CAST(T1.ImpPrimaCarteraEsp AS NUMERIC(18,2) ))
	,	ImpPrimaRenGarantizadaEsp										= SUM(CAST(T1.ImpPrimaRenGarantizadaEsp AS NUMERIC(18,2) ))
	,	ImpPrimaCarteraRen												= SUM(CAST(T1.ImpPrimaCarteraRen AS NUMERIC(18,2) ))

	into #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO_FINAL
	from #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO T1 WITH (NOLOCK)
	GROUP BY
		T1.DtReferencia
	,	T1.DtProcessamento
	,	T1.CodCorretor
	,	T1.NomeCorretor
	,	T1.RaizCpfCnpjCorretor
	,	T1.CodAssessor
	,	T1.NomeAssessor
	,	T1.CodSucursal
	,	T1.NomeSucursal
	,	T1.CodTerritorial
	,	T1.NomeTerritorial
	,	T1.CodCanal1 
	,	T1.DescricaoCanal1 
	,	T1.CodCanal2 
	,	T1.DescricaoCanal2 
	,	T1.CodCanal3 
	,	T1.DescricaoCanal3 
	,	T1.CodCanal4 
	,	T1.DescricaoCanal4 
	,	T1.TipoAtendimentoId
	,	T1.NomeAtendimento
	,	T1.NomeRamo
	,	T1.NomeSetor

	-- ====================================================================================================================================
	--
	--														PROJETADO DE PROPOSTA
	--
	-- ====================================================================================================================================

	-- ====================================================================================================================================
	-- CodAssessor: Calculo do Proposta Projetado
	-- 1
	DROP TABLE IF EXISTS #TMP_RDS_PROJETADO_COTACAO_PROPOSTA_ASSESSOR

	SELECT
		CodAssessor					= T1.CodAssessor
	,	NomeSetor					= T1.NomeSetor
	,	VrOrcado					= T1.VrOrcado
	,	QuantoFaltaNew				= T1.QuantoFaltaNew
	,	QuantoFalta					= T1.QuantoFalta
	,	VrPremio					= T1.VrPremio
	,	QtdeApoliceTotal			= T1.QtdeApoliceTotal
	,	VrTicketMedio				= CAST(CASE WHEN T1.QtdeApoliceTotal <= 0 THEN 0 ELSE T1.VrPremio / CAST(T1.QtdeApoliceTotal AS NUMERIC(18,2)) END AS NUMERIC(18,2))
	,	QtdeCotacaoLiquida			= T1.QtdeCotacaoLiquida
	,	QtdePropostaTotal			= T1.QtdePropostaTotal
	,	QtdeCotacaoRecusada			= T1.QtdeCotacaoRecusada
	,	QtdePropostaEmitida			= T1.QtdePropostaEmitida
	,	IndiceConversaoReal			= CAST(CASE WHEN T1.QtdeCotacaoLiquida > 0 THEN T1.QtdePropostaTotal / CAST(t1.QtdeCotacaoLiquida AS NUMERIC(18,2)) * 100 ELSE 0 END AS NUMERIC(18,2))
	,	IndiceConversaoRecusadas	= CAST(CASE WHEN T1.QtdeCotacaoRecusada > 0 THEN T1.QtdePropostaEmitida / CAST(t1.QtdeCotacaoRecusada AS NUMERIC(18,2)) * 100 ELSE 0 END AS NUMERIC(18,2))

	INTO #TMP_RDS_PROJETADO_COTACAO_PROPOSTA_ASSESSOR
	FROM
	(
		select 
			CodAssessor				= T1.CodAssessor
		,	NomeSetor				= T1.NomeSetor
		,	VrOrcado				= ISNULL(SUM(T1.VrOrcado), 0)
		,	QuantoFaltaNew			= ISNULL(SUM(T1.VrOrcado), 0) - ISNULL(SUM(T1.VrPremioLiquidoTotal), 0) - CASE WHEN SUM(T1.QtdePolizaRen) = 0 THEN 0 ELSE (SUM(CAST(T1.ImpPrimaCarteraRen AS NUMERIC(18,2))) / CAST(SUM(T1.QtdePolizaRen) AS NUMERIC(18,2))) * ((CAST(ISNULL(MAX(T2.IndiceRenovacaoProjetado), 0) AS FLOAT) / 100 * ISNULL(SUM(T1.QtdePolizaEsp), 0)) - ISNULL(SUM(T1.QtdePolizaRen), 0))END
		,	QuantoFalta				= ISNULL(CAST(CASE WHEN ISNULL(SUM(T1.VrPremioLiquidoTotal), 0) - ISNULL(SUM(T1.VrOrcado), 0) >= 0 THEN 0 ELSE ABS(ISNULL(SUM(T1.VrPremioLiquidoTotal), 0) - ISNULL(SUM(T1.VrOrcado), 0)) END AS NUMERIC(18,2)), 0)
		,	VrPremio				= SUM(CASE WHEN NomeSetor IN ('Caminhao', 'Individuais') THEN ISNULL(T1.VrPremioLiquidoApoliceNovaProducao, 0)  ELSE 0 END)
		,	QtdeApoliceTotal		= SUM(CASE WHEN NomeSetor IN ('Caminhao', 'Individuais') THEN ISNULL(T1.QtdeApoliceApoliceNovaProducao, 0) ELSE 0 END)
		,	VrTicketMedio			= CAST('0.00' AS NUMERIC(18,2))
		,	QtdeCotacaoLiquida		= ISNULL(SUM(T1.QtdeCotacaoLiquida), 0)
		,	QtdePropostaTotal		= ISNULL(SUM(T1.QtdePropostaTotal), 0)
		,	QtdeCotacaoRecusada		= ISNULL(SUM(T1.QtdeCotacaoRecusada), 0)
		,	QtdePropostaEmitida		= ISNULL(SUM(T1.QtdePropostaEmitida), 0)

		from #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO_FINAL T1
		LEFT JOIN IndiceProjetadoConversaoRenovacao T2 ON T1.CodTerritorial = T2.CodTerritorial and FORMAT(CONVERT(date, T1.DtReferencia), 'yyyyMM') = T2.AnoMes
		GROUP BY T1.NomeSetor, T1.CodAssessor
	) T1
	where t1.NomeSetor IN ('Caminhao', 'Individuais')

	-- ====================================================================================================================================
	-- CodSucursal: Calculo do Proposta Projetado
	-- 2
	DROP TABLE IF EXISTS #TMP_RDS_PROJETADO_COTACAO_PROPOSTA_SUCURSAL

	SELECT
		CodSucursal					= T1.CodSucursal
	,	NomeSetor					= T1.NomeSetor
	,	VrOrcado					= T1.VrOrcado
	,	QuantoFaltaNew				= T1.QuantoFaltaNew
	,	QuantoFalta					= T1.QuantoFalta
	,	VrPremio					= T1.VrPremio
	,	QtdeApoliceTotal			= T1.QtdeApoliceTotal
	,	VrTicketMedio				= CAST(CASE WHEN T1.QtdeApoliceTotal <= 0 THEN 0 ELSE T1.VrPremio / CAST(T1.QtdeApoliceTotal AS NUMERIC(18,2)) END AS NUMERIC(18,2))
	,	QtdeCotacaoLiquida			= T1.QtdeCotacaoLiquida
	,	QtdePropostaTotal			= T1.QtdePropostaTotal
	,	QtdeCotacaoRecusada			= T1.QtdeCotacaoRecusada
	,	QtdePropostaEmitida			= T1.QtdePropostaEmitida
	,	IndiceConversaoReal			= CAST(CASE WHEN T1.QtdeCotacaoLiquida > 0 THEN T1.QtdePropostaTotal / CAST(t1.QtdeCotacaoLiquida AS NUMERIC(18,2)) * 100 ELSE 0 END AS NUMERIC(18,2))
	,	IndiceConversaoRecusadas	= CAST(CASE WHEN T1.QtdeCotacaoRecusada > 0 THEN T1.QtdePropostaEmitida / CAST(t1.QtdeCotacaoRecusada AS NUMERIC(18,2)) * 100 ELSE 0 END AS NUMERIC(18,2))

	INTO #TMP_RDS_PROJETADO_COTACAO_PROPOSTA_SUCURSAL
	FROM
	(
		select 
			CodSucursal				= T1.CodSucursal
		,	NomeSetor				= T1.NomeSetor
		,	VrOrcado				= ISNULL(SUM(T1.VrOrcado), 0)
		,	QuantoFaltaNew			= ISNULL(SUM(T1.VrOrcado), 0) - ISNULL(SUM(T1.VrPremioLiquidoTotal), 0) - CASE WHEN SUM(T1.QtdePolizaRen) = 0 THEN 0 ELSE (SUM(CAST(T1.ImpPrimaCarteraRen AS NUMERIC(18,2))) / CAST(SUM(T1.QtdePolizaRen) AS NUMERIC(18,2))) * ((CAST(ISNULL(MAX(T2.IndiceRenovacaoProjetado), 0) AS FLOAT) / 100 * ISNULL(SUM(T1.QtdePolizaEsp), 0)) - ISNULL(SUM(T1.QtdePolizaRen), 0))END
		,	QuantoFalta				= ISNULL(CAST(CASE WHEN ISNULL(SUM(T1.VrPremioLiquidoTotal), 0) - ISNULL(SUM(T1.VrOrcado), 0) >= 0 THEN 0 ELSE ABS(ISNULL(SUM(T1.VrPremioLiquidoTotal), 0) - ISNULL(SUM(T1.VrOrcado), 0)) END AS NUMERIC(18,2)), 0)
		,	VrPremio				= SUM(CASE WHEN NomeSetor IN ('Caminhao', 'Individuais') THEN ISNULL(T1.VrPremioLiquidoApoliceNovaProducao, 0)  ELSE 0 END)
		,	QtdeApoliceTotal		= SUM(CASE WHEN NomeSetor IN ('Caminhao', 'Individuais') THEN ISNULL(T1.QtdeApoliceApoliceNovaProducao, 0) ELSE 0 END)
		,	VrTicketMedio			= CAST('0.00' AS NUMERIC(18,2))
		,	QtdeCotacaoLiquida		= ISNULL(SUM(T1.QtdeCotacaoLiquida), 0)
		,	QtdePropostaTotal		= ISNULL(SUM(T1.QtdePropostaTotal), 0)
		,	QtdeCotacaoRecusada		= ISNULL(SUM(T1.QtdeCotacaoRecusada), 0)
		,	QtdePropostaEmitida		= ISNULL(SUM(T1.QtdePropostaEmitida), 0)

		from #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO_FINAL T1
		LEFT JOIN IndiceProjetadoConversaoRenovacao T2 ON T1.CodTerritorial = T2.CodTerritorial and FORMAT(CONVERT(date, T1.DtReferencia), 'yyyyMM') = T2.AnoMes
		GROUP BY T1.NomeSetor, T1.CodSucursal
	) T1
	where t1.NomeSetor IN ('Caminhao', 'Individuais')

	-- ====================================================================================================================================
	-- CodTerritorial: Calculo do Proposta Projetado
	-- 3
	DROP TABLE IF EXISTS #TMP_RDS_PROJETADO_COTACAO_PROPOSTA_TERRITORIAL

	SELECT
		CodTerritorial				= T1.CodTerritorial
	,	NomeSetor					= T1.NomeSetor
	,	VrOrcado					= T1.VrOrcado
	,	QuantoFaltaNew				= T1.QuantoFaltaNew
	,	QuantoFalta					= T1.QuantoFalta
	,	VrPremio					= T1.VrPremio
	,	QtdeApoliceTotal			= T1.QtdeApoliceTotal
	,	VrTicketMedio				= CAST(CASE WHEN T1.QtdeApoliceTotal <= 0 THEN 0 ELSE T1.VrPremio / CAST(T1.QtdeApoliceTotal AS NUMERIC(18,2)) END AS NUMERIC(18,2))
	,	QtdeCotacaoLiquida			= T1.QtdeCotacaoLiquida
	,	QtdePropostaTotal			= T1.QtdePropostaTotal
	,	QtdeCotacaoRecusada			= T1.QtdeCotacaoRecusada
	,	QtdePropostaEmitida			= T1.QtdePropostaEmitida
	,	IndiceConversaoReal			= CAST(CASE WHEN T1.QtdeCotacaoLiquida > 0 THEN T1.QtdePropostaTotal / CAST(t1.QtdeCotacaoLiquida AS NUMERIC(18,2)) * 100 ELSE 0 END AS NUMERIC(18,2))
	,	IndiceConversaoRecusadas	= CAST(CASE WHEN T1.QtdeCotacaoRecusada > 0 THEN T1.QtdePropostaEmitida / CAST(t1.QtdeCotacaoRecusada AS NUMERIC(18,2)) * 100 ELSE 0 END AS NUMERIC(18,2))

	INTO #TMP_RDS_PROJETADO_COTACAO_PROPOSTA_TERRITORIAL
	FROM
	(
		select 
			CodTerritorial			= T1.CodTerritorial
		,	NomeSetor				= T1.NomeSetor
		,	VrOrcado				= ISNULL(SUM(T1.VrOrcado), 0)
		,	QuantoFaltaNew			= ISNULL(SUM(T1.VrOrcado), 0) - ISNULL(SUM(T1.VrPremioLiquidoTotal), 0) - CASE WHEN SUM(T1.QtdePolizaRen) = 0 THEN 0 ELSE (SUM(CAST(T1.ImpPrimaCarteraRen AS NUMERIC(18,2))) / CAST(SUM(T1.QtdePolizaRen) AS NUMERIC(18,2))) * ((CAST(ISNULL(MAX(T2.IndiceRenovacaoProjetado), 0) AS FLOAT) / 100 * ISNULL(SUM(T1.QtdePolizaEsp), 0)) - ISNULL(SUM(T1.QtdePolizaRen), 0))END
		,	QuantoFalta				= ISNULL(CAST(CASE WHEN ISNULL(SUM(T1.VrPremioLiquidoTotal), 0) - ISNULL(SUM(T1.VrOrcado), 0) >= 0 THEN 0 ELSE ABS(ISNULL(SUM(T1.VrPremioLiquidoTotal), 0) - ISNULL(SUM(T1.VrOrcado), 0)) END AS NUMERIC(18,2)), 0)
		,	VrPremio				= SUM(CASE WHEN NomeSetor IN ('Caminhao', 'Individuais') THEN ISNULL(T1.VrPremioLiquidoApoliceNovaProducao, 0) ELSE 0 END)
		,	QtdeApoliceTotal		= SUM(CASE WHEN NomeSetor IN ('Caminhao', 'Individuais') THEN ISNULL(T1.QtdeApoliceApoliceNovaProducao, 0)  ELSE 0 END)
		,	VrTicketMedio			= CAST('0.00' AS NUMERIC(18,2))
		,	QtdeCotacaoLiquida		= ISNULL(SUM(T1.QtdeCotacaoLiquida), 0)
		,	QtdePropostaTotal		= ISNULL(SUM(T1.QtdePropostaTotal), 0)
		,	QtdeCotacaoRecusada		= ISNULL(SUM(T1.QtdeCotacaoRecusada), 0)
		,	QtdePropostaEmitida		= ISNULL(SUM(T1.QtdePropostaEmitida), 0)

		from #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO_FINAL T1
		LEFT JOIN IndiceProjetadoConversaoRenovacao T2 ON T1.CodTerritorial = T2.CodTerritorial and FORMAT(CONVERT(date, T1.DtReferencia), 'yyyyMM') = T2.AnoMes
		GROUP BY T1.NomeSetor, T1.CodTerritorial
	) T1
	where t1.NomeSetor IN ('Caminhao', 'Individuais')


	-- ====================================================================================================================================
	-- Corretor: Calculo do Proposta Projetado
	-- 4
	DROP TABLE IF EXISTS #TMP_RDS_PROJETADO_COTACAO_PROPOSTA

	SELECT
		CodCorretor					= T1.CodCorretor
	,	CodAssessor					= T1.CodAssessor
	,	CodSucursal					= T1.CodSucursal
	,	CodTerritorial				= T1.CodTerritorial
	,	NomeSetor					= T1.NomeSetor
	,	QtdeCotacaoLiquida			= T1.QtdeCotacaoLiquida
	,	QtdeCotacaoRecusada			= t1.QtdeCotacaoRecusada
	,	QtdeCotacaoTotal			= t1.QtdeCotacaoTotal
	,	QtdePropostaEmitida			= t1.QtdePropostaEmitida
	,	QtdePropostaTotal			= t1.QtdePropostaTotal
	,	VrOrcado					= T1.VrOrcado
	,	QuantoFaltaNew				= T1.QuantoFaltaNew
	,	QuantoFalta					= T1.QuantoFalta
	,	VrPremio					= T1.VrPremio
	,	QtdeApoliceTotal			= T1.QtdeApoliceTotal
	,	VrTicketMedio				= CAST(CASE WHEN T1.QtdeApoliceTotal <= 0 THEN 0 ELSE T1.VrPremio / CAST(T1.QtdeApoliceTotal AS NUMERIC(18,2)) END AS NUMERIC(18,2))
	,	QtdePropostaProjetado		= CAST('0' AS INT)
	,	IndiceConversaoReal			= CAST('0.00' AS NUMERIC(18,2))
	,	IndiceConversaoRecusadas	= CAST('0.00' AS NUMERIC(18,2))
	,	QtdeCotacaoProposta			= CAST('0' AS INT)
	,	QtdeCotacaoAgravoRecusa		= CAST('0' AS INT)
	,	QtdeCotacaoProjetado		= CAST('0' AS INT)
	,	QtdeCotacaoProjetadoRelogio	= CAST('0' AS NUMERIC(18,4))
	,	QtdePropostaProjetadoRelogio = CAST('0' AS NUMERIC(18,4))

	INTO #TMP_RDS_PROJETADO_COTACAO_PROPOSTA
	FROM
	(
		select 
			CodCorretor				= T1.CodCorretor
		,	CodAssessor				= T1.CodAssessor
		,	CodSucursal				= T1.CodSucursal
		,	CodTerritorial			= T1.CodTerritorial
		,	NomeSetor				= T1.NomeSetor
		,	QtdeCotacaoLiquida		= sum(T1.QtdeCotacaoLiquida)
		,	QtdeCotacaoRecusada		= sum(t1.QtdeCotacaoRecusada)
		,	QtdeCotacaoTotal		= sum(t1.QtdeCotacaoTotal)
		,	QtdePropostaEmitida		= sum(t1.QtdePropostaEmitida)
		,	QtdePropostaTotal		= sum(t1.QtdePropostaTotal)
		,	VrOrcado				= ISNULL(SUM(T1.VrOrcado), 0)
		,	QuantoFaltaNew			= ISNULL(SUM(T1.VrOrcado), 0) - ISNULL(SUM(T1.VrPremioLiquidoTotal), 0) - CASE WHEN SUM(T1.QtdePolizaRen) = 0 THEN 0 ELSE (SUM(CAST(T1.ImpPrimaCarteraRen AS NUMERIC(18,2))) / CAST(SUM(T1.QtdePolizaRen) AS NUMERIC(18,2))) * ((CAST(ISNULL(MAX(T2.IndiceRenovacaoProjetado), 0) AS FLOAT) / 100 * ISNULL(SUM(T1.QtdePolizaEsp), 0)) - ISNULL(SUM(T1.QtdePolizaRen), 0))END
		--,	QuantoFalta				= ISNULL(CAST(CASE WHEN ISNULL(SUM(T1.VrPremioLiquidoTotal), 0) - ISNULL(SUM(T1.VrOrcado), 0) >= 0 THEN 0 ELSE ABS(ISNULL(SUM(T1.VrPremioLiquidoTotal), 0) - ISNULL(SUM(T1.VrOrcado), 0)) END AS NUMERIC(18,2)), 0)
		,	QuantoFalta				= CAST(ISNULL(SUM(T1.VrOrcado), 0) - ISNULL(SUM(T1.VrPremioLiquidoTotal), 0) AS NUMERIC(18,2))
		--,	VrPremio				= SUM(CASE WHEN NomeSetor IN ('Caminhao', 'Individuais') THEN ISNULL(T1.VrPremioLiquidoApoliceNovaProducao, 0) + ISNULL(T1.VrPremioLiquidoApoliceRenovacao, 0) ELSE 0 END)
		,	VrPremio				= SUM(CASE WHEN NomeSetor IN ('Caminhao', 'Individuais') THEN ISNULL(T1.VrPremioLiquidoApoliceNovaProducao, 0) ELSE 0 END)
		--,	QtdeApoliceTotal		= SUM(CASE WHEN NomeSetor IN ('Caminhao', 'Individuais') THEN ISNULL(T1.QtdeApoliceApoliceNovaProducao, 0) + ISNULL(T1.QtdeApoliceApoliceRenovacao, 0) ELSE 0 END)
		,	QtdeApoliceTotal		= SUM(CASE WHEN NomeSetor IN ('Caminhao', 'Individuais') THEN ISNULL(T1.QtdeApoliceApoliceNovaProducao, 0) ELSE 0 END)
		,	VrTicketMedio			= CAST('0.00' AS NUMERIC(18,2))

		from #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO_FINAL T1
		LEFT JOIN IndiceProjetadoConversaoRenovacao T2 ON T1.CodTerritorial = T2.CodTerritorial and FORMAT(CONVERT(date, T1.DtReferencia), 'yyyyMM') = T2.AnoMes
		GROUP BY T1.CodCorretor, T1.NomeSetor, T1.CodAssessor, T1.CodSucursal, T1.CodTerritorial
	) T1
	where t1.NomeSetor IN ('Caminhao', 'Individuais')
	-- ====================================================================================================================================
	-- Atualizando o Ticket (Assessor)

	UPDATE T1
	SET T1.VrTicketMedio = T2.VrTicketMedio
	FROM #TMP_RDS_PROJETADO_COTACAO_PROPOSTA T1
	INNER JOIN #TMP_RDS_PROJETADO_COTACAO_PROPOSTA_ASSESSOR T2 ON T1.CodAssessor = T2.CodAssessor AND T1.NomeSetor = T2.NomeSetor
	WHERE T1.VrTicketMedio = 0

	-- ====================================================================================================================================
	-- Atualizando o Ticket (Sucursal)

	UPDATE T1
	SET T1.VrTicketMedio = T2.VrTicketMedio
	FROM #TMP_RDS_PROJETADO_COTACAO_PROPOSTA T1
	INNER JOIN #TMP_RDS_PROJETADO_COTACAO_PROPOSTA_SUCURSAL T2 ON T1.CodSucursal = T2.CodSucursal AND T1.NomeSetor = T2.NomeSetor
	WHERE T1.VrTicketMedio = 0

	-- ====================================================================================================================================
	-- Atualizando o Ticket (Territorial)

	UPDATE T1
	SET T1.VrTicketMedio = T2.VrTicketMedio
	FROM #TMP_RDS_PROJETADO_COTACAO_PROPOSTA T1
	INNER JOIN #TMP_RDS_PROJETADO_COTACAO_PROPOSTA_TERRITORIAL T2 ON T1.CodTerritorial = T2.CodTerritorial AND T1.NomeSetor = T2.NomeSetor
	WHERE T1.VrTicketMedio = 0

	-- ====================================================================================================================================
	-- 1-PASSO: ATUALIZANDO O CALCULO DE PROPOSTA PROJETADO (incluir recusas e conversao dos superiores)
	-- Calculo por QuantoFalta
	--UPDATE T1
	--SET T1.QtdePropostaProjetado = CAST(CAST(CASE WHEN VrTicketMedio <= 0 THEN 0 ELSE QuantoFalta / VrTicketMedio END AS NUMERIC(18,0)) AS INT)
	--,	T1.IndiceConversaoReal = CAST(CASE WHEN T1.QtdeCotacaoLiquida > 0 THEN T1.QtdePropostaTotal / CAST(t1.QtdeCotacaoLiquida AS NUMERIC(18,2)) * 100 ELSE 0 END AS NUMERIC(18,2)) 
	--,	T1.IndiceConversaoRecusadas = CAST(CASE WHEN T1.QtdeCotacaoRecusada > 0 THEN T1.QtdePropostaEmitida / CAST(t1.QtdeCotacaoRecusada AS NUMERIC(18,2)) * 100 ELSE 0 END AS NUMERIC(18,2)) 

	--FROM #TMP_RDS_PROJETADO_COTACAO_PROPOSTA T1

	-- Calculo por QuantoFaltaNew
	UPDATE T1
	SET T1.QtdePropostaProjetado	= CAST(CAST(CASE WHEN VrTicketMedio <= 0 THEN 0 ELSE QuantoFaltaNew / VrTicketMedio END AS NUMERIC(18,0)) AS INT)
	,	T1.IndiceConversaoReal		= CAST(CASE WHEN T1.QtdeCotacaoLiquida > 0 THEN T1.QtdePropostaTotal / CAST(t1.QtdeCotacaoLiquida AS NUMERIC(18,2)) * 100 ELSE 0 END AS NUMERIC(18,2)) 
	,	T1.IndiceConversaoRecusadas = CAST(CASE WHEN T1.QtdeCotacaoRecusada > 0 THEN T1.QtdePropostaEmitida / CAST(t1.QtdeCotacaoRecusada AS NUMERIC(18,2)) * 100 ELSE 0 END AS NUMERIC(18,2)) 

	FROM #TMP_RDS_PROJETADO_COTACAO_PROPOSTA T1
	-- ====================================================================================================================================
	-- Atualizando o IndiceConversaoReal (Assessor)

	UPDATE T1
	SET T1.IndiceConversaoReal = T2.IndiceConversaoReal
	FROM #TMP_RDS_PROJETADO_COTACAO_PROPOSTA T1
	INNER JOIN #TMP_RDS_PROJETADO_COTACAO_PROPOSTA_ASSESSOR T2 ON T1.CodAssessor = T2.CodAssessor AND T1.NomeSetor = T2.NomeSetor
	WHERE T1.IndiceConversaoReal = 0

	-- ====================================================================================================================================
	-- Atualizando o IndiceConversaoReal (Sucursal)

	UPDATE T1
	SET T1.IndiceConversaoReal = T2.IndiceConversaoReal
	FROM #TMP_RDS_PROJETADO_COTACAO_PROPOSTA T1
	INNER JOIN #TMP_RDS_PROJETADO_COTACAO_PROPOSTA_SUCURSAL T2 ON T1.CodSucursal = T2.CodSucursal AND T1.NomeSetor = T2.NomeSetor
	WHERE T1.IndiceConversaoReal = 0

	-- ====================================================================================================================================
	-- Atualizando o IndiceConversaoReal (Territorial)

	UPDATE T1
	SET T1.IndiceConversaoReal = T2.IndiceConversaoReal
	FROM #TMP_RDS_PROJETADO_COTACAO_PROPOSTA T1
	INNER JOIN #TMP_RDS_PROJETADO_COTACAO_PROPOSTA_TERRITORIAL T2 ON T1.CodTerritorial = T2.CodTerritorial AND T1.NomeSetor = T2.NomeSetor
	WHERE T1.IndiceConversaoReal = 0

	-- ====================================================================================================================================
	-- Atualizando o IndiceConversaoRecusadas (Assessor)

	UPDATE T1
	SET T1.IndiceConversaoRecusadas = T2.IndiceConversaoRecusadas
	FROM #TMP_RDS_PROJETADO_COTACAO_PROPOSTA T1
	INNER JOIN #TMP_RDS_PROJETADO_COTACAO_PROPOSTA_ASSESSOR T2 ON T1.CodAssessor = T2.CodAssessor AND T1.NomeSetor = T2.NomeSetor
	WHERE T1.IndiceConversaoRecusadas = 0

	-- ====================================================================================================================================
	-- Atualizando o IndiceConversaoRecusadas (Sucursal)

	UPDATE T1
	SET T1.IndiceConversaoRecusadas = T2.IndiceConversaoRecusadas
	FROM #TMP_RDS_PROJETADO_COTACAO_PROPOSTA T1
	INNER JOIN #TMP_RDS_PROJETADO_COTACAO_PROPOSTA_SUCURSAL T2 ON T1.CodSucursal = T2.CodSucursal AND T1.NomeSetor = T2.NomeSetor
	WHERE T1.IndiceConversaoRecusadas = 0

	-- ====================================================================================================================================
	-- Atualizando o IndiceConversaoRecusadas (Territorial)

	UPDATE T1
	SET T1.IndiceConversaoRecusadas = T2.IndiceConversaoRecusadas
	FROM #TMP_RDS_PROJETADO_COTACAO_PROPOSTA T1
	INNER JOIN #TMP_RDS_PROJETADO_COTACAO_PROPOSTA_TERRITORIAL T2 ON T1.CodTerritorial = T2.CodTerritorial AND T1.NomeSetor = T2.NomeSetor
	WHERE T1.IndiceConversaoRecusadas = 0

	-- ====================================================================================================================================
	-- 2-PASSO: ATUALIZANDO O CALCULO DE PROPOSTA PROJETADO

	UPDATE T1
	SET T1.QtdeCotacaoProposta	= CAST(CAST(CASE WHEN (T1.IndiceConversaoReal / 100) <= 0 THEN 0 ELSE t1.QtdePropostaProjetado / (T1.IndiceConversaoReal / 100) END AS NUMERIC(18,0)) AS INT)

	FROM #TMP_RDS_PROJETADO_COTACAO_PROPOSTA T1

	-- ====================================================================================================================================
	-- 3-PASSO: ATUALIZANDO O CALCULO DE PROPOSTA PROJETADO

	UPDATE T1
	SET T1.QtdeCotacaoAgravoRecusa = CAST(CAST(t1.QtdeCotacaoProposta * (T1.IndiceConversaoRecusadas / 100) AS NUMERIC(18,0) ) AS INT)
	,	T1.QtdeCotacaoProjetado = CAST(CAST(t1.QtdeCotacaoProposta * (T1.IndiceConversaoRecusadas / 100) AS NUMERIC(18,0) ) AS INT) + QtdeCotacaoProposta

	FROM #TMP_RDS_PROJETADO_COTACAO_PROPOSTA T1

	-- ====================================================================================================================================
	-- 4-PASSO: ATUALIZANDO O CALCULO DE PROPOSTA PROJETADO

	UPDATE T1
	SET T1.QtdeCotacaoProjetadoRelogio = case when @TotalDiasUteis = 0 then 0 else (CAST(QtdeCotacaoProjetado AS NUMERIC(18,2)) / @TotalDiasUteis) * @DiasUteisSemFDS end
	,	T1.QtdePropostaProjetadoRelogio = case when @TotalDiasUteis = 0 then 0 else (CAST(QtdePropostaProjetado AS NUMERIC(18,2)) / @TotalDiasUteis) * @DiasUteisSemFDS end

	FROM #TMP_RDS_PROJETADO_COTACAO_PROPOSTA T1	

	-- ====================================================================================================================================
	-- ATUALIZANDO A TEMPORARIA PRINCIPAL

	UPDATE T1
	SET T1.VrTicketMedio = T2.VrTicketMedio
	,	T1.QtdePropostaProjetado = T2.QtdePropostaProjetado
	,	T1.IndiceConversaoReal	= T2.IndiceConversaoReal
	,	T1.IndiceConversaoRecusadas = T2.IndiceConversaoRecusadas
	,	T1.QtdeCotacaoProposta	= T2.QtdeCotacaoProposta
	,	T1.QtdeCotacaoProjetado = T2.QtdeCotacaoProjetado
	,	T1.QtdeCotacaoProjetadoRelogio = T2.QtdeCotacaoProjetadoRelogio
	,	T1.QtdePropostaProjetadoRelogio = T2.QtdePropostaProjetadoRelogio
	--,	T1.IndiceConversaoReal = T2.IndiceConversaoReal
	--,	T1.IndiceConversaoRecusadas = T2.IndiceConversaoRecusadas

	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO_FINAL T1
	INNER JOIN #TMP_RDS_PROJETADO_COTACAO_PROPOSTA T2 ON T1.CodCorretor = T2.CodCorretor AND T1.NomeSetor = T2.NomeSetor

	-- ====================================================================================================================================
	--
	--														CARREGANDO A BASE FINAL
	--
	-- ====================================================================================================================================

	-- ====================================================================================================================================
	-- Delete a base


	WHILE (1=1)
	BEGIN
    
		DELETE TOP(10000)
		FROM dbo.IndicadorAtingimentoPremioLiquidoAuto_20250417
		WHERE DtReferencia = @FirstDayOfMonth

		SET @Qt_Linhas = @@ROWCOUNT
		SET @Total_Linhas = @Total_Linhas + @Qt_Linhas

		IF (@Qt_Linhas = 0)
			BREAK

		SET @Msg = CONCAT('Quantidade de Linhas Apagadas: ', @Qt_Linhas, ' - Total Deletado: ', @Total_Linhas)
		RAISERROR(@Msg, 1, 1) WITH NOWAIT

	END

	-- ====================================================================================================================================
	-- Insert a base

	INSERT INTO dbo.IndicadorAtingimentoPremioLiquidoAuto
	(
		DtReferencia
	,	DtProcessamento
	,	CodCorretor
	,	NomeCorretor
	,	RaizCpfCnpjCorretor
	,	CodAssessor
	,	NomeAssessor
	,	CodSucursal
	,	NomeSucursal
	,	CodTerritorial
	,	NomeTerritorial
	,	CodCanal1
	,	DescricaoCanal1
	,	CodCanal2
	,	DescricaoCanal2
	,	CodCanal3
	,	DescricaoCanal3
	,	CodCanal4
	,	DescricaoCanal4
	,	TipoAtendimentoId
	,	NomeAtendimento
	,	NomeRamo
	,	NomeSetor
	,	
	,	VrPremioLiquidoApoliceNovaProducao
	,	VrPremioLiquidoEndossoNovaProducao
	,	VrPremioLiquidoApoliceRenovacao
	,	VrPremioLiquidoEndossoRenovacao
	,	VrPremioLiquidoTotal
	,	QtdeApoliceApoliceNovaProducao
	,	QtdeApoliceEndossoNovaProducao
	,	QtdeApoliceApoliceRenovacao
	,	QtdeApoliceEndossoRenovacao
	,	QtdeApoliceTotal
	,	VrProjecaoIndividualPrimeiraSemana
	,	VrProjecaoIndividualSemSegunda
	,	VrProjecaoIndividualComSegunda
	,	VrProjecaoIndividual
	,	VrProjecaoCaminhao
	,	VrProjecaoFrota
	,	VrProjecaoLiquidoTotal
	,	VrPremioCotacaoRecusada
	,	VrPremioCotacaoLiquida
	,	VrPremioCotacaoTotal
	,	QtdeCotacaoRecusada
	,	QtdeCotacaoLiquida
	,	QtdeCotacaoTotal
	,	QtdeCotacaoEsforcoRecusada
	,	QtdeCotacaoEsforcoLiquida
	,	QtdeCotacaoEsforcoTotal
	,	QtdeCotacaoEsforcoMulticalculoRecusada
	,	QtdeCotacaoEsforcoMulticalculoLiquida
	,	QtdeCotacaoEsforcoMulticalculoTotal
	,	QtdePropostaEmitida
	,	QtdePropostaPendente
	,	QtdePropostaTotal
	,	QtdeCotacaoApoliceTotal
	,	VrPremioLiquidoApoliceNovaProducaoMesAtualAnoAnterior
	,	VrPremioLiquidoEndossoNovaProducaoMesAtualAnoAnterior
	,	VrPremioLiquidoApoliceRenovacaoMesAtualAnoAnterior
	,	VrPremioLiquidoEndossoRenovacaoMesAtualAnoAnterior
	,	VrPremioLiquidoTotalMesAtualAnoAnterior
	,	QtdeApoliceApoliceNovaProducaoMesAtualAnoAnterior
	,	QtdeApoliceEndossoNovaProducaoMesAtualAnoAnterior
	,	QtdeApoliceApoliceRenovacaoMesAtualAnoAnterior
	,	QtdeApoliceEndossoRenovacaoMesAtualAnoAnterior
	,	QtdeApoliceTotalMesAtualAnoAnterior
	,	VrPremioCotacaoRecusadaMesAtualAnoAnterior
	,	VrPremioCotacaoLiquidaMesAtualAnoAnterior
	,	VrPremioCotacaoTotalMesAtualAnoAnterior
	,	QtdeCotacaoRecusadaMesAtualAnoAnterior
	,	QtdeCotacaoLiquidaMesAtualAnoAnterior
	,	QtdeCotacaoTotalMesAtualAnoAnterior
	,	QtdeCotacaoEsforcoRecusadaMesAtualAnoAnterior
	,	QtdeCotacaoEsforcoLiquidaMesAtualAnoAnterior
	,	QtdeCotacaoEsforcoTotalMesAtualAnoAnterior
	,	QtdeCotacaoEsforcoMulticalculoRecusadaMesAtualAnoAnterior
	,	QtdeCotacaoEsforcoMulticalculoLiquidaMesAtualAnoAnterior
	,	QtdeCotacaoEsforcoMulticalculoTotalMesAtualAnoAnterior
	,	QtdePropostaEmitidaMesAtualAnoAnterior
	,	QtdePropostaPendenteMesAtualAnoAnterior
	,	QtdePropostaTotalMesAtualAnoAnterior
	,	QtdeCotacaoApoliceTotalMesAtualAnoAnterior
	,	VrPremioLiquidoApoliceNovaProducaoMesAnterior
	,	VrPremioLiquidoEndossoNovaProducaoMesAnterior
	,	VrPremioLiquidoApoliceRenovacaoMesAnterior
	,	VrPremioLiquidoEndossoRenovacaoMesAnterior
	,	VrPremioLiquidoTotalMesAnterior
	,	QtdeApoliceApoliceNovaProducaoMesAnterior
	,	QtdeApoliceEndossoNovaProducaoMesAnterior
	,	QtdeApoliceApoliceRenovacaoMesAnterior
	,	QtdeApoliceEndossoRenovacaoMesAnterior
	,	QtdeApoliceTotalMesAnterior
	,	VrPremioCotacaoRecusadaMesAnterior
	,	VrPremioCotacaoLiquidaMesAnterior
	,	VrPremioCotacaoTotalMesAnterior
	,	QtdeCotacaoRecusadaMesAnterior
	,	QtdeCotacaoLiquidaMesAnterior
	,	QtdeCotacaoTotalMesAnterior
	,	QtdeCotacaoEsforcoRecusadaMesAnterior
	,	QtdeCotacaoEsforcoLiquidaMesAnterior
	,	QtdeCotacaoEsforcoTotalMesAnterior
	,	QtdeCotacaoEsforcoMulticalculoRecusadaMesAnterior
	,	QtdeCotacaoEsforcoMulticalculoLiquidaMesAnterior
	,	QtdeCotacaoEsforcoMulticalculoTotalMesAnterior
	,	QtdePropostaEmitidaMesAnterior
	,	QtdePropostaPendenteMesAnterior
	,	QtdePropostaTotalMesAnterior
	,	QtdeCotacaoApoliceTotalMesAnterior
	,	VrPremioLiquidoApoliceNovaProducaoMesAnteriorAnoAnterior
	,	VrPremioLiquidoEndossoNovaProducaoMesAnteriorAnoAnterior
	,	VrPremioLiquidoApoliceRenovacaoMesAnteriorAnoAnterior
	,	VrPremioLiquidoEndossoRenovacaoMesAnteriorAnoAnterior
	,	VrPremioLiquidoTotalMesAnteriorAnoAnterior
	,	QtdeApoliceApoliceNovaProducaoMesAnteriorAnoAnterior
	,	QtdeApoliceEndossoNovaProducaoMesAnteriorAnoAnterior
	,	QtdeApoliceApoliceRenovacaoMesAnteriorAnoAnterior
	,	QtdeApoliceEndossoRenovacaoMesAnteriorAnoAnterior
	,	QtdeApoliceTotalMesAnteriorAnoAnterior
	,	VrPremioCotacaoRecusadaMesAnteriorAnoAnterior
	,	VrPremioCotacaoLiquidaMesAnteriorAnoAnterior
	,	VrPremioCotacaoTotalMesAnteriorAnoAnterior
	,	QtdeCotacaoRecusadaMesAnteriorAnoAnterior
	,	QtdeCotacaoLiquidaMesAnteriorAnoAnterior
	,	QtdeCotacaoTotalMesAnteriorAnoAnterior
	,	QtdeCotacaoEsforcoRecusadaMesAnteriorAnoAnterior
	,	QtdeCotacaoEsforcoLiquidaMesAnteriorAnoAnterior
	,	QtdeCotacaoEsforcoTotalMesAnteriorAnoAnterior
	,	QtdeCotacaoEsforcoMulticalculoRecusadaMesAnteriorAnoAnterior
	,	QtdeCotacaoEsforcoMulticalculoLiquidaMesAnteriorAnoAnterior
	,	QtdeCotacaoEsforcoMulticalculoTotalMesAnteriorAnoAnterior
	,	QtdePropostaEmitidaMesAnteriorAnoAnterior
	,	QtdePropostaPendenteMesAnteriorAnoAnterior
	,	QtdePropostaTotalMesAnteriorAnoAnterior
	,	QtdeCotacaoApoliceTotalMesAnteriorAnoAnterior
	,	VrPremioLiquidoApoliceNovaProducaoAnoAcumulado
	,	VrPremioLiquidoEndossoNovaProducaoAnoAcumulado
	,	VrPremioLiquidoApoliceRenovacaoAnoAcumulado
	,	VrPremioLiquidoEndossoRenovacaoAnoAcumulado
	,	VrPremioLiquidoTotalAnoAcumulado
	,	QtdeApoliceApoliceNovaProducaoAnoAcumulado
	,	QtdeApoliceEndossoNovaProducaoAnoAcumulado
	,	QtdeApoliceApoliceRenovacaoAnoAcumulado
	,	QtdeApoliceEndossoRenovacaoAnoAcumulado
	,	QtdeApoliceTotalAnoAcumulado
	,	VrPremioCotacaoRecusadaAnoAcumulado
	,	VrPremioCotacaoLiquidaAnoAcumulado
	,	VrPremioCotacaoTotalAnoAcumulado
	,	QtdeCotacaoRecusadaAnoAcumulado
	,	QtdeCotacaoLiquidaAnoAcumulado
	,	QtdeCotacaoTotalAnoAcumulado
	,	QtdeCotacaoEsforcoRecusadaAnoAcumulado
	,	QtdeCotacaoEsforcoLiquidaAnoAcumulado
	,	QtdeCotacaoEsforcoTotalAnoAcumulado
	,	QtdeCotacaoEsforcoMulticalculoRecusadaAnoAcumulado
	,	QtdeCotacaoEsforcoMulticalculoLiquidaAnoAcumulado
	,	QtdeCotacaoEsforcoMulticalculoTotalAnoAcumulado
	,	QtdePropostaEmitidaAnoAcumulado
	,	QtdePropostaPendenteAnoAcumulado
	,	QtdePropostaTotalAnoAcumulado
	,	QtdeCotacaoApoliceTotalAnoAcumulado
	,	VrPremioLiquidoApoliceNovaProducaoAnoAnteriorAcumulado
	,	VrPremioLiquidoEndossoNovaProducaoAnoAnteriorAcumulado
	,	VrPremioLiquidoApoliceRenovacaoAnoAnteriorAcumulado
	,	VrPremioLiquidoEndossoRenovacaoAnoAnteriorAcumulado
	,	VrPremioLiquidoTotalAnoAnteriorAcumulado
	,	QtdeApoliceApoliceNovaProducaoAnoAnteriorAcumulado
	,	QtdeApoliceEndossoNovaProducaoAnoAnteriorAcumulado
	,	QtdeApoliceApoliceRenovacaoAnoAnteriorAcumulado
	,	QtdeApoliceEndossoRenovacaoAnoAnteriorAcumulado
	,	QtdeApoliceTotalAnoAnteriorAcumulado
	,	VrPremioCotacaoRecusadaAnoAnteriorAcumulado
	,	VrPremioCotacaoLiquidaAnoAnteriorAcumulado
	,	VrPremioCotacaoTotalAnoAnteriorAcumulado
	,	QtdeCotacaoRecusadaAnoAnteriorAcumulado
	,	QtdeCotacaoLiquidaAnoAnteriorAcumulado
	,	QtdeCotacaoTotalAnoAnteriorAcumulado
	,	QtdeCotacaoEsforcoRecusadaAnoAnteriorAcumulado
	,	QtdeCotacaoEsforcoLiquidaAnoAnteriorAcumulado
	,	QtdeCotacaoEsforcoTotalAnoAnteriorAcumulado
	,	QtdeCotacaoEsforcoMulticalculoRecusadaAnoAnteriorAcumulado
	,	QtdeCotacaoEsforcoMulticalculoLiquidaAnoAnteriorAcumulado
	,	QtdeCotacaoEsforcoMulticalculoTotalAnoAnteriorAcumulado
	,	QtdePropostaEmitidaAnoAnteriorAcumulado
	,	QtdePropostaPendenteAnoAnteriorAcumulado
	,	QtdePropostaTotalAnoAnteriorAcumulado
	,	QtdeCotacaoApoliceTotalAnoAnteriorAcumulado
	,	VrOrcado
	,	VrOrcadoAnoAcumulado
	,	QtdePolizaEsp
	,	QtdeOfertada
	,	QtdePolizaRen
	,	QtdePolizaEspParcial
	,	QtdeOfertadaParcial
	,	QtdePolizaRenParcial
	,	QtdePolizaEspMesAnterior
	,	QtdeOfertadaMesAnterior
	,	QtdePolizaRenMesAnterior
	,	VrTicketMedio
	,	QtdePropostaProjetado
	,	IndiceConversaoReal
	,	IndiceConversaoRecusadas
	,	QtdeCotacaoProposta
	,	QtdeCotacaoAgravoRecusa
	,	QtdeCotacaoProjetado
	,	QtdeCotacaoProjetadoRelogio
	,	QtdePropostaProjetadoRelogio
	,	ImpPrimaCarteraEsp
	,	ImpPrimaRenGarantizadaEsp
	,	ImpPrimaCarteraRen
	)
	SELECT
		DtReferencia
	,	DtProcessamento
	,	CodCorretor
	,	NomeCorretor
	,	RaizCpfCnpjCorretor
	,	CodAssessor
	,	NomeAssessor
	,	CodSucursal
	,	NomeSucursal
	,	CodTerritorial
	,	NomeTerritorial
	,	CodCanal1
	,	DescricaoCanal1
	,	CodCanal2
	,	DescricaoCanal2
	,	CodCanal3
	,	DescricaoCanal3
	,	CodCanal4
	,	DescricaoCanal4
	,	TipoAtendimentoId
	,	NomeAtendimento
	,	NomeRamo
	,	NomeSetor
	,	VrPremioLiquidoApoliceNovaProducao
	,	VrPremioLiquidoEndossoNovaProducao
	,	VrPremioLiquidoApoliceRenovacao
	,	VrPremioLiquidoEndossoRenovacao
	,	VrPremioLiquidoTotal
	,	QtdeApoliceApoliceNovaProducao
	,	QtdeApoliceEndossoNovaProducao
	,	QtdeApoliceApoliceRenovacao
	,	QtdeApoliceEndossoRenovacao
	,	QtdeApoliceTotal
	,	VrProjecaoIndividualPrimeiraSemana
	,	VrProjecaoIndividualSemSegunda
	,	VrProjecaoIndividualComSegunda
	,	VrProjecaoIndividual
	,	VrProjecaoCaminhao
	,	VrProjecaoFrota
	,	VrProjecaoLiquidoTotal
	,	VrPremioCotacaoRecusada
	,	VrPremioCotacaoLiquida
	,	VrPremioCotacaoTotal
	,	QtdeCotacaoRecusada
	,	QtdeCotacaoLiquida
	,	QtdeCotacaoTotal
	,	QtdeCotacaoEsforcoRecusada
	,	QtdeCotacaoEsforcoLiquida
	,	QtdeCotacaoEsforcoTotal
	,	QtdeCotacaoEsforcoMulticalculoRecusada
	,	QtdeCotacaoEsforcoMulticalculoLiquida
	,	QtdeCotacaoEsforcoMulticalculoTotal
	,	QtdePropostaEmitida
	,	QtdePropostaPendente
	,	QtdePropostaTotal
	,	QtdeCotacaoApoliceTotal
	,	VrPremioLiquidoApoliceNovaProducaoMesAtualAnoAnterior
	,	VrPremioLiquidoEndossoNovaProducaoMesAtualAnoAnterior
	,	VrPremioLiquidoApoliceRenovacaoMesAtualAnoAnterior
	,	VrPremioLiquidoEndossoRenovacaoMesAtualAnoAnterior
	,	VrPremioLiquidoTotalMesAtualAnoAnterior
	,	QtdeApoliceApoliceNovaProducaoMesAtualAnoAnterior
	,	QtdeApoliceEndossoNovaProducaoMesAtualAnoAnterior
	,	QtdeApoliceApoliceRenovacaoMesAtualAnoAnterior
	,	QtdeApoliceEndossoRenovacaoMesAtualAnoAnterior
	,	QtdeApoliceTotalMesAtualAnoAnterior
	,	VrPremioCotacaoRecusadaMesAtualAnoAnterior
	,	VrPremioCotacaoLiquidaMesAtualAnoAnterior
	,	VrPremioCotacaoTotalMesAtualAnoAnterior
	,	QtdeCotacaoRecusadaMesAtualAnoAnterior
	,	QtdeCotacaoLiquidaMesAtualAnoAnterior
	,	QtdeCotacaoTotalMesAtualAnoAnterior
	,	QtdeCotacaoEsforcoRecusadaMesAtualAnoAnterior
	,	QtdeCotacaoEsforcoLiquidaMesAtualAnoAnterior
	,	QtdeCotacaoEsforcoTotalMesAtualAnoAnterior
	,	QtdeCotacaoEsforcoMulticalculoRecusadaMesAtualAnoAnterior
	,	QtdeCotacaoEsforcoMulticalculoLiquidaMesAtualAnoAnterior
	,	QtdeCotacaoEsforcoMulticalculoTotalMesAtualAnoAnterior
	,	QtdePropostaEmitidaMesAtualAnoAnterior
	,	QtdePropostaPendenteMesAtualAnoAnterior
	,	QtdePropostaTotalMesAtualAnoAnterior
	,	QtdeCotacaoApoliceTotalMesAtualAnoAnterior
	,	VrPremioLiquidoApoliceNovaProducaoMesAnterior
	,	VrPremioLiquidoEndossoNovaProducaoMesAnterior
	,	VrPremioLiquidoApoliceRenovacaoMesAnterior
	,	VrPremioLiquidoEndossoRenovacaoMesAnterior
	,	VrPremioLiquidoTotalMesAnterior
	,	QtdeApoliceApoliceNovaProducaoMesAnterior
	,	QtdeApoliceEndossoNovaProducaoMesAnterior
	,	QtdeApoliceApoliceRenovacaoMesAnterior
	,	QtdeApoliceEndossoRenovacaoMesAnterior
	,	QtdeApoliceTotalMesAnterior
	,	VrPremioCotacaoRecusadaMesAnterior
	,	VrPremioCotacaoLiquidaMesAnterior
	,	VrPremioCotacaoTotalMesAnterior
	,	QtdeCotacaoRecusadaMesAnterior
	,	QtdeCotacaoLiquidaMesAnterior
	,	QtdeCotacaoTotalMesAnterior
	,	QtdeCotacaoEsforcoRecusadaMesAnterior
	,	QtdeCotacaoEsforcoLiquidaMesAnterior
	,	QtdeCotacaoEsforcoTotalMesAnterior
	,	QtdeCotacaoEsforcoMulticalculoRecusadaMesAnterior
	,	QtdeCotacaoEsforcoMulticalculoLiquidaMesAnterior
	,	QtdeCotacaoEsforcoMulticalculoTotalMesAnterior
	,	QtdePropostaEmitidaMesAnterior
	,	QtdePropostaPendenteMesAnterior
	,	QtdePropostaTotalMesAnterior
	,	QtdeCotacaoApoliceTotalMesAnterior
	,	VrPremioLiquidoApoliceNovaProducaoMesAnteriorAnoAnterior
	,	VrPremioLiquidoEndossoNovaProducaoMesAnteriorAnoAnterior
	,	VrPremioLiquidoApoliceRenovacaoMesAnteriorAnoAnterior
	,	VrPremioLiquidoEndossoRenovacaoMesAnteriorAnoAnterior
	,	VrPremioLiquidoTotalMesAnteriorAnoAnterior
	,	QtdeApoliceApoliceNovaProducaoMesAnteriorAnoAnterior
	,	QtdeApoliceEndossoNovaProducaoMesAnteriorAnoAnterior
	,	QtdeApoliceApoliceRenovacaoMesAnteriorAnoAnterior
	,	QtdeApoliceEndossoRenovacaoMesAnteriorAnoAnterior
	,	QtdeApoliceTotalMesAnteriorAnoAnterior
	,	VrPremioCotacaoRecusadaMesAnteriorAnoAnterior
	,	VrPremioCotacaoLiquidaMesAnteriorAnoAnterior
	,	VrPremioCotacaoTotalMesAnteriorAnoAnterior
	,	QtdeCotacaoRecusadaMesAnteriorAnoAnterior
	,	QtdeCotacaoLiquidaMesAnteriorAnoAnterior
	,	QtdeCotacaoTotalMesAnteriorAnoAnterior
	,	QtdeCotacaoEsforcoRecusadaMesAnteriorAnoAnterior
	,	QtdeCotacaoEsforcoLiquidaMesAnteriorAnoAnterior
	,	QtdeCotacaoEsforcoTotalMesAnteriorAnoAnterior
	,	QtdeCotacaoEsforcoMulticalculoRecusadaMesAnteriorAnoAnterior
	,	QtdeCotacaoEsforcoMulticalculoLiquidaMesAnteriorAnoAnterior
	,	QtdeCotacaoEsforcoMulticalculoTotalMesAnteriorAnoAnterior
	,	QtdePropostaEmitidaMesAnteriorAnoAnterior
	,	QtdePropostaPendenteMesAnteriorAnoAnterior
	,	QtdePropostaTotalMesAnteriorAnoAnterior
	,	QtdeCotacaoApoliceTotalMesAnteriorAnoAnterior
	,	VrPremioLiquidoApoliceNovaProducaoAnoAcumulado
	,	VrPremioLiquidoEndossoNovaProducaoAnoAcumulado
	,	VrPremioLiquidoApoliceRenovacaoAnoAcumulado
	,	VrPremioLiquidoEndossoRenovacaoAnoAcumulado
	,	VrPremioLiquidoTotalAnoAcumulado
	,	QtdeApoliceApoliceNovaProducaoAnoAcumulado
	,	QtdeApoliceEndossoNovaProducaoAnoAcumulado
	,	QtdeApoliceApoliceRenovacaoAnoAcumulado
	,	QtdeApoliceEndossoRenovacaoAnoAcumulado
	,	QtdeApoliceTotalAnoAcumulado
	,	VrPremioCotacaoRecusadaAnoAcumulado
	,	VrPremioCotacaoLiquidaAnoAcumulado
	,	VrPremioCotacaoTotalAnoAcumulado
	,	QtdeCotacaoRecusadaAnoAcumulado
	,	QtdeCotacaoLiquidaAnoAcumulado
	,	QtdeCotacaoTotalAnoAcumulado
	,	QtdeCotacaoEsforcoRecusadaAnoAcumulado
	,	QtdeCotacaoEsforcoLiquidaAnoAcumulado
	,	QtdeCotacaoEsforcoTotalAnoAcumulado
	,	QtdeCotacaoEsforcoMulticalculoRecusadaAnoAcumulado
	,	QtdeCotacaoEsforcoMulticalculoLiquidaAnoAcumulado
	,	QtdeCotacaoEsforcoMulticalculoTotalAnoAcumulado
	,	QtdePropostaEmitidaAnoAcumulado
	,	QtdePropostaPendenteAnoAcumulado
	,	QtdePropostaTotalAnoAcumulado
	,	QtdeCotacaoApoliceTotalAnoAcumulado
	,	VrPremioLiquidoApoliceNovaProducaoAnoAnteriorAcumulado
	,	VrPremioLiquidoEndossoNovaProducaoAnoAnteriorAcumulado
	,	VrPremioLiquidoApoliceRenovacaoAnoAnteriorAcumulado
	,	VrPremioLiquidoEndossoRenovacaoAnoAnteriorAcumulado
	,	VrPremioLiquidoTotalAnoAnteriorAcumulado
	,	QtdeApoliceApoliceNovaProducaoAnoAnteriorAcumulado
	,	QtdeApoliceEndossoNovaProducaoAnoAnteriorAcumulado
	,	QtdeApoliceApoliceRenovacaoAnoAnteriorAcumulado
	,	QtdeApoliceEndossoRenovacaoAnoAnteriorAcumulado
	,	QtdeApoliceTotalAnoAnteriorAcumulado
	,	VrPremioCotacaoRecusadaAnoAnteriorAcumulado
	,	VrPremioCotacaoLiquidaAnoAnteriorAcumulado
	,	VrPremioCotacaoTotalAnoAnteriorAcumulado
	,	QtdeCotacaoRecusadaAnoAnteriorAcumulado
	,	QtdeCotacaoLiquidaAnoAnteriorAcumulado
	,	QtdeCotacaoTotalAnoAnteriorAcumulado
	,	QtdeCotacaoEsforcoRecusadaAnoAnteriorAcumulado
	,	QtdeCotacaoEsforcoLiquidaAnoAnteriorAcumulado
	,	QtdeCotacaoEsforcoTotalAnoAnteriorAcumulado
	,	QtdeCotacaoEsforcoMulticalculoRecusadaAnoAnteriorAcumulado
	,	QtdeCotacaoEsforcoMulticalculoLiquidaAnoAnteriorAcumulado
	,	QtdeCotacaoEsforcoMulticalculoTotalAnoAnteriorAcumulado
	,	QtdePropostaEmitidaAnoAnteriorAcumulado
	,	QtdePropostaPendenteAnoAnteriorAcumulado
	,	QtdePropostaTotalAnoAnteriorAcumulado
	,	QtdeCotacaoApoliceTotalAnoAnteriorAcumulado
	,	VrOrcado
	,	VrOrcadoAnoAcumulado
	,	QtdePolizaEsp
	,	QtdeOfertada
	,	QtdePolizaRen
	,	QtdePolizaEspParcial
	,	QtdeOfertadaParcial
	,	QtdePolizaRenParcial
	,	QtdePolizaEspMesAnterior
	,	QtdeOfertadaMesAnterior
	,	QtdePolizaRenMesAnterior
	,	VrTicketMedio
	,	QtdePropostaProjetado
	,	IndiceConversaoReal
	,	IndiceConversaoRecusadas
	,	QtdeCotacaoProposta
	,	QtdeCotacaoAgravoRecusa
	,	QtdeCotacaoProjetado
	,	QtdeCotacaoProjetadoRelogio
	,	QtdePropostaProjetadoRelogio
	,	ImpPrimaCarteraEsp
	,	ImpPrimaRenGarantizadaEsp
	,	ImpPrimaCarteraRen

	FROM #TMP_RDS_ATINGIMENTO_PREMIO_LIQUIDO_PRODUTO_AUTO_FINAL

	SELECT @QTDE_INSERT = @QTDE_INSERT + @@ROWCOUNT

	PRINT CONCAT('[Carga Final] Total Delete: ', @Total_Linhas, ' - Total Insert: ', @QTDE_INSERT)

END

GO
