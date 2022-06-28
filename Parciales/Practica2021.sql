/*
Realizar una consulta SQL que retorne: 
	Año (OK)
	Cantidad de productos compuestos vendidos en el Año 
	Cantidad de facturas realizadas en el Año (OK)
	Monto total facturado en el Año (OK)
	Monto total facturado en el Año anterior.
*/


SELECT
	YEAR(fact2.fact_fecha) as 'Anio', 
	(
		SELECT SUM(itemFact.item_cantidad)
		FROM Factura fact
		JOIN Item_Factura itemFact ON itemFact.item_tipo = fact.fact_tipo AND itemFact.item_sucursal = fact.fact_sucursal AND itemFact.item_numero = fact.fact_numero
		WHERE 
			YEAR(fact.fact_fecha) = YEAR(fact2.fact_fecha)
			AND itemFact.item_producto IN (
				SELECT DISTINCT prod.prod_codigo FROM Producto prod JOIN Composicion c ON c.comp_producto = prod.prod_codigo
			)

	) as 'Productos compuestos vendidos',
	COUNT(DISTINCT fact2.fact_tipo+fact2.fact_sucursal+fact2.fact_numero) as 'Facturas realizadas',
	(SELECT SUM(fact.fact_total) FROM Factura fact WHERE year(fact.fact_fecha) = year(fact2.fact_fecha))  as 'Monto total facturado',
	(
		SELECT COALESCE(SUM(fact.fact_total), 0)
		FROM Factura fact
		WHERE YEAR(fact.fact_fecha) = YEAR(fact2.fact_fecha) - 1
	) as 'Monto total facturado año anterior'
FROM Factura fact2
JOIN Item_Factura itemFact2 ON itemFact2.item_tipo = fact2.fact_tipo AND itemFact2.item_sucursal = fact2.fact_sucursal AND itemFact2.item_numero = fact2.fact_numero
GROUP BY YEAR(fact2.fact_fecha)
HAVING COALESCE(SUM(itemFact2.item_cantidad),0) > 1000
ORDER BY COALESCE(SUM(itemFact2.item_cantidad),0) DESC


/*
Realizar una función
	Parametros:
		Tipo de factura 
		Sucursal 
	Retorno:
		Próximo número de factura consecutivo 
		No exista ninguno informar el primero
	Consideraciones:
		El tipo de dato y formato de retorno debe coincidir con el de la tabla (Ej. '00002021').
*/

/*SELECT *
  FROM sys.sql_modules m 
INNER JOIN sys.objects o 
        ON m.object_id=o.object_id
WHERE type_desc like '%function%'*/

CREATE FUNCTION dbo.ProxNumFactura1(@tipo CHAR(1), @sucursal CHAR(4))
RETURNS CHAR(8)
BEGIN
	RETURN COALESCE((
    SELECT 
	MAX(f.fact_numero) 
	FROM Factura f
    WHERE f.fact_sucursal = @sucursal AND f.fact_tipo = @tipo
    ), 0) + 1 
END;

DROP FUNCTION dbo.ProxNumFactura1

SELECT dbo.ProxNumFactura1('A', '0003')



/*
Realizar un stored procedure que 
	Objetivo:
		Inserte un nuevo registro de factura y un ítem
	Parametros:
		Todos los datos obligatorios de las 2 tablas, la fecha y un código de depósito
	Consideraciones:
		Guardar solo los valores no nulos en ambas tablas
		Restar el stock de ese producto en la tabla correspondiente
		Se debe validar previamente la existencia del stock en ese depósito y en caso de no haber no realizar nada.
		El total de factura se calcula como el precio de ese único ítem
		Los impuestos es el 21% de dicho valor redondeado a 2 decimales.

Se debe programar una transacción para que las 3 operaciones se realicen atómicamente, se asume que todos los parámetros recibidos están validados a excepción de la cantidad del producto en stock.
Queda a criterio del alumno, que acciones tomar en caso de que no se cumpla la única validación o se produzca un error no previsto.
*/
DROP PROCEDURE dbo.ComprarUnProducto;
CREATE PROCEDURE dbo.ComprarUnProducto 
	@fact_tipo char(1), 
	@fact_sucursal char(4),
	@fact_numero char(8),
	@item_producto char(8),
	@fecha smalldatetime,
	@depo_codigo char(2)
AS
	DECLARE @stock decimal(12,2);
	SET @stock = (SELECT ISNULL((SELECT s.stoc_cantidad FROM STOCK s WHERE s.stoc_producto = @item_producto AND s.stoc_deposito = @depo_codigo), 0));
	IF @stock < 1
		BEGIN
			print 'Stock insuficiente: ' + convert(varchar, @stock);
		END
	ELSE
		BEGIN
			DECLARE @precio decimal(12,2);
			DECLARE @upd_error int, @ins1_error int, @ins2_error int;

			SET @precio = (SELECT p.prod_precio FROM Producto p WHERE p.prod_codigo = @item_producto);
			
			BEGIN TRANSACTION T1 WITH MARK 'VENDIENDO UN PRODUCTO';

			UPDATE dbo.STOCK
			SET stoc_cantidad = stoc_cantidad - 1
			WHERE stoc_producto = @item_producto AND stoc_deposito = @depo_codigo;

			SET @upd_error = @@ERROR;

			INSERT INTO dbo.Factura 
				(
					fact_tipo,
					fact_sucursal,
					fact_numero,
					fact_fecha,
					fact_total,
					fact_total_impuestos
				)
				VALUES
				(
					@fact_tipo,
					@fact_sucursal,
					@fact_numero,
					@fecha,
					@precio,
					ROUND(@precio * 0.21, 2)
				);
			SET @ins1_error = @@ERROR;

			INSERT INTO dbo.Item_Factura
				(
					item_tipo,
					item_sucursal,
					item_numero,
					item_producto,
					item_cantidad,
					item_precio
				)
				VALUES
				(
					@fact_tipo,
					@fact_sucursal,
					@fact_numero,
					@item_producto,
					1,
					@precio
				);
			SET @ins2_error = @@ERROR;

			IF @upd_error = 0 AND @ins1_error = 0 AND @ins2_error = 0
			BEGIN
				PRINT 'Salió todo bien'
				COMMIT TRAN
			END
			ELSE
			BEGIN
				IF @upd_error <> 0
					PRINT 'Error en update'
				IF @ins1_error <> 0
					PRINT 'Error en insert 1'
				IF @ins2_error <> 0
					PRINT 'Error en insert 2'
			 ROLLBACK TRANSACTION T1
			END
		END
GO


EXEC dbo.ComprarUnProducto 
	@fact_tipo = 'A', 
	@fact_sucursal = '0003', 
	@fact_numero = '33233122',
	@item_producto = '42424242',
	@fecha = '2010-01-23 00:00:00',
	@depo_codigo = '00'

EXEC dbo.ComprarUnProducto 
	@fact_tipo = 'A', 
	@fact_sucursal = '0003', 
	@fact_numero = '55555559',
	@item_producto = '00000030',
	@fecha = '2010-01-23 00:00:00',
	@depo_codigo = '00'

SELECT S.stoc_cantidad FROM STOCK S WHERE S.stoc_producto = '00000030' AND S.stoc_deposito = '00'