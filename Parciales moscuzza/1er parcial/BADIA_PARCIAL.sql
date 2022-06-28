SELECT 
	CASE 
		CASE MONTH(F.fact_fecha) 
			WHEN 1 THEN 1
			WHEN 2 THEN 1
			WHEN 3 THEN 2
			WHEN 4 THEN 2
			WHEN 5 THEN 3
			WHEN 6 THEN 3
			WHEN 7 THEN 4
			WHEN 8 THEN 4
			WHEN 9 THEN 5
			WHEN 10 THEN 5
			WHEN 11 THEN 6
			ELSE 6
		END 
			WHEN 1 THEN 'PRIMERO'
			WHEN 2 THEN 'SEGUNDO'
			WHEN 3 THEN 'TERCERO'
			WHEN 4 THEN 'CUARTO'
			WHEN 5 THEN 'QUINTO'
			WHEN 6 THEN 'SEXTO'
		END AS BIMESTRE,
	SUM(F.fact_total + F.fact_total_impuestos) AS TOTAL_FACTURA_BIMESTRE,
	COUNT(*) AS CANTIDAD_FACTURAS_BIMESTRE,
	(SELECT prod_detalle FROM PRODUCTO WHERE prod_codigo = 
		(	SELECT TOP 1 I.item_producto
			FROM Item_Factura I 
			LEFT JOIN Factura F_S  ON F_S.fact_tipo = I.item_tipo AND F_S.fact_sucursal = I.item_sucursal AND F_S.fact_numero = I.item_numero
			WHERE 	
			CASE 
				CASE MONTH(F.fact_fecha) 
					WHEN 1 THEN 1
					WHEN 2 THEN 1
					WHEN 3 THEN 2
					WHEN 4 THEN 2
					WHEN 5 THEN 3
					WHEN 6 THEN 3
					WHEN 7 THEN 4
					WHEN 8 THEN 4
					WHEN 9 THEN 5
					WHEN 10 THEN 5
					WHEN 11 THEN 6
					ELSE 6
				END 
				WHEN 1 THEN 'PRIMERO'
				WHEN 2 THEN 'SEGUNDO'
				WHEN 3 THEN 'TERCERO'
				WHEN 4 THEN 'CUARTO'
				WHEN 5 THEN 'QUINTO'
				WHEN 6 THEN 'SEXTO'
			END  = 	
			CASE 
				CASE MONTH(F_S.fact_fecha) 
					WHEN 1 THEN 1
					WHEN 2 THEN 1
					WHEN 3 THEN 2
					WHEN 4 THEN 2
					WHEN 5 THEN 3
					WHEN 6 THEN 3
					WHEN 7 THEN 4
					WHEN 8 THEN 4
					WHEN 9 THEN 5
					WHEN 10 THEN 5
					WHEN 11 THEN 6
					ELSE 6
				END 
				WHEN 1 THEN 'PRIMERO'
				WHEN 2 THEN 'SEGUNDO'
				WHEN 3 THEN 'TERCERO'
				WHEN 4 THEN 'CUARTO'
				WHEN 5 THEN 'QUINTO'
				WHEN 6 THEN 'SEXTO'
			END 
			AND YEAR(F_S.fact_fecha) = YEAR(GETDATE()) - 1
			GROUP BY I.item_producto
			ORDER BY SUM(I.item_cantidad) DESC
		) 
	) AS DETALLE_PRODUCTO_MAS_VENDIDO
FROM FACTURA F
WHERE YEAR(F.fact_fecha) = YEAR(GETDATE()) - 1
GROUP BY 	
		CASE MONTH(F.fact_fecha) 
			WHEN 1 THEN 1
			WHEN 2 THEN 1
			WHEN 3 THEN 2
			WHEN 4 THEN 2
			WHEN 5 THEN 3
			WHEN 6 THEN 3
			WHEN 7 THEN 4
			WHEN 8 THEN 4
			WHEN 9 THEN 5
			WHEN 10 THEN 5
			WHEN 11 THEN 6
			ELSE 6
		END 
ORDER BY 		
	CASE MONTH(F.fact_fecha) 
		WHEN 1 THEN 1
		WHEN 2 THEN 1
		WHEN 3 THEN 2
		WHEN 4 THEN 2
		WHEN 5 THEN 3
		WHEN 6 THEN 3
		WHEN 7 THEN 4
		WHEN 8 THEN 4
		WHEN 9 THEN 5
		WHEN 10 THEN 5
		WHEN 11 THEN 6
		ELSE 6
	END 

CREATE PROCEDURE PR_PARCIAL(@TIPO_FAC CHAR(1), @SUCU_FAC CHAR(4), @NRO_FAC CHAR(8), @COD_PROD CHAR(8), @CANTIDAD DECIMAL(12, 2))
AS
BEGIN
	DECLARE @CANTIDAD_STOCK DECIMAL(12, 2)
	
	IF ( SELECT SUM(stoc_cantidad) FROM STOCK WHERE stoc_producto = @COD_PROD ) > 0
	BEGIN
		DECLARE @PRECIO DECIMAL(12, 2) = (SELECT prod_precio FROM Producto WHERE prod_codigo = @COD_PROD)
		DECLARE @DEPO_CON_STOCK CHAR(2) = (SELECT TOP 1 stoc_deposito FROM STOCK WHERE stoc_producto = @COD_PROD AND stoc_cantidad > 0)
		BEGIN TRANSACTION
			INSERT INTO Item_Factura (item_tipo, item_sucursal, item_numero, item_producto, item_precio, item_cantidad) VALUES (@TIPO_FAC, @SUCU_FAC, @NRO_FAC, @COD_PROD, @PRECIO, @CANTIDAD)
		
			UPDATE Factura SET fact_total = ROUND(ISNULL(fact_total, 0) + @PRECIO * @CANTIDAD, 2), fact_total_impuestos = ROUND(ISNULL(fact_total_impuestos, 0) + @PRECIO * @CANTIDAD * 21 /100, 2)
			WHERE fact_tipo = @TIPO_FAC AND fact_sucursal = @SUCU_FAC AND fact_numero = @NRO_FAC
		
			UPDATE STOCK 
			SET stoc_cantidad = stoc_cantidad - @CANTIDAD
			WHERE stoc_producto = @COD_PROD AND stoc_deposito = @DEPO_CON_STOCK
		COMMIT TRANSACTION
	END
	ELSE
	BEGIN
		PRINT 'NO EXISTE SUFICIENTE STOCK PARA FACTURAR EL PRODUCTO: ' + @COD_PROD
	END
END