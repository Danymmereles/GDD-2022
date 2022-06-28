-- 1. SQL

SELECT
  CASE DATEPART(QUARTER, fact_fecha)
    WHEN 1 THEN 'Primero'
    WHEN 2 THEN 'Segundo'
    WHEN 3 THEN 'Tercero'
    WHEN 4 THEN 'Cuarto'
  END
  AS 'TRIMESTRE',
  SUM(fact_total_impuestos) AS 'TOTAL_IMPUESTOS',
  COUNT(*) AS 'CANTIDAD_FACTURAS',
  (SELECT TOP 1 prod_detalle
	FROM Producto
	INNER JOIN Item_Factura ON prod_codigo = item_producto
	INNER JOIN Factura f1 ON f1.fact_tipo = item_tipo
	AND f1.fact_sucursal = item_sucursal
	AND f1.fact_numero = item_numero
	WHERE DATEPART(QUARTER, fact_fecha) = DATEPART(QUARTER, f1.fact_fecha)
	GROUP BY prod_detalle
	ORDER BY SUM(item_cantidad)
   ) AS 'PRODUCTO_MAS_VENDIDO'
FROM
  Factura
WHERE
  YEAR(fact_fecha) = (SELECT YEAR(GETDATE()) - 1)
GROUP BY
  DATEPART(QUARTER, fact_fecha)
ORDER BY 2




-- 2. T-SQL
-- De acuerdo al enunciado, asumo que el trigger ya está creado. Lo único que debe hacerse es realizar el procedimiento correspondiente para hacer efectivas las modificaciones en el stock

IF OBJECT_ID('PR_MOSTRAR_FACTURAS_STOCK_NEGATIVO') IS NOT NULL
	DROP PROCEDURE PR_MOSTRAR_FACTURAS_STOCK_NEGATIVO
GO

IF OBJECT_ID('PR_ACTUALIZAR_CANTIDAD_STOCK') IS NOT NULL
	DROP PROCEDURE PR_ACTUALIZAR_CANTIDAD_STOCK
GO

CREATE PROCEDURE PR_MOSTRAR_FACTURAS_STOCK_NEGATIVO
(@PRODUCTO CHAR(8)) AS
BEGIN
	DECLARE @F_TIPO CHAR(1)
	DECLARE @F_SUCURSAL CHAR(4)
	DECLARE @F_NUMERO CHAR(8)
	DECLARE @F_FECHA SMALLDATETIME
	DECLARE @F_VENDEDOR NUMERIC(6)
	DECLARE @F_TOTAL DECIMAL(12, 2)
	DECLARE @F_TOTAL_IMPUESTOS DECIMAL(12, 2)
	DECLARE @F_CLIENTE CHAR(6)
	
	DECLARE @STOCK DECIMAL (12, 2) = (SELECT stoc_stock_maximo
	FROM STOCK
	WHERE stoc_producto = @PRODUCTO)
	
	DECLARE C_FACTURAS CURSOR FOR
		SELECT *
			FROM Factura
				INNER JOIN Item_Factura ON fact_tipo = item_tipo
					AND fact_sucursal = item_sucursal
					AND fact_numero = item_numero
			WHERE item_producto = @PRODUCTO
	
	OPEN C_FACTURAS
	FETCH NEXT FROM C_FACTURAS INTO
	@F_TIPO, @F_SUCURSAL, @F_NUMERO, @F_FECHA, 
	@F_VENDEDOR, @F_TOTAL, @F_TOTAL_IMPUESTOS, @F_CLIENTE
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF (@STOCK - (SELECT item_cantidad FROM Item_Factura
						INNER JOIN Factura ON fact_tipo = item_tipo
							AND fact_sucursal = item_sucursal
							AND fact_numero = item_numero
						WHERE fact_tipo = @F_TIPO
							AND	fact_sucursal = @F_SUCURSAL
							AND fact_numero = @F_NUMERO)) > 0
		BEGIN
			SET @STOCK = @STOCK - (SELECT item_cantidad FROM Item_Factura
						INNER JOIN Factura ON fact_tipo = item_tipo
							AND fact_sucursal = item_sucursal
							AND fact_numero = item_numero
						WHERE fact_tipo = @F_TIPO
							AND	fact_sucursal = @F_SUCURSAL
							AND fact_numero = @F_NUMERO)
		END
		ELSE BEGIN
			PRINT(CAST(@F_TIPO AS NVARCHAR(MAX)) +
				CAST(@F_SUCURSAL AS NVARCHAR(MAX)) +
				CAST(@F_NUMERO AS NVARCHAR(MAX)) +
				CAST(@F_FECHA AS NVARCHAR(MAX)) +
				CAST(@F_VENDEDOR AS NVARCHAR(MAX)) +
				CAST(@F_TOTAL AS NVARCHAR(MAX)) +
				CAST(@F_TOTAL_IMPUESTOS AS NVARCHAR(MAX)) +
				CAST(@F_CLIENTE AS NVARCHAR(MAX)))
		END
		FETCH NEXT FROM C_FACTURAS INTO
			@F_TIPO, @F_SUCURSAL, @F_NUMERO, @F_FECHA, 
			@F_VENDEDOR, @F_TOTAL, @F_TOTAL_IMPUESTOS, @F_CLIENTE
	END
	CLOSE C_FACTURAS
	DEALLOCATE C_FACTURAS
END

CREATE PROCEDURE PR_ACTUALIZAR_CANTIDAD_STOCK
(@PRODUCTO CHAR(8), @CANTIDAD DECIMAL(12, 2)) AS
BEGIN
	IF ((SELECT stoc_cantidad FROM STOCK WHERE stoc_producto = @PRODUCTO) >= 0) BEGIN
		UPDATE STOCK SET stoc_cantidad = stoc_cantidad + @CANTIDAD
			WHERE stoc_producto = @PRODUCTO
	END
	ELSE BEGIN
		EXEC PR_MOSTRAR_FACTURAS_STOCK_NEGATIVO @PRODUCTO
	END
END