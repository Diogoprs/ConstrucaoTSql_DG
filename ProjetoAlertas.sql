/****** Object:  StoredProcedure [dbo].[sp_GerarAlertaPublicacaoCorretoresSemCotacoes]    Script Date: 17/03/2025 17:06:01 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_GerarAlertaPublicacaoCorretoresSemCotacoes_Diogo07032025]
    @AlertaId INT = 19,  
    @AlertaPublicacaoId UNIQUEIDENTIFIER,  
    @UsuarioId INT 

AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @DataAtual DATETIME = GETDATE();

	IF DATEPART(WEEKDAY, @DataAtual) NOT IN (1, 7)
		AND dbo.EhFeriado(@DataAtual) = 0
	BEGIN

		DECLARE @DiaDaSemana INT = DATEPART(WEEKDAY, @DataAtual);
		DECLARE @UltimoAlertaPublicacaoIdGerado UNIQUEIDENTIFIER;
		-- Tabela temporária para armazenar alertas a serem processados
		CREATE TABLE #AlertasParaProcessar (
			AlertaId INT
		);

		-- Inserir alertas do dia da semana
		INSERT INTO #AlertasParaProcessar (AlertaId)
			SELECT DISTINCT
				a.Id
			FROM Alerta a with (nolock)
			INNER JOIN AlertaPeriodo ap with (nolock)
				ON a.Id = ap.AlertaId
			WHERE a.Ativo = 1
			AND a.Id = 19
			AND ap.DiaDaSemana = @DiaDaSemana
			AND NOT EXISTS (SELECT
					1
				FROM #AlertasParaProcessar
				WHERE AlertaId = a.Id);

		-- Inserir alertas do dia do mês
		INSERT INTO #AlertasParaProcessar (AlertaId)
			SELECT DISTINCT
				a.Id
			FROM Alerta a with (nolock)
			INNER JOIN AlertaPeriodo ap with (nolock)
				ON a.Id = ap.AlertaId
			WHERE a.Ativo = 1
			AND a.Id = 19
			AND ap.DiaDoMes = DAY(@DataAtual)
			AND NOT EXISTS (SELECT
					1
				FROM #AlertasParaProcessar
				WHERE AlertaId = a.Id);

		-- Inserir alertas diário
		INSERT INTO #AlertasParaProcessar (AlertaId)
			SELECT DISTINCT
				a.Id
			FROM Alerta a with (nolock)
			INNER JOIN AlertaPeriodo ap with (nolock)
				ON a.Id = ap.AlertaId
			WHERE a.Ativo = 1
			AND a.Id = 19
			AND ap.AlertaTipoPeriodoId = 1 --1 = DIÁRIO
			AND NOT EXISTS (SELECT
					1
				FROM #AlertasParaProcessar
				WHERE AlertaId = a.Id);

		-- Iterar sobre os alertas e usuários para criar AlertaPublicacao
		DECLARE @AlertaId INT
			   ,@UsuarioId INT
			   ,@HoraLimiteEnvio TIME;

		DECLARE alertaCursor CURSOR FOR SELECT
			AlertaId
		FROM #AlertasParaProcessar;

		OPEN alertaCursor;

		FETCH NEXT FROM alertaCursor INTO @AlertaId;

		WHILE @@fetch_status = 0
		BEGIN
		DECLARE usuarioCursor CURSOR FOR SELECT
			U.Id
		FROM Usuario U with (nolock)
			LEFT JOIN AlertaPublicacao AP with (nolock) ON AP.UsuarioId = U.Id AND AP.AlertaId = @AlertaId AND CONVERT(DATE, AP.DataReferencia) = CONVERT(DATE, GETDATE())
		WHERE Telefone IS NOT NULL AND AP.Id IS NULL

		OPEN usuarioCursor;

		FETCH NEXT FROM usuarioCursor INTO @UsuarioId;

		WHILE @@fetch_status = 0
		BEGIN
		IF NOT EXISTS (SELECT
					1
				FROM AlertaPublicacao A with (nolock)
				WHERE A.AlertaId = @AlertaId
				AND A.UsuarioId = @UsuarioId
				AND A.DataReferencia >= CONVERT(DATE, GETDATE()))
		BEGIN
			SELECT
				@HoraLimiteEnvio = HoraLimiteEnvio
			FROM AlertaPeriodo with (nolock)
			WHERE AlertaId = @AlertaId
			AND (
			DiaDaSemana = @DiaDaSemana
			OR DiaDoMes = DAY(@DataAtual)
			OR AlertaTipoPeriodoId = 1
			);

			DECLARE @DataRefencia DATETIME = CAST(CONVERT(VARCHAR, @DataAtual, 112) + ' ' +
			RIGHT('0' + CAST(DATEPART(HOUR, @HoraLimiteEnvio) AS VARCHAR), 2) + ':' +
			RIGHT('0' + CAST(DATEPART(MINUTE, @HoraLimiteEnvio) AS VARCHAR), 2) AS DATETIME);

			SET @UltimoAlertaPublicacaoIdGerado = NEWID()

			INSERT INTO AlertaPublicacao (Id, TemplateCalculado, AlertaId, Titulo, DataCriacao, UsuarioId, DataReferencia, Ativo)
				VALUES (@UltimoAlertaPublicacaoIdGerado, (SELECT Template FROM Alerta WHERE Id = @AlertaId), @AlertaId, (SELECT Titulo FROM Alerta WHERE Id = @AlertaId), GETDATE(), @UsuarioId, @DataRefencia, 1);
	
-- Diogo 17/03/2025 - Essa inclusão foi feita atraves da estrutura retirada do processo sp_GerarAlertaPublicacaoVariavelNovoModelo 

    ---------------- DECLARAÇÃO DE VARIÁVEIS ----------------
		DECLARE @NomeComercialAlerta VARCHAR(255);  
		DECLARE @UsuarioCPFCNPJ VARCHAR(18);  
		DECLARE @Var_msg VARCHAR(MAX);  
		DECLARE @mesatual DATE = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);  
		DECLARE @QtdeTotalCorretores INT = 0;  
		DECLARE @Var_quantidade_corretores INT = 0;  
		DECLARE @Var_percentual NVARCHAR(10);  

		---------------- OBTENDO DADOS DO USUÁRIO ----------------  
		SELECT  
			@NomeComercialAlerta = UPPER(ISNULL(NULLIF(PARSENAME(REPLACE(Nome, ' ', '.'), 2), ''), Nome)),  
			@UsuarioCPFCNPJ = CpfCnpj  
		FROM Usuario  
		WHERE Id = @UsuarioId AND Ativo = 1;  

		-- Se o usuário for inválido, encerra a execução  
		IF @UsuarioCPFCNPJ IS NULL  
		BEGIN  
			PRINT 'Usuário inválido ou inativo.';  
			RETURN;  
		END  

		---------------- CALCULA MÉDIA DE COTAÇÕES ----------------  
		IF @AlertaId = 19  
		BEGIN  
			BEGIN TRY  
		-------------------------------------------------
		-- Drop the temporary table if it already exists
		IF OBJECT_ID('tempdb..#TempResult') IS NOT NULL
			DROP TABLE #TempResult;

		-- Criando CTE para manipulação dos dados de corretores com Menor Média de cotações
		-- Apresentando os 5 piores Corretores na base
		WITH CorretoresMenorMedia AS (  
		SELECT TOP 5
			MAX(CodCorretor) AS CodCorretor,  
			MAX(NomeCorretor) AS NomeCorretor,  
			AVG(QtdeCotacaoEsforcoTotal) AS MediaCotacoes
		FROM IndicadorProdutoAutoSinteticoCotacao WITH (NOLOCK)  
		WHERE CodAssessor = @UsuarioCPFCNPJ
		GROUP BY RaizCpfCnpjCorretor
		),  
		-- Apresentando o Mês e Valor com maior Pico de cotações para os 5 piores Corretores
		-- Levando em consideração os top 5 com menor media
		MesMaiorCotacao AS (  
		-- Criando a tabela temporária #CorretoresMenorMedia
		SELECT CodCorretor,
			   MesMaiorCotacao,
			   ValorMaiorCotacao
		FROM (
			SELECT  
				i.CodCorretor,
				FORMAT(i.DtReferencia, 'MMM', 'pt-BR') AS MesMaiorCotacao,  
				SUM(i.QtdeCotacaoEsforcoTotal) AS ValorMaiorCotacao,
				ROW_NUMBER() OVER (PARTITION BY i.CodCorretor ORDER BY SUM(i.QtdeCotacaoEsforcoTotal) DESC) AS RowNum
			FROM IndicadorProdutoAutoSinteticoCotacao i WITH (NOLOCK)  
			JOIN CorretoresMenorMedia cm ON i.CodCorretor = cm.CodCorretor
			GROUP BY i.CodCorretor, FORMAT(i.DtReferencia, 'MMM', 'pt-BR')
		) AS MesMaiorCotacao
		WHERE RowNum = 1
		),  
		-- Apresentando o Mês e Valor do mês anterior
		-- Levando em consideração os top 5 com menor media
		QtdeCotacoesMesAnterior AS (  
			SELECT  
				i.CodCorretor,
				sum(i.QtdeCotacaoEsforcoTotal) AS QtdeCotacoesMesAnterior,  
				FORMAT(DATEADD(MONTH, -1, GETDATE()), 'MMM', 'pt-BR') AS MesCotacoesMesAnterior  
			FROM IndicadorProdutoAutoSinteticoCotacao i WITH (NOLOCK)  
			JOIN CorretoresMenorMedia cm ON i.CodCorretor = cm.CodCorretor
			WHERE MONTH(i.DtReferencia) = MONTH(GETDATE()) - 1  
				  AND YEAR(i.DtReferencia) = YEAR(GETDATE())  
			GROUP BY i.CodCorretor
		)
		-- Criando tabela temporária para armazenar os dados
		SELECT  
			ROW_NUMBER() OVER (ORDER BY cm.MediaCotacoes ASC) AS RowNum,  
			cm.NomeCorretor,  
			mmc.ValorMaiorCotacao AS QtdeCotacoesPico,  
			mmc.MesMaiorCotacao AS MesPicoCotacoes,  
			qma.QtdeCotacoesMesAnterior AS QtdeCotacoesEmitidasMesAnterior,  
			qma.MesCotacoesMesAnterior AS MesAnterior,  
			cm.MediaCotacoes  
		INTO #TempResult  
		FROM CorretoresMenorMedia cm  
		LEFT JOIN MesMaiorCotacao mmc ON cm.CodCorretor = mmc.CodCorretor  
		LEFT JOIN QtdeCotacoesMesAnterior qma ON cm.CodCorretor = qma.CodCorretor;
		-------------------------------------------------
				-- Construindo a mensagem  
				SELECT @Var_msg =  
					'Alerta para ' + @NomeComercialAlerta + CHAR(13) +  
					'Corretor: ' + NomeCorretor + CHAR(13) +  
					'Média de Cotações: ' + CAST(MediaCotacoes AS VARCHAR) + CHAR(13) +  
					'Maior Cotação: ' + CAST(QtdeCotacoesPico AS VARCHAR) + CHAR(13) +  
					'Mês da Maior Cotação: ' + MesPicoCotacoes + CHAR(13) +  
					'Cotações Emitidas no Mês Anterior: ' + CAST(QtdeCotacoesEmitidasMesAnterior AS VARCHAR)  
				FROM #TempResult;  

				PRINT @Var_msg;  

				-- Limpando a tabela temporária  
				DROP TABLE #TempResult;  

			END TRY  
			BEGIN CATCH  
				PRINT 'Erro ao executar a procedure: ' + ERROR_MESSAGE();  
			END CATCH;  
		END  

		---------------- CÁLCULO DE PERCENTUAL DE CORRETORES ----------------  
		SELECT  
			@Var_quantidade_corretores = COUNT(DISTINCT RaizCpfCnpjCorretor)  
		FROM IndicadorProdutoAutoSinteticoCotacao WITH (NOLOCK)  
		WHERE DtReferencia = @mesatual  
		AND CodAssessor = @UsuarioCPFCNPJ;  

		SELECT  
			@QtdeTotalCorretores = COUNT(DISTINCT RaizCpfCnpjCorretor)  
		FROM HierarquiaComercialUnificada A WITH (NOLOCK)  
		LEFT JOIN ClassificacaoAutoCorretor B WITH (NOLOCK)  
			ON B.COD_CORRETORA = A.CodCorretor  
		WHERE A.CodAssessor = @UsuarioCPFCNPJ  
		AND B.CLASSIF_AUTO IN ('A', 'AB', 'B', 'C+');  

		SELECT @Var_percentual = FORMAT(  
			CONVERT(DECIMAL(18, 2),  
				CASE  
					WHEN (@QtdeTotalCorretores > 0) THEN  
						((CONVERT(DECIMAL(18, 2), @Var_quantidade_corretores) / @QtdeTotalCorretores) * 100)  
					ELSE 0  
				END  
			), 'N2') + '%';  

		---------------- DELETANDO VARIÁVEIS EXISTENTES ----------------  
		DELETE FROM [dbo].[AlertaPublicacaoVariavel]  
		WHERE [AlertaPublicacaoId] = @AlertaPublicacaoId;  

		---------------- INSERINDO NOVAS VARIÁVEIS ----------------  
		INSERT INTO [dbo].[AlertaPublicacaoVariavel] (Id, AlertaPublicacaoId, Valor, Variavel, ValidarValorVazioAoEnviaNotificacao)  
		SELECT  
			NEWID(),  
			@AlertaPublicacaoId,  
			CASE  
				WHEN AV.VariavelId = 8 THEN FORMAT(IIF(@AlertaId IN (2, 15), DATEADD(MONTH, 1, GETDATE()), GETDATE()), 'MM/yyyy')  
				WHEN AV.VariavelId = 28 AND @AlertaId = 19 THEN (  
					SELECT TOP 1 AI.UrlImagem  
					FROM [dbo].[Urls] AI  
					WHERE AI.AlertaId = @AlertaId  
					ORDER BY AI.UrlId DESC  
				)  
				WHEN AV.VariavelId = 39 THEN @NomeComercialAlerta  
				ELSE ''  
			END,  
			V.Valor,  
			V.ValidarValorVazioAoEnviaNotificacao  
		FROM [dbo].[AlertaVariavel] AV WITH (NOLOCK)  
		LEFT JOIN [dbo].[Variavel] V WITH (NOLOCK)  
			ON AV.VariavelId = V.Id  
		WHERE AV.AlertaId = @AlertaId;  
		
		END

		--------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------
		FETCH NEXT FROM usuarioCursor INTO @UsuarioId;
		END

		CLOSE usuarioCursor;
		DEALLOCATE usuarioCursor;

		FETCH NEXT FROM alertaCursor INTO @AlertaId;
		END

		CLOSE alertaCursor;
		DEALLOCATE alertaCursor;

		-- Limpar a tabela temporária
		DROP TABLE #AlertasParaProcessar;

	END
END
GO


