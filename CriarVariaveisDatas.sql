	DECLARE 
		@CurrentDate				        DATE = NULL --'2025-03-31'
	,	@FirstDayOfMonth			      DATE
	,	@LastDayOfMonth				      DATE
	,	@FirstDaySkFecha			      VARCHAR(200)
	,	@LastDaySkFecha				      VARCHAR(200)
	,	@Msg					              VARCHAR(MAX)
	,	@Qt_Linhas				          INT
	,	@Total_Linhas				        INT = 0
	,	@QTDE_INSERT				        INT = 0
	,	@DiasUteisSemFDS			      INT
	,	@DiasUteisParaFimSemFDS			INT
	,	@TotalDiasUteis				      INT
	,	@FirstDayOfYear				      DATE
	,	@FirstDayPreviousMonth			DATE
	,	@DiasSegParaFim				      INT
	,	@DiasUteisSemSegunda			  INT
	,	@DiasUteisParaFimSemSegunda	INT
	,	@DiasSeg				            INT
	,	@LastDayOfNextMonth			    DATE
	,	@LastDayOfNextMonthSkFecha	VARCHAR(200)
	,	@NR_ANO_MES				          INT
	,	@FirstDayOfMonthLastYear		DATE


	SET @CurrentDate			    = CASE WHEN @CurrentDate IS NULL THEN DATEADD(DAY, -1, GETDATE()) ELSE @CurrentDate END
	SET @FirstDayOfMonth			= DATEADD(DAY, 1 - DAY(@CurrentDate), @CurrentDate)
	SET @LastDayOfMonth			  = EOMONTH(@CurrentDate)
	SET @FirstDaySkFecha			= CONVERT(varchar, DATEADD(DAY, 1 - DAY(@CurrentDate), @CurrentDate), 112)
	SET @LastDaySkFecha			  = CONVERT(varchar, EOMONTH(@CurrentDate), 112)
	SET @DiasUteisSemFDS			= dbo.ContarDiasUteisSemFDS(@FirstDayOfMonth, @CurrentDate)
	SET @DiasUteisParaFimSemFDS		= dbo.ContarDiasUteisFaltantesSemFDS(@CurrentDate, @LastDayOfMonth)
	SET @TotalDiasUteis			      = @DiasUteisSemFDS + @DiasUteisParaFimSemFDS
	SET @FirstDayOfYear			      = DATEFROMPARTS(YEAR(@CurrentDate), 1, 1)
	SET @FirstDayPreviousMonth		= DATEADD(MONTH, -1, DATEADD(DAY, 1 - DAY(@CurrentDate), @CurrentDate))
	SET @DiasSegParaFim			      = dbo.ContarSabadDomSeg(@CurrentDate, @LastDayOfMonth)
	SET @DiasUteisSemSegunda		  = dbo.ContarDiasUteis(@FirstDayOfMonth, @CurrentDate)
	SET @DiasUteisParaFimSemSegunda 	= dbo.ContarDiasUteisFaltantes(@CurrentDate, @LastDayOfMonth)
	SET @DiasSeg				              = dbo.ContarSabadDomSeg(@FirstDayOfMonth, @CurrentDate)
	SET @LastDayOfNextMonth			      = EOMONTH(DATEADD(MONTH, 1, @CurrentDate))
	SET @LastDayOfNextMonthSkFecha		= CONVERT(varchar, EOMONTH(@LastDayOfNextMonth), 112)
	SET @NR_ANO_MES				            = CONVERT(VARCHAR(6), @CurrentDate, 112)
	SET @FirstDayOfMonthLastYear		  = DATEADD(YEAR, -1, @FirstDayOfMonth)


	SELECT 
	 @CurrentDate				  AS CurrentDate					
	,@FirstDayOfMonth			AS FirstDayOfMonth			
	,@LastDayOfMonth			AS LastDayOfMonth				
	,@FirstDaySkFecha			AS FirstDaySkFecha			
	,@LastDaySkFecha			AS LastDaySkFecha				
	,@DiasUteisSemFDS			AS DiasUteisSemFDS			
	,@DiasUteisParaFimSemFDS		AS DiasUteisParaFimSemFDS		
	,@TotalDiasUteis			      AS TotalDiasUteis				
	,@FirstDayOfYear			      AS FirstDayOfYear				
	,@FirstDayPreviousMonth			AS FirstDayPreviousMonth		
	,@DiasSegParaFim			      AS DiasSegParaFim				
	,@DiasUteisSemSegunda			  AS DiasUteisSemSegunda		
	,@DiasUteisParaFimSemSegunda 		AS DiasUteisParaFimSemSegunda 
	,@DiasSeg				                AS DiasSeg					
	,@LastDayOfNextMonth			      AS LastDayOfNextMonth			
	,@LastDayOfNextMonthSkFecha		  AS LastDayOfNextMonthSkFecha	
	,@NR_ANO_MES				            AS NR_ANO_MES					
	,@FirstDayOfMonthLastYear		    AS FirstDayOfMonthLastYear	


