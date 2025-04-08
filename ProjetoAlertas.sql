/****** Object:  StoredProcedure [dbo].[sp_GerarAlertaPublicacaoCorretoresSemCotacoes_Alerta19]    Script Date: 07/04/2025 11:32:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


----------------------------------------------------------------
CREATE PROCEDURE [dbo].[sp_GerarAlertaPublicacaoCorretoresSemCotacoes_Alerta19]
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @DataAtual DATETIME = GETDATE();

	IF DATEPART(WEEKDAY, @DataAtual) NOT IN (1, 7)
		AND dbo.EhFeriado(@DataAtual) = 0
	BEGIN

		DECLARE @DiaDaSemana INT = DATEPART(WEEKDAY, @DataAtual);
		--DECLARE @DiaDaSemana INT = 6 -- Flag para teste
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
		--AND U.ID = 2858 --Teste UsuarioID

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

			INSERT INTO tpm_AlertaPublicacao 
						(Id, AlertaId, Titulo, TemplateCalculado, UsuarioId, DataCriacao, DataReferencia, Ativo)
			VALUES (
				@UltimoAlertaPublicacaoIdGerado,  
				@AlertaId,  
				(SELECT Titulo FROM Alerta WHERE Id = @AlertaId),  
				(SELECT Template FROM Alerta WHERE Id = @AlertaId),  
				@UsuarioId,  
				GETDATE(),  
				@DataRefencia,  
				1
			);
		------------------Alteracao de processo Alerta 19
		------------------Diogo Pereira dos Santos
					---Desabilitando chamada de PROC
					--EXEC sp_GerarAlertaPublicacaoVariavelNovoModelo 
					--										@AlertaId
					--										,@UltimoAlertaPublicacaoIdGerado
					--										,@UsuarioId
------------------Iniciando
		--------------------------DECLARE--------------------------------------
			-- ==================================================================================================
			DECLARE @NomeComercialAlerta VARCHAR(255);
			DECLARE @UsuarioCPFCNPJ VARCHAR(18);
			DECLARE @Var_quantidade_corretores NVARCHAR(20), @Var_percentual NVARCHAR(20);
			DECLARE @Var_msg VARCHAR(MAX);
			-- ==================================================================================================	
			-- Variaveis Diogo
			DECLARE @DiaAnterior DATE = CONVERT(DATE, GETDATE()-2);
			DECLARE @Hist INT = -12;
			DECLARE @PrimeiroDiaMesAtual DATE = DATEFROMPARTS(YEAR(@DiaAnterior), MONTH(@DiaAnterior), 1);
			DECLARE @PrimeiroDiaMesAnterior DATE = DATEADD(MONTH, -1, @PrimeiroDiaMesAtual);
			DECLARE @UltimoDiaMesAnterior DATE = EOMONTH(@PrimeiroDiaMesAnterior);
			DECLARE @AlertaPublicacaoId UNIQUEIDENTIFIER = @UltimoAlertaPublicacaoIdGerado;
-----------------------------------------------------------------------------------------------------------------
			SELECT @NomeComercialAlerta =
					CASE
						WHEN CHARINDEX(' ', Nome) > 0 THEN UPPER(SUBSTRING(Nome, 1, CHARINDEX(' ', Nome) - 1))
						ELSE UPPER(Nome)
					END
				FROM Usuario
				WHERE Id = @UsuarioId
				and Ativo=1;

		SELECT
			@UsuarioCPFCNPJ = CpfCnpj
		FROM Usuario
		WHERE Id = @UsuarioId
		and Ativo=1
		;

		DECLARE @CodCorretorPorAssessor TABLE (
			CodCorretor INT
		);

		INSERT INTO @CodCorretorPorAssessor (CodCorretor)
			SELECT
				hc.CodCorretor
			FROM dbo.HierarquiaComercialUnificada hc with (nolock)
			WHERE hc.CodAssessor = @UsuarioCPFCNPJ 
-----------------------------------------------------------------------------------------------------------------
		-- Armazenar resultados em variáveis temporárias
		DECLARE @RealizadoCarteira DECIMAL(18, 2);
		DECLARE @OrcadoCarteira DECIMAL(18, 2);
-----------------------------------------------------------------------------------------------------------------
		----------------Alterações Diogo--------------------------------
		-- Calcular valores para utilizar no alerta 19
		IF (@AlertaId = 19)
		BEGIN
			DECLARE @QtdeTotalCorretores INT = 0;
-----------------------------------------------------------------------------------------------------------------
		------Adicionando nova Estrutura
-----------------------------------------------------------------------------------------------------------------
			--Verificar somente corretores com classificação diferente de C
			--HierarquiaComercial e ClassificacaoAutoCorretor -#BaseHierarquia
		IF OBJECT_ID('tempdb..#BaseHierarquia') IS NULL
		BEGIN
			SELECT DISTINCT 
				 H.CodCorretor
				,H.CodAssessor
				,H.RaizCpfCnpjCorretor
				,C.CLASSIF_AUTO
				,U.Ativo
			INTO #BaseHierarquia
			FROM HierarquiaComercialUnificada H WITH (NOLOCK)
				LEFT JOIN ClassificacaoAutoCorretor C WITH (NOLOCK)
					ON H.CodCorretor = C.COD_CORRETORA
				LEFT JOIN USUARIO U
					ON H.CodAssessor = U.CpfCnpj
			WHERE C.CLASSIF_AUTO IN ('A', 'AB', 'B', 'C+') 
			  AND U.Ativo = 1;
		END;
-----------------------------------------------------------------------------------------------------------------
			--Cria tabela de cotacoes, somente com Corretores com classificacao <> C -#BaseCotacoes
		IF OBJECT_ID('tempdb..#BaseCotacoes') IS NULL
		BEGIN
			SELECT
				 I.DtReferencia
				,DATEFROMPARTS(YEAR(I.FecEmisionAjustada), MONTH(I.FecEmisionAjustada), 1) as RefMes
				,I.FecEmisionAjustada
				,I.CodCorretor
				,I.NomeCorretor
				,I.CodAssessor
				,I.NomeAssessor
				,I.RaizCpfCnpjCorretor
				,I.QtdeCotacaoEsforcoTotal
				,C.CLASSIF_AUTO
			INTO #BaseCotacoes
			FROM IndicadorProdutoAutoSinteticoCotacaoPorDia I WITH (NOLOCK)
				LEFT JOIN #BaseHierarquia C
					ON I.CodCorretor = C.CodCorretor
			WHERE	I.DtReferencia > DATEADD(MONTH, @Hist, @DiaAnterior)
					AND C.CLASSIF_AUTO IN ('A', 'AB', 'B', 'C+')
					--AND I.CodAssessor = @UsuarioCPFCNPJ
		END;
-----------------------------------------------------------------------------------------------------------------
			--Corretores com cotações zeradas no mês atual - #CorretoresZerados
		IF OBJECT_ID('tempdb..#BaseCorretoresZerados') IS NULL
		BEGIN
			SELECT * 
			INTO #BaseCorretoresZerados
			FROM (
				SELECT 
					RaizCpfCnpjCorretor, 
					MAX(CodCorretor) AS CodCorretor, 
					MAX(NomeCorretor) AS NomeCorretor,
					CodAssessor,
					SUM(QtdeCotacaoEsforcoTotal) AS CotacoesMesAtual
				FROM #BaseCotacoes
				WHERE RefMes = @PrimeiroDiaMesAtual
				GROUP BY 
					RaizCpfCnpjCorretor
					, CodAssessor
			) CorretoresZerados where CotacoesMesAtual = 0
		END;
-----------------------------------------------------------------------------------------------------------------
			--Cotações do Mes Anterior - #BaseCotacoesMesAnterior
		IF OBJECT_ID('tempdb..#BaseCotacoesMesAnterior') IS NULL
		BEGIN
			SELECT 
				RaizCpfCnpjCorretor, 
				MAX(CodCorretor) AS CodCorretor, 
				MAX(CodAssessor) AS CodAssessor,
				SUM(QtdeCotacaoEsforcoTotal) AS QtdeCotacoesEmitidasMesAnterior,
				FORMAT(@PrimeiroDiaMesAnterior, 'MMM', 'pt-BR') AS MesAnterior
				INTO #BaseCotacoesMesAnterior
			FROM #BaseCotacoes
			WHERE RefMes = DATEADD(MONTH, -1, @PrimeiroDiaMesAtual)
			GROUP BY RaizCpfCnpjCorretor, CodAssessor
		END; 
-----------------------------------------------------------------------------------------------------------------
			---Criando Base com a informação de Maior Cotação e Mes - #BaseMesMaiorCotacao
		IF OBJECT_ID('tempdb..#BaseMesMaiorCotacao') IS NULL
		BEGIN
			SELECT
				RaizCpfCnpjCorretor,
				CodCorretor,
				CodAssessor,
				QtdeMaiorCotacao,
				MesMaiorCotacao
				INTO #BaseMesMaiorCotacao
			FROM (
				SELECT 
					RaizCpfCnpjCorretor, 
					MAX(CodCorretor) AS CodCorretor,
					CodAssessor,
					RefMes,
					SUM(QtdeCotacaoEsforcoTotal) AS QtdeMaiorCotacao, 
					RefMes AS MesMaiorCotacao,
					ROW_NUMBER() OVER (PARTITION BY RaizCpfCnpjCorretor, CodAssessor 
						ORDER BY SUM(QtdeCotacaoEsforcoTotal) DESC) AS RankCotacao
				FROM #BaseCotacoes
				GROUP BY RaizCpfCnpjCorretor, CodAssessor, RefMes
			) BaseMesMaiorCotacao where RankCotacao = 1
			END;
-----------------------------------------------------------------------------------------------------------------
			--Crianda Base com a Media dos corretores
			--Dias uteis do Mês atual e atribuido a mesma quantidade de dias uteis para os meses anteriores

			--Criando Referencia de dias uteis 
		IF OBJECT_ID('tempdb..#BaseMediaCotacoes') IS NULL
		BEGIN
			DECLARE @UltimoDiaMesAtual DATE = EOMONTH(@PrimeiroDiaMesAtual);
			--Contar os dias úteis do mês atual (excluindo sábados e domingos)
			DECLARE @DiasUteisMesAtual INT = (
				SELECT COUNT(DISTINCT FecEmisionAjustada) 
					FROM #BaseCotacoes
				WHERE FecEmisionAjustada BETWEEN @PrimeiroDiaMesAtual 
						AND @UltimoDiaMesAtual
						AND DATEPART(WEEKDAY, FecEmisionAjustada) NOT IN (1, 7)
			);
			WITH DiasUteisPassados AS (
				SELECT 
					RaizCpfCnpjCorretor, 
					MAX(CodCorretor) AS CodCorretor, 
					MAX(NomeCorretor) AS NomeCorretor,
					CodAssessor,
					RefMes,
					FecEmisionAjustada,
					SUM(QtdeCotacaoEsforcoTotal) AS TotalCotacoes,
					ROW_NUMBER() OVER (PARTITION BY RaizCpfCnpjCorretor, RefMes ORDER BY FecEmisionAjustada) AS DiaUtilRank
				FROM #BaseCotacoes
				WHERE DATEPART(WEEKDAY, FecEmisionAjustada) NOT IN (1, 7) -- Exclui sábados e domingos
				GROUP BY RaizCpfCnpjCorretor, CodAssessor, RefMes, FecEmisionAjustada
			)
			--Calcular a média mensal e a média diária ajustada
			SELECT 
				RaizCpfCnpjCorretor, 
				MAX(CodCorretor) AS CodCorretor, 
				MAX(NomeCorretor) AS NomeCorretor,
				CodAssessor AS CodAssessor, 
				SUM(TotalCotacoes) / COUNT(DISTINCT RefMes) AS MediaMensalCotacoes, -- Média mensal baseada nos meses distintos
				CASE 
					WHEN @DiasUteisMesAtual > 0 THEN SUM(TotalCotacoes) / @DiasUteisMesAtual 
					ELSE NULL 
				END AS MediaDiariaAjustada -- Evita divisão por zero
				INTO #BaseMediaCotacoes
			FROM DiasUteisPassados
			WHERE DiaUtilRank <= @DiasUteisMesAtual -- Considera apenas os primeiros dias úteis de cada mês
			GROUP BY RaizCpfCnpjCorretor, CodAssessor
		END;
-----------------------------------------------------------------------------------------------------------------
		--Criando tabela consolidade de dados, apartir de CodAssessor zerados
		-- Verifica se a tabela temporária #TempResult já existe
		IF OBJECT_ID('tempdb..#TempResult') IS NOT NULL
		BEGIN
		-- Se a tabela já existir, fazer um DROP na tabela
			DROP TABLE #TempResult;
		END
		-- Se a tabela não existir, cria a tabela temporária #TempResult
		SELECT 
			CZ.RaizCpfCnpjCorretor,
			MAX(CZ.CodCorretor) AS CodCorretor,
			MAX(CZ.NomeCorretor) AS NomeCorretor,
			MAX(CZ.CodAssessor) AS CodAssessor,
			SUM(COALESCE(CZ.CotacoesMesAtual, 0)) AS CotacoesMesAtual,
			SUM(COALESCE(MC.MediaDiariaAjustada, 0)) AS MediaCotacoes,
			MAX(CONVERT(DATE, BM.MesMaiorCotacao)) AS MesPicoCotacoes,
			SUM(COALESCE(BM.QtdeMaiorCotacao, 0)) AS QtdeCotacoesPico,
			MAX(ISNULL(BA.MesAnterior, '0')) AS QtdeCotacoesEmitidasMesAnterior,
			SUM(COALESCE(BA.QtdeCotacoesEmitidasMesAnterior, 0)) AS QtdeMesAnterior
			INTO #TempResult
		FROM #BaseCorretoresZerados CZ
		LEFT JOIN #BaseMediaCotacoes MC
			ON CZ.RaizCpfCnpjCorretor = MC.RaizCpfCnpjCorretor 
			AND CZ.CodAssessor = MC.CodAssessor 
		LEFT JOIN #BaseMesMaiorCotacao BM
			ON CZ.RaizCpfCnpjCorretor = BM.RaizCpfCnpjCorretor 
			AND CZ.CodAssessor = BM.CodAssessor 
		LEFT JOIN #BaseCotacoesMesAnterior BA
			ON CZ.RaizCpfCnpjCorretor = BA.RaizCpfCnpjCorretor 
			AND CZ.CodAssessor = BA.CodAssessor
--		WHERE CZ.CodAssessor = @UsuarioCPFCNPJ
		GROUP BY CZ.RaizCpfCnpjCorretor
		;
-----------------------------------------------------------------------------------------------------------------
		--Criando a estrutura de Varmsg em tabela
		-- Verifica se a tabela temporária #tmp_Var_msg já existe
		IF OBJECT_ID('tempdb..#tmp_Var_msg') IS NOT NULL
		BEGIN
			-- Se a tabela já existir, remover os dados do usuário específico e fazer nova carga de acordo com o CodAssessor
			DELETE FROM #tmp_Var_msg WHERE CodAssessor = @UsuarioCPFCNPJ;
		END
		ELSE
		BEGIN
			-- Criar a tabela temporária se ela não existir
			CREATE TABLE #tmp_Var_msg (
				NomeComercialAlerta VARCHAR(255),
				NomeCorretor VARCHAR(255),
				CodAssessor BIGINT,
				MediaCotacoes FLOAT,
				QtdeCotacoesPico INT,
				MesPicoCotacoes VARCHAR(3), -- Reduzindo tamanho para armazenar 'abr', 'mai', etc.
				QtdeMesAnterior INT
			);
		END;
		-- Insert dos novos dados na tabela temporária: TOP 5 com menor MediaCotacoes
		INSERT INTO #tmp_Var_msg (NomeComercialAlerta, NomeCorretor, CodAssessor, MediaCotacoes, QtdeCotacoesPico, MesPicoCotacoes, QtdeMesAnterior)
		SELECT TOP 5
			@NomeComercialAlerta AS NomeComercialAlerta,  
			NomeCorretor,
			CodAssessor,
			MediaCotacoes,  
			QtdeCotacoesPico,  
			FORMAT(CONVERT(DATE, MesPicoCotacoes), 'MMM', 'pt-BR') AS MesPicoCotacoes, -- Transformando '2025-04-01' em 'abr'
			QtdeMesAnterior
		FROM #TempResult 
		WHERE CodAssessor = @UsuarioCPFCNPJ
		ORDER BY MediaCotacoes ASC; -- Pegando os 5 menores valores
-----------------------------------------------------------------------------------------------------------------
		---Criando processo de envio Var_msg. Inserindo dados dentro @Var_msg
		SELECT @Var_msg = (
			SELECT 
				COALESCE('Destacamos 5 corretores: ' + CHAR(10) + '\\n' +
					STRING_AGG(
						CONVERT(NVARCHAR(MAX), (
							CASE 
								WHEN LEN(top5.NomeCorretor) > 20 THEN LEFT(top5.NomeCorretor, 17) + '...'
								ELSE top5.NomeCorretor
							END
						)) + ' | Pico de Cotações: ' + 
						ISNULL(top5.MesPicoCotacoes, 'Não informado') + ' - ' + 
						CONVERT(NVARCHAR(MAX), ISNULL(top5.QtdeCotacoesPico, 0)) + 
						' | Qtd de Cotações mês anterior: ' + 
						FORMAT(DATEADD(MONTH, -1, GETDATE()), 'MMM') + ' - ' + 
						CONVERT(NVARCHAR(MAX), ISNULL(top5.QtdeCotacoesEmitidasMesAnterior, 0)) + '\\n',
						CHAR(10)
					), ''
				)
			FROM (
				SELECT TOP 5 
					NomeCorretor, 
					MesPicoCotacoes, 
					QtdeCotacoesPico, 
					FORMAT(DATEADD(MONTH, -1, GETDATE()), 'MMM') AS MesAnterior, 
					QtdeMesAnterior AS QtdeCotacoesEmitidasMesAnterior
				FROM #tmp_Var_msg 
				WHERE CodAssessor = @UsuarioCPFCNPJ
				ORDER BY MediaCotacoes ASC
			) AS top5
		);
		--Reproduzi Mensagem
		--PRINT @Var_msg;
-----------------------------------------------------------------------------------------------------------------
			SELECT 
				@Var_quantidade_corretores = COUNT(DISTINCT RaizCpfCnpjCorretor)
			FROM #BaseCotacoes 
			WHERE RefMes = @PrimeiroDiaMesAtual
			AND CodAssessor = @UsuarioCPFCNPJ;

			SELECT 
				@QtdeTotalCorretores = COUNT(DISTINCT RaizCpfCnpjCorretor) 
			FROM #BaseHierarquia A WITH (NOLOCK)
			WHERE A.CodAssessor = @UsuarioCPFCNPJ;
-----------------------------------------------------------------------------------------------------------------
			SELECT @Var_percentual = FORMAT(
				CONVERT(DECIMAL(18, 2),
					CASE 
						WHEN (@QtdeTotalCorretores > 0) THEN
							((CONVERT(DECIMAL(18, 2), @Var_quantidade_corretores) / @QtdeTotalCorretores) * 100)
						ELSE 0
					END
				), 'N2') + '%';
		END
-----------------------------------------------------------------------------------------------------------------
		-- Deletar variáveis existentes
		DELETE FROM AlertaPublicacaoVariavel
		WHERE [AlertaPublicacaoId] = @AlertaPublicacaoId;

		-- Inserir novas variáveis
		INSERT INTO AlertaPublicacaoVariavel (Id, AlertaPublicacaoId, Valor, Variavel, ValidarValorVazioAoEnviaNotificacao)
			SELECT
				NEWID()
			   ,@AlertaPublicacaoId
			   ,CASE
-----------------------------------------------------------------------------------------------------------------
					WHEN AV.VariavelId = 8 THEN -- MM/AA
						CAST(FORMAT(IIF(@AlertaId IN (2, 15), DATEADD(MONTH, 1, @DataAtual), @DataAtual), 'MM/yyyy') AS NVARCHAR(MAX))

					WHEN AV.VariavelId = 28 AND @AlertaId = 19 THEN -- Imagem_Alerta_
						(
							SELECT 
								TOP 1 AI.UrlImagem
							FROM [dbo].[Urls] AI
							WHERE AI.AlertaId = @AlertaId
							ORDER BY AI.UrlId DESC
						)
-----------------------------------------------------------------------------------------------------------------
					WHEN AV.VariavelId = 39 THEN -- var_nome_do_comercial
						@NomeComercialAlerta
					WHEN AV.VariavelId = 40 AND @AlertaId IN (7, 18, 19) THEN -- var_lista_corretores
						CAST(@Var_msg AS NVARCHAR(MAX))
					WHEN AV.VariavelId = 41 AND @AlertaId IN (18, 19) THEN -- var_quantidade_corretores
						CAST(@Var_quantidade_corretores AS NVARCHAR(MAX))
					WHEN AV.VariavelId = 42 AND @AlertaId IN (18, 19) THEN -- var_percentual
						CAST(@Var_percentual AS NVARCHAR(MAX))
-----------------------------------------------------------------------------------------------------------------
					ELSE CAST('' AS NVARCHAR(MAX))
				END
			   ,V.Valor
			   ,V.ValidarValorVazioAoEnviaNotificacao
			FROM [dbo].[AlertaVariavel] AV with (nolock)
			LEFT JOIN [dbo].[Variavel] V with (nolock)
				ON AV.VariavelId = V.Id
			WHERE AV.AlertaId = @AlertaId;
-----------------------------------------------------------------------------------------------------------------
------------------Fim do processo Alerta 19
		END

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

----------------------------------------------------------------
			--Criando o DROP TABLE das tabelas temporarias
			--Limpando a tabela temporária 
			IF OBJECT_ID('tempdb..#BaseHierarquia') IS NOT NULL DROP TABLE #BaseHierarquia;
			IF OBJECT_ID('tempdb..#BaseCotacoes') IS NOT NULL DROP TABLE #BaseCotacoes;
			IF OBJECT_ID('tempdb..#BaseCorretoresZerados') IS NOT NULL DROP TABLE #BaseCorretoresZerados;
			IF OBJECT_ID('tempdb..#BaseCotacoesMesAnterior') IS NOT NULL DROP TABLE #BaseCotacoesMesAnterior;
			IF OBJECT_ID('tempdb..#BaseMesMaiorCotacao') IS NOT NULL DROP TABLE #BaseMesMaiorCotacao;
			IF OBJECT_ID('tempdb..#BaseMediaCotacoes') IS NOT NULL DROP TABLE #BaseMediaCotacoes;
			IF OBJECT_ID('tempdb..#TempResult') IS NOT NULL DROP TABLE #TempResult;
			IF OBJECT_ID('tempdb..#tmp_Var_msg') IS NOT NULL DROP TABLE #tmp_Var_msg;
GO


