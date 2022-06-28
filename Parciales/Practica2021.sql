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