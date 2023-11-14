USE [GD2015C1]
GO

/*16. Con el fin de lanzar una nueva campaña comercial para los clientes que menos compran
en la empresa, se pide una consulta SQL que retorne aquellos clientes cuyas ventas son
inferiores a 1/3 del promedio de ventas del producto que más se vendió en el 2012.
Además mostrar
1. Nombre del Cliente
2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
3. Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1,
mostrar solamente el de menor código) para ese cliente.
Aclaraciones:
La composición es de 2 niveles, es decir, un producto compuesto solo se compone de
productos no compuestos.
Los clientes deben ser ordenados por código de provincia ascendente*/

SELECT C.clie_razon_social AS Nombre, (SELECT TOP 1 P.prod_codigo
FROM Item_Factura I
INNER JOIN Factura F ON I.item_tipo = F.fact_tipo AND I.item_sucursal = F.fact_sucursal AND I.item_numero = F.fact_numero 
INNER JOIN Producto P ON I.item_producto = P.prod_codigo
WHERE YEAR (F.fact_fecha) = 2012 AND fact_cliente = C.clie_codigo
GROUP BY P.prod_codigo, P.prod_detalle
ORDER BY SUM(I.item_cantidad) ASC) AS 'Producto mas vendido' 
FROM Cliente C 



USE [GD2015C1]
GO




SELECT  clie_razon_social 'Razón Social',
		clie_domicilio 'Domicilio',	
		SUM(item_cantidad) 'Unidades totales compradas',
		(SELECT TOP 1 item_producto
		FROM Item_Factura JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
		WHERE YEAR (fact_fecha) = 2012 AND fact_cliente = clie_codigo
		GROUP BY item_producto
		ORDER BY SUM(item_cantidad) DESC, item_producto ASC) 'Producto mas comprado'
FROM Cliente JOIN Factura ON clie_codigo = fact_cliente
			 JOIN Item_Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
WHERE YEAR(fact_fecha) = 2012
GROUP BY clie_codigo, clie_razon_social, clie_domicilio
HAVING SUM(item_cantidad) < 1.00/3*(SELECT TOP 1 SUM(item_cantidad)
									FROM Item_Factura
										JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
									WHERE YEAR(fact_fecha) = 2012
									GROUP BY item_producto
									ORDER BY SUM(item_cantidad) DESC)
ORDER BY clie_domicilio ASC


/*
SELECT TOP 1 P.prod_codigo
FROM Item_Factura I
INNER JOIN Factura F ON I.item_tipo = F.fact_tipo AND I.item_sucursal = F.fact_sucursal AND I.item_numero = F.fact_numero 
INNER JOIN Producto P ON I.item_producto = P.prod_codigo
WHERE YEAR (F.fact_fecha) = 2012
GROUP BY P.prod_codigo, P.prod_detalle
ORDER BY SUM(I.item_cantidad) ASC
*/

/*17. Escriba una consulta que retorne una estadística de ventas por año y mes para cada
producto.
La consulta debe retornar:
PERIODO: Año y mes de la estadística con el formato YYYYMM
PROD: Código de producto
DETALLE: Detalle del producto
CANTIDAD_VENDIDA= Cantidad vendida del producto en el periodo
VENTAS_AÑO_ANT= Cantidad vendida del producto en el mismo mes del periodo
pero del año anterior
CANT_FACTURAS= Cantidad de facturas en las que se vendió el producto en el
periodo
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por periodo y código de producto*/

SELECT prod_codigo, CONVERT(f.fact_fecha,GETDATE(),112) AS [Fecha de estadistica], prod_detalle, ISNULL(SUM(I.item_cantidad),0)
FROM Producto P
INNER JOIN Item_Factura I ON I.item_producto = P.prod_codigo
INNER JOIN Factura f  ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
GROUP BY prod_codigo, prod_detalle
ORDER BY f.fact_fecha


--FORMA RESUELTA--
SELECT STR(YEAR(F.fact_fecha))+STR(MONTH(F.fact_fecha))--FORMAT (F.fact_fecha, 'yyyyMM') AS [Periodo]--(YEAR(F.fact_fecha) ++ MONTH(F.fact_fecha))
	--FORMAT (F.fact_fecha, 'yyyyMM') AS [Periodo]
	,P.prod_codigo
	,P.prod_detalle
	,SUM(IFACT.item_cantidad)
	,ISNULL((
		SELECT SUM(item_cantidad)
		FROM Item_Factura
			INNER JOIN Factura
				ON item_tipo = fact_tipo AND item_numero = fact_numero AND item_sucursal = fact_sucursal
		WHERE YEAR(fact_fecha) = (YEAR(F.fact_fecha)-1) AND MONTH(fact_fecha) = MONTH(F.fact_fecha) AND P.prod_codigo = item_producto
		),0) AS [Cantidad del mismo producto en el año anterior]
	,COUNT(F.fact_tipo + F.fact_sucursal + F.fact_numero) AS [Cant de facturas]
FROM Producto P
	INNER JOIN Item_Factura IFACT
		ON IFACT.item_producto = P.prod_codigo
	INNER JOIN Factura F
		ON IFACT.item_tipo = F.fact_tipo AND IFACT.item_numero = F.fact_numero AND IFACT.item_sucursal = F.fact_sucursal
WHERE p.prod_codigo = '00010200'
GROUP BY --,P.prod_codigo,P.prod_detalle

YEAR(F.fact_fecha), MONTH(F.fact_fecha),P.prod_codigo,P.prod_detalle
ORDER BY 1 ASC, P.prod_codigo

--OTRA FORMA--
SELECT 
	CONCAT(YEAR(F1.fact_fecha), RIGHT('0' + RTRIM(MONTH(F1.fact_fecha)), 2)) AS 'Periodo',
	prod_codigo AS 'Codigo',
	ISNULL(prod_detalle, 'SIN DESCRIPCION') AS 'Producto',
	ISNULL(SUM(item_cantidad), 0) AS 'Cantidad vendida',
	ISNULL((SELECT SUM(item_cantidad) FROM Item_Factura
	JOIN Factura F2 ON item_numero + item_sucursal + item_tipo =
	F2.fact_numero + F2.fact_sucursal + F2.fact_tipo  
	WHERE item_producto = prod_codigo 
	AND YEAR(F2.fact_fecha) = YEAR(F1.fact_fecha) - 1
	AND MONTH(F2.fact_fecha) = MONTH(F1.fact_fecha)), 0) AS 'Cantidad vendida anterior',
	ISNULL(COUNT(*) , 0) AS 'Cantidad de facturas'
FROM Producto
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura F1 ON item_numero + item_sucursal + item_tipo =
F1.fact_numero + F1.fact_sucursal + F1.fact_tipo
GROUP BY prod_codigo, prod_detalle, YEAR(F1.fact_fecha), MONTH(F1.fact_fecha)
ORDER BY 1, 2

/*18. Escriba una consulta que retorne una estadística de ventas para todos los rubros.
La consulta debe retornar:
DETALLE_RUBRO: Detalle del rubro
VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro
PROD1: Código del producto más vendido de dicho rubro
PROD2: Código del segundo producto más vendido de dicho rubro
CLIENTE: Código del cliente que compro más productos del rubro en los últimos 30
días
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por cantidad de productos diferentes vendidos del rubro*/

--Mi planteo
SELECT R.rubr_detalle, ISNULL(SUM(item_cantidad*item_precio),0), ISNULL((SELECT TOP 1 prod_codigo FROM Producto GROUP BY prod_codigo),' ' ) [Producto mas vendido]
FROM Rubro R
INNER JOIN Producto P ON P.prod_rubro = R.rubr_id
INNER JOIN Item_Factura I ON P.prod_codigo = I.item_producto
--INNER JOIN Factura F ON F.fact_numero = I.item_numero AND F.fact_sucursal = I.item_sucursal AND F.fact_tipo = I.item_tipo
GROUP BY rubr_detalle

/*
SELECT TOP 1 fact_clie
FROM Factura
GROUP BY 
WHERE 
ORDER BY SUM(I.item_cantidad) ASC)
*/

--Solucion del profe
SELECT r.rubr_detalle, SUM(i.item_cantidad * i.item_precio) AS ventas,
(SELECT TOP 1 p2.prod_codigo
FROM producto p2 INNER JOIN Item_Factura i2 ON i2.item_producto = p2.prod_codigo
WHERE p2.prod_rubro = r.rubr_id
GROUP BY p2.prod_codigo
ORDER BY SUM(i2.item_cantidad * i2.item_precio) DESC) AS masVendido,
ISNULL((SELECT VW.prod_codigo FROM 
(SELECT ROW_NUMBER() OVER (ORDER BY SUM(i2.item_cantidad * i2.item_precio) DESC) AS orden /**/, p2.prod_codigo --ROWNUMBER lo que hace es enumerar las filas, sirve también para ordenar 
FROM producto p2 INNER JOIN Item_Factura i2 ON i2.item_producto = p2.prod_codigo
WHERE p2.prod_rubro = r.rubr_id
GROUP BY p2.prod_codigo) VW
WHERE orden = 2),'00000000') AS SegundoVendido, --Aca le digo que me traiga la fila 2
ISNULL((SELECT TOP 1 fact_cliente
	FROM Producto
	JOIN Item_Factura ON prod_codigo = item_producto
	JOIN Factura ON item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo
	WHERE fact_fecha > (SELECT DATEADD(DAY, -30, MAX(fact_fecha)) FROM Factura) AND prod_rubro = rubr_id
	GROUP BY fact_cliente
	ORDER BY SUM(item_cantidad) DESC), '--------') AS 'Cliente'
FROM rubro r
INNER JOIN producto p ON r.rubr_id = p.prod_rubro
INNER JOIN Item_Factura i ON i.item_producto = p.prod_codigo
GROUP BY r.rubr_id, r.rubr_detalle
ORDER BY COUNT(DISTINCT p.prod_codigo)


/*UN EJEMPLO DE ROWNUMBER
SELECT *
FROM (
    SELECT *, ROW_NUMBER() OVER (ORDER BY columna_orden) AS rownum
    FROM MiTabla
) AS Paginado
WHERE rownum BETWEEN 11 AND 20;

Devuelve las filas del 11 al 20
*/


SELECT 
	ISNULL(rubr_detalle, 'Sin descripcion') AS 'Rubro',
	ISNULL(SUM(item_cantidad * item_precio), 0) AS 'Ventas',
	ISNULL((SELECT TOP 1 item_producto
	FROM Producto
	JOIN Item_Factura ON prod_codigo = item_producto
	WHERE prod_rubro = rubr_id
	GROUP BY item_producto
	ORDER BY SUM(item_cantidad) DESC), 0) AS '1� Producto',
	ISNULL((SELECT TOP 1 item_producto FROM Producto
	JOIN Item_Factura ON prod_codigo = item_producto
	WHERE prod_rubro = rubr_id
	AND item_producto NOT IN
		(SELECT TOP 1 item_producto FROM Producto
		JOIN Item_Factura ON prod_codigo = item_producto
		WHERE prod_rubro = rubr_id
		GROUP BY item_producto
		ORDER BY SUM(item_cantidad) DESC) 
	GROUP BY item_producto
	ORDER BY SUM(item_cantidad) DESC), '--------') AS '2� Producto',
	ISNULL((SELECT TOP 1 fact_cliente
	FROM Producto
	JOIN Item_Factura ON prod_codigo = item_producto
	JOIN Factura ON item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo
	WHERE fact_fecha > (SELECT DATEADD(DAY, -30, MAX(fact_fecha)) FROM Factura) AND prod_rubro = rubr_id
	GROUP BY fact_cliente
	ORDER BY SUM(item_cantidad) DESC), '--------') AS 'Cliente'
FROM Rubro
JOIN Producto ON rubr_id = prod_rubro
JOIN Item_Factura ON prod_codigo = item_producto
GROUP BY rubr_id, rubr_detalle
ORDER BY COUNT(DISTINCT prod_codigo)


SELECT R.rubr_detalle ,R.rubr_id ,SUM(IFACT.item_precio * IFACT.item_cantidad)
	,ISNULL((
		SELECT TOP 1 item_producto
		FROM Producto
			INNER JOIN Item_Factura
				ON item_producto = prod_codigo
		WHERE R.rubr_id = prod_rubro
		GROUP BY item_producto
		ORDER BY SUM(item_cantidad)DESC
		),0) AS [Cod del prod mas vendido]
	,ISNULL((
		SELECT TOP 1 item_producto
		FROM Producto
			INNER JOIN Item_Factura ON item_producto = prod_codigo
		WHERE R.rubr_id = prod_rubro
			AND prod_codigo <> (
									SELECT TOP 1 item_producto
									FROM Producto
										INNER JOIN Item_Factura ON item_producto = prod_codigo
									WHERE R.rubr_id = prod_rubro
									GROUP BY item_producto
									ORDER BY SUM(item_cantidad)DESC
									)
		GROUP BY item_producto
		ORDER BY SUM(item_cantidad)DESC
		),0) AS [Cod del segundo prod mas vendido]
	,ISNULL((
		SELECT TOP 1 fact_cliente
		FROM Producto
			INNER JOIN Item_Factura ON item_producto = prod_codigo
			INNER JOIN Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
		WHERE prod_rubro = R.rubr_id --AND fact_fecha BETWEEN GETDATE() AND (GETDATE()-30)
			AND fact_fecha > DATEADD(DAY,-30,(SELECT MAX(fact_fecha) FROM Factura))--
			--AND fact_fecha BETWEEN DATEADD(DAY,-30,(SELECT MAX(fact_fecha) FROM Factura)) AND (SELECT MAX(fact_fecha) FROM Factura)
		GROUP BY fact_cliente
		ORDER BY SUM(item_cantidad) DESC ),'-') AS [Cod CLiente]
FROM RUBRO R
INNER JOIN Producto P ON P.prod_rubro = R.rubr_id
INNER JOIN Item_Factura IFACT ON IFACT.item_producto = P.prod_codigo
GROUP BY R.rubr_detalle,R.rubr_id
ORDER BY COUNT(DISTINCT IFACT.item_producto)

/*19. En virtud de una recategorizacion de productos referida a la familia de los mismos se
solicita que desarrolle una consulta sql que retorne para todos los productos:
 Codigo de producto
 Detalle del producto
 Codigo de la familia del producto
 Detalle de la familia actual del producto
 Codigo de la familia sugerido para el producto
 Detalla de la familia sugerido para el producto
La familia sugerida para un producto es la que poseen la mayoria de los productos cuyo
detalle coinciden en los primeros 5 caracteres.
En caso que 2 o mas familias pudieran ser sugeridas se debera seleccionar la de menor
codigo. Solo se deben mostrar los productos para los cuales la familia actual sea
diferente a la sugerida
Los resultados deben ser ordenados por detalle de producto de manera ascendente
*/

--Otra solucion mia, tarda mucho más que la del otro pibe, es por el LEFT JOIN--
SELECT P1.prod_codigo, p1.prod_detalle, P1.prod_familia, F1.fami_detalle, (SELECT TOP 1 prod_familia
FROM Producto p2 
WHERE LEFT(P1.prod_detalle,5) LIKE LEFT(p2.prod_detalle,5)
GROUP BY prod_familia
ORDER BY COUNT(*) DESC, prod_familia ASC) AS [Codigo familia sugerida]
FROM Producto P1
LEFT JOIN Familia F1 ON P1.prod_familia = F1.fami_id
WHERE P1.prod_familia NOT LIKE (SELECT TOP 1 prod_familia
FROM Producto p2 
WHERE LEFT(P1.prod_detalle,5) LIKE LEFT(p2.prod_detalle,5)
GROUP BY prod_familia
ORDER BY COUNT(*) DESC, prod_familia ASC)
GROUP BY prod_codigo, prod_detalle, p1.prod_familia, fami_detalle
ORDER BY prod_detalle ASC

--Solucion mia
SELECT prod_codigo, prod_detalle, prod_familia, (SELECT TOP 1 p2.prod_codigo
FROM Producto p2
WHERE LEFT(P1.prod_detalle,5) LIKE LEFT(p2.prod_detalle,5)
ORDER BY p2.prod_codigo ASC) AS [Familia sugerida]
FROM Producto P1
WHERE P1.prod_familia NOT LIKE (SELECT TOP 1 p2.prod_codigo
FROM Producto p2
WHERE LEFT(P1.prod_detalle,5) LIKE LEFT(p2.prod_detalle,5)
ORDER BY p2.prod_codigo ASC)
GROUP BY prod_codigo, prod_detalle, prod_familia
ORDER BY prod_detalle ASC


--Solucion de otro--
SELECT P.prod_codigo ,P.prod_detalle ,FAM.fami_id ,FAM.fami_detalle
	,(
		SELECT TOP 1 prod_familia
		FROM Producto
		WHERE SUBSTRING(prod_detalle, 1, 5) = SUBSTRING(P.prod_detalle, 1, 5)
		GROUP BY prod_familia
		ORDER BY COUNT(*) DESC, prod_familia
		) AS [ID familia recomendada]
	,(
		SELECT fami_detalle
		FROM Familia
		WHERE fami_id = (
			SELECT TOP 1 prod_familia
			FROM Producto
			WHERE SUBSTRING(prod_detalle, 1, 5) = SUBSTRING(P.prod_detalle, 1, 5)
			GROUP BY prod_familia
			ORDER BY COUNT(*) DESC, prod_familia
			)
		) AS [Detalle Familia Recomendada]

FROM Producto P
	INNER JOIN Familia FAM
		ON FAM.fami_id = P.prod_familia
WHERE FAM.fami_id <> ( --Esos simbolos significa que tienen que ser distinto
		SELECT TOP 1 prod_familia
		FROM Producto
		WHERE SUBSTRING(prod_detalle, 1, 5) = SUBSTRING(P.prod_detalle, 1, 5)
		GROUP BY prod_familia
		ORDER BY COUNT(*) DESC, prod_familia
		) --Magia para que no repita (Que el fami ID no sea igual al que trae por default)
Order BY 2

/*20. Escriba una consulta sql que retorne un ranking de los mejores 3 empleados del 2012
Se debera retornar legajo, nombre y apellido, anio de ingreso, puntaje 2011, puntaje
2012. El puntaje de cada empleado se calculara de la siguiente manera: para los que
hayan vendido al menos 50 facturas el puntaje se calculara como la cantidad de facturas
que superen los 100 pesos que haya vendido en el año, para los que tengan menos de 50
facturas en el año el calculo del puntaje sera el 50% de cantidad de facturas realizadas
por sus subordinados directos en dicho año.
*/

--ESTO ESTA COMO EL OJETE--
SELECT TOP 3 E.empl_codigo, E.empl_nombre, E.empl_apellido, E.empl_ingreso,
	(SELECT 
CASE WHEN COUNT (*) >= 50 THEN (SELECT COUNT(*) FROM Factura WHERE fact_total >100)
	 WHEN COUNT (*) < 50 THEN (SELECT COUNT (*)*0,5 FROM Factura WHERE E2.empl_codigo = empl_jefe)
	 END AS [Puntaje 2012] 
FROM Factura F2
INNER JOIN Empleado E2 ON E2.empl_codigo = F2.fact_vendedor
WHERE YEAR(fact_fecha) = 2012)
FROM Empleado E
ORDER BY empl_codigo

--ESTE ESTÁ BIEN--
SELECT TOP 3 E.empl_codigo ,E.empl_nombre ,E.empl_apellido ,E.empl_ingreso
	,CASE
		WHEN (
				SELECT COUNT(fact_vendedor)
				FROM Factura
				WHERE E.empl_codigo = fact_vendedor
					AND YEAR(fact_fecha) = 2011) >= 50 
		THEN (
				SELECT COUNT(*) 
				FROM FACTURA
				WHERE fact_total > 100
					AND E.empl_codigo = fact_vendedor
					AND YEAR(fact_fecha) = 2011
			)
		ELSE (
				SELECT COUNT(*) * 0.5
				FROM Factura
				WHERE fact_vendedor IN (
											SELECT empl_codigo
											FROM Empleado
											WHERE empl_jefe = E.empl_codigo
										)
					AND YEAR(fact_fecha) = 2011
			)													   
	END 'Puntaje 2011'
	,CASE
		WHEN (
				SELECT COUNT(fact_vendedor)
				FROM Factura
				WHERE E.empl_codigo = fact_vendedor
					AND YEAR(fact_fecha) = 2012) >= 50 
		THEN (
				SELECT COUNT(*) 
				FROM FACTURA
				WHERE fact_total > 100
					AND E.empl_codigo = fact_vendedor
					AND YEAR(fact_fecha) = 2012
			)
		ELSE (
				SELECT COUNT(*) * 0.5
				FROM Factura
				WHERE fact_vendedor IN (
											SELECT empl_codigo
											FROM Empleado
											WHERE empl_jefe = E.empl_codigo
										)
					AND YEAR(fact_fecha) = 2012
			)													   
	END 'Puntaje 2012'
FROM Empleado E
ORDER BY 6 DESC



/*21. Escriba una consulta sql que retorne para todos los años, en los cuales se haya hecho al
menos una factura, la cantidad de clientes a los que se les facturo de manera incorrecta
al menos una factura y que cantidad de facturas se realizaron de manera incorrecta. Se
considera que una factura es incorrecta cuando la diferencia entre el total de la factura
menos el total de impuesto tiene una diferencia mayor a $ 1 respecto a la sumatoria de
los costos de cada uno de los items de dicha factura. Las columnas que se deben mostrar
son:
 Año
 Clientes a los que se les facturo mal en ese año
 Facturas mal realizadas en ese año
*/

--Solucion mia-- Mal, pero ni tanto, ah
SELECT YEAR(fact_fecha), COUNT (*), COUNT (DISTINCT fact_cliente)
FROM (SELECT *
FROM Factura F 
INNER JOIN Item_Factura I ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
INNER JOIN Producto P ON item_producto = prod_codigo
WHERE (fact_total - fact_total_impuestos) - (SELECT SUM (prod_precio) FROM Producto P2 INNER JOIN Item_Factura I2 ON item_producto = prod_codigo  ) > 1) FI



--Solucion de otro--
SELECT YEAR(fact_fecha) AS [AÑO]
		,COUNT(DISTINCT F.fact_cliente) AS [Clientes mal facturados]
		,COUNT(DISTINCT F.fact_tipo + F.fact_sucursal + F.fact_numero) AS [FACTURAS MAL REALIZADAS]
FROM FACTURA F
WHERE (F.fact_total-F.fact_total_impuestos) NOT BETWEEN (
												SELECT SUM(item_cantidad * item_precio)-1
												FROM Item_Factura
												WHERE item_numero+item_sucursal+item_tipo = F.fact_numero+F.fact_sucursal+F.fact_tipo
												)
												AND
												(
												SELECT SUM(item_cantidad * item_precio)+1
												FROM Item_Factura
												WHERE item_numero+item_sucursal+item_tipo = F.fact_numero+F.fact_sucursal+F.fact_tipo
												)
GROUP BY YEAR(fact_fecha)


/*22. Escriba una consulta sql que retorne una estadistica de venta para todos los rubros por 
trimestre contabilizando todos los años. Se mostraran como maximo 4 filas por rubro (1 
por cada trimestre).
Se deben mostrar 4 columnas:
 Detalle del rubro
 Numero de trimestre del año (1 a 4)
 Cantidad de facturas emitidas en el trimestre en las que se haya vendido al 
menos un producto del rubro
 Cantidad de productos diferentes del rubro vendidos en el trimestre 
El resultado debe ser ordenado alfabeticamente por el detalle del rubro y dentro de cada 
rubro primero el trimestre en el que mas facturas se emitieron.
No se deberan mostrar aquellos rubros y trimestres para los cuales las facturas emitiadas 
no superen las 100.
En ningun momento se tendran en cuenta los productos compuestos para esta 
estadistica.*/

--Mi solucion--
SELECT R.rubr_detalle , 
CASE WHEN MONTH(F.fact_fecha) BETWEEN  1 AND 3 THEN 1
	 WHEN MONTH(F.fact_fecha) BETWEEN  4 AND 6 THEN 2
	 WHEN MONTH(F.fact_fecha) BETWEEN  7 AND 9 THEN 3
	 WHEN MONTH(F.fact_fecha) BETWEEN  10 AND 12 THEN 4
	 END AS [Numero de trimestre]
FROM Rubro R
	INNER JOIN Producto P ON P.prod_rubro = R.rubr_id
	INNER JOIN Item_Factura IFACT ON IFACT.item_producto = P.prod_codigo
	INNER JOIN Factura F ON IFACT.item_numero = F.fact_numero AND IFACT.item_sucursal = F.fact_sucursal AND IFACT.item_tipo = F.fact_tipo

SELECT COUNT(*)


--Solucion de otro--
SELECT R.rubr_detalle
	,CASE WHEN MONTH(F.fact_fecha) BETWEEN  1 AND 3 THEN 1
	 WHEN MONTH(F.fact_fecha) BETWEEN  4 AND 6 THEN 2
	 WHEN MONTH(F.fact_fecha) BETWEEN  7 AND 9 THEN 3
	 WHEN MONTH(F.fact_fecha) BETWEEN  10 AND 12 THEN 4
	 END AS [Numero de trimestre]

	,COUNT(DISTINCT F.fact_tipo+F.fact_numero+F.fact_sucursal) [Cantidad de facturas emitidas]
	,COUNT(DISTINCT IFACT.item_producto)
	,YEAR(F.fact_fecha)
FROM Rubro R
	INNER JOIN Producto P ON P.prod_rubro = R.rubr_id
	INNER JOIN Item_Factura IFACT ON IFACT.item_producto = P.prod_codigo
	INNER JOIN Factura F ON IFACT.item_numero = F.fact_numero AND IFACT.item_sucursal = F.fact_sucursal AND IFACT.item_tipo = F.fact_tipo
	--Verifico que no sea un producto compuesto
WHERE P.prod_codigo NOT IN (
							SELECT comp_producto
							FROM Composicion
							)
--Los agrupo por , rubro, trimestre y año
GROUP BY R.rubr_detalle ,
CASE WHEN MONTH(F.fact_fecha) BETWEEN  1 AND 3 THEN 1
	 WHEN MONTH(F.fact_fecha) BETWEEN  4 AND 6 THEN 2
	 WHEN MONTH(F.fact_fecha) BETWEEN  7 AND 9 THEN 3
	 WHEN MONTH(F.fact_fecha) BETWEEN  10 AND 12 THEN 4
	 END ,
	YEAR(F.fact_fecha)
HAVING COUNT(DISTINCT F.fact_tipo+F.fact_numero+F.fact_sucursal) > 100
ORDER BY 1,3 DESC

/*23. Realizar una consulta SQL que para cada año muestre :
 Año
 El producto con composición más vendido para ese año.
 Cantidad de productos que componen directamente al producto más vendido
 La cantidad de facturas en las cuales aparece ese producto.
 El código de cliente que más compro ese producto.
 El porcentaje que representa la venta de ese producto respecto al total de venta 
del año.
El resultado deberá ser ordenado por el total vendido por año en forma descendente*/

--Solucion mia--
SELECT YEAR(fact_fecha), 
--Producto mas vendido-- Esto esta OK
(SELECT TOP 1 prod_detalle
FROM Producto P
INNER JOIN Item_Factura I ON I.item_producto = P.prod_codigo
INNER JOIN Factura F ON I.item_numero = F.fact_numero AND I.item_sucursal = F.fact_sucursal AND I.item_tipo = F.fact_tipo
WHERE P.prod_codigo IN (
							SELECT comp_producto
							FROM Composicion
							)
GROUP BY P.prod_codigo, P.prod_detalle
ORDER BY SUM(I.item_cantidad) DESC) [Producto mas vendido],
COUNT(DISTINCT F.fact_tipo+F.fact_numero+F.fact_sucursal) [Cant Facturas]
FROM Producto P
INNER JOIN Composicion C ON C.comp_producto = P.prod_codigo
INNER JOIN Item_Factura I ON I.item_producto = P.prod_codigo
INNER JOIN Factura F ON I.item_numero = F.fact_numero AND I.item_sucursal = F.fact_sucursal AND I.item_tipo = F.fact_tipo
GROUP BY YEAR(fact_fecha)
ORDER BY 3 DESC

/*
SELECT TOP 1 prod_detalle
FROM Producto P
INNER JOIN Item_Factura I ON I.item_producto = P.prod_codigo
INNER JOIN Factura F ON I.item_numero = F.fact_numero AND I.item_sucursal = F.fact_sucursal AND I.item_tipo = F.fact_tipo
WHERE P.prod_codigo IN (
							SELECT comp_producto
							FROM Composicion
							)
GROUP BY P.prod_codigo, P.prod_detalle
ORDER BY SUM(I.item_cantidad) DESC*/


--solucion de otro--



SELECT YEAR(F1.fact_fecha)
	,IFACT1.item_producto
	,(
		SELECT COUNT(*)
		FROM Producto Prod
			INNER JOIN Composicion C ON C.comp_producto = Prod.prod_codigo
			INNER JOIN Producto Componente ON Componente.prod_codigo = C.comp_componente
		WHERE Prod.prod_codigo = IFACT1.item_producto
	) AS [Productos que componen el mas vendido]
	,(
		SELECT COUNT(DISTINCT F.fact_numero+F.fact_sucursal+F.fact_tipo)
		FROM Factura F
			INNER JOIN Item_Factura IFACT ON F.fact_tipo = IFACT.item_tipo AND F.fact_numero = IFACT.item_numero AND F.fact_sucursal = IFACT.item_sucursal
			INNER JOIN Producto Prod ON Prod.prod_codigo = IFACT.item_producto
			INNER JOIN Composicion C ON C.comp_producto = Prod.prod_codigo
		WHERE Prod.prod_codigo = IFACT1.item_producto AND YEAR(F.fact_fecha) = YEAR(F1.fact_fecha)
	) AS [Cantidad de facturas]
	--Cliente que mas compro--
	,(
		SELECT TOP 1 F.fact_cliente
		FROM Factura F
			INNER JOIN Item_Factura IFACT ON F.fact_tipo = IFACT.item_tipo AND F.fact_numero = IFACT.item_numero AND F.fact_sucursal = IFACT.item_sucursal
		WHERE IFACT.item_producto = IFACT1.item_producto AND YEAR(F.fact_fecha) = YEAR(F1.fact_fecha)
		GROUP BY F.fact_cliente
		ORDER BY SUM(IFACT.item_cantidad) DESC
	)
	--Promedio respecto a las ventas
	,(
		SELECT ( SUM(IFACT.item_cantidad) /
					(
						SELECT TOP 1 SUM(item_cantidad)
						FROM Item_Factura
							INNER JOIN Factura ON fact_numero = item_numero AND fact_tipo = item_tipo AND fact_sucursal = item_sucursal
						WHERE YEAR(fact_fecha) = YEAR(F1.fact_fecha)
					) *100
					
				)
		FROM Factura F
			INNER JOIN Item_Factura IFACT ON F.fact_tipo = IFACT.item_tipo AND F.fact_numero = IFACT.item_numero AND F.fact_sucursal = IFACT.item_sucursal
		WHERE IFACT.item_producto = IFACT1.item_producto AND YEAR(F.fact_fecha) = YEAR(F1.fact_fecha)
	)
FROM Factura F1
	INNER JOIN Item_Factura IFACT1 ON F1.fact_tipo = IFACT1.item_tipo AND F1.fact_numero = IFACT1.item_numero AND F1.fact_sucursal = IFACT1.item_sucursal
--Saco al top 1 de producto compuesto
WHERE IFACT1.item_producto = (
								SELECT TOP 1 P.prod_codigo
								FROM Producto P
									INNER JOIN Composicion C ON C.comp_producto = P.prod_codigo
									INNER JOIN Item_Factura IFACT ON IFACT.item_producto = P.prod_codigo
									INNER JOIN Factura F ON F.fact_tipo = IFACT.item_tipo AND F.fact_numero = IFACT.item_numero AND F.fact_sucursal = IFACT.item_sucursal
								WHERE YEAR(F1.fact_fecha) = YEAR(F.fact_fecha)
								ORDER BY (IFACT.item_producto * IFACT.item_cantidad) DESC
							)						
GROUP BY YEAR(F1.fact_fecha),IFACT1.item_producto
ORDER BY SUM(IFACT1.item_cantidad) DESC


/*24. Escriba una consulta que considerando solamente las facturas correspondientes a los 
dos vendedores con mayores comisiones, retorne los productos con composición 
facturados al menos en cinco facturas,
La consulta debe retornar las siguientes columnas:
 Código de Producto
 Nombre del Producto
 Unidades facturadas
El resultado deberá ser ordenado por las unidades facturadas descendente.*/
--Solucion mia, ni tan mal
SELECT prod_codigo, prod_detalle, COUNT(DISTINCT F.fact_tipo+F.fact_numero+F.fact_sucursal) AS [Unidades facturadas]
FROM Factura F
INNER JOIN Item_Factura I ON I.item_numero = F.fact_numero AND I.item_sucursal = F.fact_sucursal AND I.item_tipo = F.fact_tipo
INNER JOIN  Producto P ON I.item_producto = P.prod_codigo
WHERE fact_vendedor IN (
	SELECT TOP 2 empl_codigo, empl_comision
	FROM Empleado E2
	--GROUP BY E2.empl_codigo
	ORDER BY E2.empl_comision DESC ) AND P.prod_codigo IN ( SELECT comp_producto FROM Composicion)
GROUP BY prod_codigo, prod_detalle
HAVING COUNT(DISTINCT F.fact_tipo+F.fact_numero+F.fact_sucursal) >= 5
ORDER BY 3 DESC

--Solucion de otro--
SELECT Prod.prod_codigo ,Prod.prod_detalle ,SUM(IFACT.item_cantidad) AS [Unidades Facturadas]
FROM Producto Prod
	INNER JOIN Item_Factura IFACT ON IFACT.item_producto = Prod.prod_codigo
	INNER JOIN Factura F ON F.fact_numero = IFACT.item_numero AND F.fact_sucursal = IFACT.item_sucursal AND F.fact_tipo = IFACT.item_tipo
WHERE F.fact_vendedor IN (
							SELECT TOP 2 empl_codigo
							FROM Empleado
							ORDER BY empl_comision DESC
							)
							AND
	Prod.prod_codigo IN (
							SELECT comp_producto
							FROM Composicion
							)
GROUP BY Prod.prod_codigo,Prod.prod_detalle
HAVING COUNT(IFACT.item_producto) > 5
ORDER BY 3 DESC		


/*25. Realizar una consulta SQL que para cada año y familia muestre :
a. Año
b. El código de la familia más vendida en ese año.
c. Cantidad de Rubros que componen esa familia.
d. Cantidad de productos que componen directamente al producto más vendido de 
esa familia.
e. La cantidad de facturas en las cuales aparecen productos pertenecientes a esa 
familia.
f. El código de cliente que más compro productos de esa familia.
g. El porcentaje que representa la venta de esa familia respecto al total de venta 
del año.
El resultado deberá ser ordenado por el total vendido por año y familia en forma 
descendente.*/

SELECT YEAR(F.fact_fecha) AS [AÑO] ,FAM.fami_id
	,COUNT(DISTINCT P.prod_rubro) AS [CANTIDAD DE RUBROS QUE COMPONEN LA FAMILIA (SUBDIVIDO ANUALMENTE)]
	,CASE 
		WHEN(
				(
		SELECT TOP 1 prod_codigo
		FROM Producto
			INNER JOIN Item_Factura ON item_producto = prod_codigo
			INNER JOIN Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
		WHERE prod_familia = FAM.fami_id AND YEAR(fact_fecha) = YEAR(F.fact_fecha)
		GROUP BY prod_codigo
		ORDER BY SUM(item_cantidad) DESC
		) IN (
		
				SELECT comp_producto
				FROM Composicion
			)
		)
		THEN (
				SELECT COUNT(*)
				FROM Composicion
				WHERE comp_producto = (
										SELECT TOP 1 prod_codigo
										FROM Producto 
											INNER JOIN Item_Factura ON item_producto = prod_codigo
											INNER JOIN Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
										WHERE prod_familia = FAM.fami_id AND YEAR(fact_fecha) = YEAR(F.fact_fecha)
										GROUP BY prod_codigo
										ORDER BY SUM(item_cantidad) DESC
										)
		)
		ELSE 1
	END AS [CANT DE PROD QUE CONFORMAN EL MAS VENDIDO]
	,COUNT(DISTINCT F.fact_tipo+F.fact_numero+F.fact_sucursal) AS [CANT FACTURAS EN LOS QUE APARECEN PRODS DE LA FAMI]
	,(
		SELECT TOP 1 fact_cliente
		FROM Factura
			INNER JOIN Item_Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
			INNER JOIN Producto	ON prod_codigo = item_producto
		WHERE prod_familia = FAM.fami_id AND YEAR(fact_fecha) = YEAR(F.fact_fecha)
		GROUP BY fact_cliente
		ORDER BY SUM(item_cantidad) DESC
		) AS [CLIENTE QUE MAS COMPRO DE LA FAMILIA]
	,(SUM(IFACT.item_cantidad*IFACT.item_precio) *100) / (
													SELECT SUM(item_cantidad * item_precio)
													FROM Factura
														INNER JOIN Item_Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
														INNER JOIN Producto	ON prod_codigo = item_producto
													WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha)
													) AS [PORCENTAJE VENDIDO POR FAMILIA VS TOTAL ANUAL]
FROM FAMILIA FAM
	INNER JOIN Producto P ON P.prod_familia = FAM.fami_id
	INNER JOIN Rubro R ON R.rubr_id = P.prod_rubro
	INNER JOIN Item_Factura IFACT ON IFACT.item_producto = P.prod_codigo
	INNER JOIN Factura F ON  F.fact_numero = IFACT.item_numero AND F.fact_sucursal = IFACT.item_sucursal AND F.fact_tipo = IFACT.item_tipo
--Familia mas vendida
WHERE FAM.fami_id = (
						SELECT TOP 1 prod_familia
						FROM Producto
							INNER JOIN Item_Factura ON item_producto = prod_codigo
							INNER JOIN Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
						GROUP BY prod_familia
						ORDER BY SUM(item_cantidad) DESC
						)

GROUP BY YEAR(F.fact_fecha),FAM.fami_id
ORDER BY SUM(IFACT.item_cantidad*IFACT.item_precio) DESC, 2


/*26. Escriba una consulta sql que retorne un ranking de empleados devolviendo las 
siguientes columnas:
 Empleado
 Depósitos que tiene a cargo
 Monto total facturado en el año corriente
 Codigo de Cliente al que mas le vendió
 Producto más vendido
 Porcentaje de la venta de ese empleado sobre el total vendido ese año.
Los datos deberan ser ordenados por venta del empleado de mayor a menor.*/

SELECT E.empl_codigo ,COUNT(DISTINCT D.depo_codigo) [Cant Depositos que tiene a cargo]
	,(
		SELECT SUM(fact_total)
		FROM Factura
		WHERE fact_vendedor = E.empl_codigo AND YEAR(fact_fecha) = YEAR(F.fact_fecha)
		
		) AS [Monto total facturado en el año corriente]
	,(							
		SELECT TOP 1 fact_cliente
		FROM Factura
		WHERE fact_vendedor = E.empl_codigo AND YEAR(fact_fecha) = YEAR(F.fact_fecha)
		GROUP BY fact_cliente
		ORDER BY SUM(fact_total) DESC
	) AS [Codigo Cliente al que mas vendio]
	,(
		SELECT TOP 1 item_producto
		FROM Item_Factura
			INNER JOIN Factura
				ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
		WHERE fact_vendedor = E.empl_codigo AND YEAR(fact_fecha) = YEAR(F.fact_fecha)
		GROUP BY item_producto
		ORDER BY SUM(item_cantidad) DESC
	) AS [Producto mas vendido]
	,((
		SELECT SUM(fact_total)
		FROM Factura
		WHERE fact_vendedor = E.empl_codigo AND YEAR(fact_fecha) = YEAR(F.fact_fecha)
	)
	 *100) / (
				SELECT SUM(fact_total)
				FROM Factura
				WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha)
				) AS [Porcentaje vendido por el empleado sobre el total anual]

FROM EMPLEADO E
	LEFT OUTER JOIN DEPOSITO D ON D.depo_encargado = E.empl_codigo
	LEFT OUTER JOIN Factura F ON F.fact_vendedor = E.empl_codigo
WHERE YEAR(F.fact_fecha) = 2012--YEAR(GETDATE())
GROUP BY E.empl_codigo, YEAR(F.fact_fecha)
ORDER BY 3 DESC

/*27. Escriba una consulta sql que retorne una estadística basada en la facturacion por año y
envase devolviendo las siguientes columnas:
- Año
- Codigo de envase
- Detalle del envase
- Cantidad de productos que tienen ese envase
- Cantidad de productos facturados de ese envase
- Producto mas vendido de ese envase
- Monto total de venta de ese envase en ese año
- Porcentaje de la venta de ese envase respecto al total vendido de ese año
Los datos deberan ser ordenados*/

SELECT YEAR(F.fact_fecha)
	,E.enva_codigo
	,E.enva_detalle
	,COUNT (DISTINCT IFACT.item_producto) AS [Cantidad de productos facturados para ese envase]
	,SUM (IFACT.item_cantidad) AS [Cantidad de productos facturados para ese envase]
	,(
		SELECT TOP 1 item_producto
		FROM Producto
			INNER JOIN Item_Factura
				ON item_producto = prod_codigo
			INNER JOIN Factura
				ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
		WHERE prod_envase = E.enva_codigo AND YEAR(fact_fecha) = YEAR(F.fact_fecha)
		GROUP BY item_producto
		ORDER BY SUM(item_cantidad) DESC
		) AS [Producto mas vendido del envase]
	,SUM(IFACT.item_precio * IFACT.item_cantidad) AS [Monto Total de venta del envase]
	,(SUM(IFACT.item_precio * IFACT.item_cantidad) *100) / (
															SELECT SUM(fact_total)
															FROM Factura
															WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha)
															) AS [Procentaje de la venta respecto al total]
FROM Producto P
	INNER JOIN Envases E
		ON E.enva_codigo = P.prod_envase
	INNER JOIN Item_Factura IFACT
		ON IFACT.item_producto = P.prod_codigo
	INNER JOIN Factura F
		ON F.fact_numero = IFACT.item_numero AND F.fact_sucursal = IFACT.item_sucursal AND F.fact_tipo = IFACT.item_tipo
GROUP BY YEAR(F.fact_fecha),E.enva_codigo,E.enva_detalle
ORDER BY 1,2



-------------------------------------------------------------------------------------------------------------------------

SELECT YEAR(F.fact_fecha)
	,E.enva_codigo
	,E.enva_detalle
	,COUNT (DISTINCT IFACT.item_producto) AS [Cantidad de productos facturados para ese envase]
	,SUM (IFACT.item_cantidad) AS [Cantidad de productos facturados para ese envase]
	,(
		SELECT TOP 1 item_producto
		FROM Producto
			INNER JOIN Item_Factura
				ON item_producto = prod_codigo
			INNER JOIN Factura
				ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
		WHERE prod_envase = E.enva_codigo AND YEAR(fact_fecha) = YEAR(F.fact_fecha)
		GROUP BY item_producto
		ORDER BY SUM(item_cantidad) DESC
		) AS [Producto mas vendido del envase]
	,SUM(IFACT.item_precio * IFACT.item_cantidad) AS [Monto Total de venta del envase]
	,(SUM(IFACT.item_precio * IFACT.item_cantidad) *100) / (
															SELECT SUM(item_precio * item_cantidad)
															FROM Item_Factura
																INNER JOIN Factura
																	ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
															WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha)
															) AS [Procentaje de la venta respecto al total]
FROM Producto P
	INNER JOIN Envases E
		ON E.enva_codigo = P.prod_envase
	INNER JOIN Item_Factura IFACT
		ON IFACT.item_producto = P.prod_codigo
	INNER JOIN Factura F
		ON F.fact_numero = IFACT.item_numero AND F.fact_sucursal = IFACT.item_sucursal AND F.fact_tipo = IFACT.item_tipo
GROUP BY YEAR(F.fact_fecha),E.enva_codigo,E.enva_detalle
ORDER BY 1,2


/*28. Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las
siguientes columnas:
- Año.
- Codigo de Vendedor
- Detalle del Vendedor
- Cantidad de facturas que realizó en ese año
- Cantidad de clientes a los cuales les vendió en ese año.
- Cantidad de productos facturados con composición en ese año
- Cantidad de productos facturados sin composicion en ese año.
- Monto total vendido por ese vendedor en ese año
Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya
vendido mas productos diferentes de mayor a menor.*/

SELECT YEAR(fact_fecha)
	,F.fact_vendedor
	,E.empl_nombre
	,E.empl_apellido
	,COUNT(DISTINCT F.fact_numero+F.fact_sucursal+F.fact_tipo) AS [Cantidad de facturas realizadas]
	,COUNT(DISTINCT F.fact_cliente) AS [Cantidad de clientes a los que se vendió]
	,(
		SELECT COUNT(DISTINCT prod_codigo)
		FROM Producto
			INNER JOIN Composicion
				ON comp_producto = prod_codigo
			INNER JOIN Item_Factura
				ON item_producto = prod_codigo
			INNER JOIN Factura
				ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
		WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha) AND fact_vendedor = F.fact_vendedor
		) AS [Cantidad de productos facturados con composicion]
	,(
		SELECT COUNT(DISTINCT prod_codigo)
		FROM Producto
			INNER JOIN Item_Factura
				ON item_producto = prod_codigo
			INNER JOIN Factura
				ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
		WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha) AND fact_vendedor = F.fact_vendedor AND prod_codigo NOT IN (SELECT comp_producto FROM Composicion)
		) AS [Cantidad de productos facturados sin composicion]
	,SUM(F.fact_total)
FROM Factura F
	INNER JOIN Empleado E
		ON E.empl_codigo = F.fact_vendedor 
GROUP BY YEAR(fact_fecha),F.fact_vendedor,E.empl_nombre,E.empl_apellido
ORDER BY 1 DESC, (
					SELECT COUNT(DISTINCT prod_codigo)
					FROM Producto
						INNER JOIN Item_Factura
							ON item_producto = prod_codigo
						INNER JOIN Factura
							ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
					WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha) AND fact_vendedor = F.fact_vendedor
					) DESC

/* 29. Se solicita que realice una estadística de venta por producto para el año 2011, solo para
los productos que pertenezcan a las familias que tengan más de 20 productos asignados
a ellas, la cual deberá devolver las siguientes columnas:
a. Código de producto
b. Descripción del producto
c. Cantidad vendida
d. Cantidad de facturas en la que esta ese producto
e. Monto total facturado de ese producto
Solo se deberá mostrar un producto por fila en función a los considerandos establecidos
antes. El resultado deberá ser ordenado por el la cantidad vendida de mayor a menor.*/

SELECT P.prod_codigo
	,P.prod_detalle
	,SUM(IFACT.item_cantidad) AS [Cantidad Vendido]
	,COUNT(DISTINCT F.fact_tipo+F.fact_sucursal+F.fact_numero) AS [Cantidad de facturas]
	,SUM(IFACT.item_precio*IFACT.item_cantidad) AS [Monto total facturado sin impuestos]
FROM Producto P
	INNER JOIN Familia FAM
		ON FAM.fami_id = P.prod_familia
	INNER JOIN Item_Factura IFACT
		ON IFACT.item_producto = P.prod_codigo
	INNER JOIN Factura F
		ON F.fact_numero = IFACT.item_numero AND F.fact_sucursal = IFACT.item_sucursal AND F.fact_tipo = IFACT.item_tipo
WHERE YEAR(F.fact_fecha) = 2011
GROUP BY P.prod_codigo, P.prod_detalle, FAM.fami_id
HAVING (
		SELECT COUNT(DISTINCT prod_codigo)
		FROM Producto
			INNER JOIN Familia
				ON fami_id = prod_familia
		WHERE fami_id = FAM.fami_id

		GROUP BY fami_id
		) > 20

ORDER BY 4 DESC

/*30. Se desea obtener una estadistica de ventas del año 2012, para los empleados que sean 
jefes, o sea, que tengan empleados a su cargo, para ello se requiere que realice la 
consulta que retorne las siguientes columnas:
 Nombre del Jefe
 Cantidad de empleados a cargo
 Monto total vendido de los empleados a cargo
 Cantidad de facturas realizadas por los empleados a cargo
 Nombre del empleado con mejor ventas de ese jefe
Debido a la perfomance requerida, solo se permite el uso de una subconsulta si fuese 
necesario.
Los datos deberan ser ordenados por de mayor a menor por el Total vendido y solo se 
deben mostrarse los jefes cuyos subordinados hayan realizado más de 10 facturas.*/

SELECT J.empl_nombre
	,J.empl_apellido
	,SUM(ISNULL(F.fact_total,0)) AS [Monto total vendido empleados]
	,COUNT(DISTINCT E.empl_codigo) AS [Cantidad de empleados a cargo]
	,COUNT(F.fact_vendedor) [Cantidad de facturas]
	,(
		SELECT TOP 1 empl_codigo
		FROM Empleado
			INNER JOIN Factura
				ON fact_vendedor = empl_codigo
		WHERE empl_jefe = J.empl_codigo AND YEAR(fact_fecha) = YEAR(F.fact_fecha)
		GROUP BY empl_codigo
		ORDER BY SUM(fact_total) DESC
		) AS [Empleado con mejor ventas ]
FROM Empleado J
	INNER JOIN Empleado E ON E.empl_jefe = J.empl_codigo
	LEFT JOIN Factura F ON F.fact_vendedor = E.empl_codigo
WHERE YEAR(F.fact_fecha) = 2012
GROUP BY J.empl_nombre, J.empl_apellido, J.empl_codigo, YEAR(F.fact_fecha)
HAVING COUNT(F.fact_numero+F.fact_tipo+F.fact_sucursal) > 10
ORDER BY 4 DESC

/*31. Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las
siguientes columnas:
- Año.
- Codigo de Vendedor
- Detalle del Vendedor
- Cantidad de facturas que realizó en ese año
- Cantidad de clientes a los cuales les vendió en ese año.
- Cantidad de productos facturados con composición en ese año
- Cantidad de productos facturados sin composicion en ese año.
- Monto total vendido por ese vendedor en ese año
Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya
vendido mas productos diferentes de mayor a menor.*/

SELECT YEAR(F.fact_fecha) AS [Año]
	,E.empl_codigo
	,E.empl_nombre
	,E.empl_apellido
	,COUNT(DISTINCT F.fact_tipo+F.fact_tipo+F.fact_numero) AS [Cantidad de facturas realizadas]
	,COUNT(DISTINCT F.fact_cliente) AS [Cantidad de clientes a los que se le facturo]
	,(
		SELECT SUM(item_cantidad)
		FROM Item_Factura
			INNER JOIN Factura
				ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
		WHERE fact_vendedor = E.empl_codigo 
			AND YEAR(fact_fecha) = YEAR(F.fact_fecha)
			AND item_producto IN (
									SELECT comp_producto
									FROM Composicion	
								)
	) AS [Cant Prod Fact CON comp]
	,(
		SELECT SUM(item_cantidad)
		FROM Item_Factura
			INNER JOIN Factura
				ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
		WHERE fact_vendedor = E.empl_codigo 
			AND YEAR(fact_fecha) = YEAR(F.fact_fecha)
			AND item_producto NOT IN (
									SELECT comp_producto
									FROM Composicion	
								)
			AND item_producto IN (
									SELECT prod_codigo
									FROM Producto
								)
		) AS [Cant Prod Fact SIN comp]
		,SUM(F.fact_total) AS [Total vendido por vendedor]
FROM Factura F
	INNER JOIN Empleado E
		ON E.empl_codigo = F.fact_vendedor

GROUP BY YEAR(F.fact_fecha),E.empl_codigo,E.empl_nombre,E.empl_apellido--,F.fact_numero+F.fact_tipo+F.fact_sucursal
ORDER BY 2,(
			SELECT COUNT(DISTINCT item_cantidad)
			FROM Item_Factura
				INNER JOIN Factura
					ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
			WHERE fact_vendedor = E.empl_codigo 
				AND YEAR(fact_fecha) = YEAR(F.fact_fecha)
			) DESC


/*32. Se desea conocer las familias que sus productos se facturaron juntos en las mismas
facturas para ello se solicita que escriba una consulta sql que retorne los pares de
familias que tienen productos que se facturaron juntos. Para ellos deberá devolver las
siguientes columnas:
- Código de familia
- Detalle de familia
- Código de familia
- Detalle de familia
- Cantidad de facturas
- Total vendido
Los datos deberan ser ordenados por Total vendido y solo se deben mostrar las familias
que se vendieron juntas más de 10 veces.*/

SELECT FAM1.fami_id AS [FAMI Cod 1]
	,FAM1.fami_detalle AS [FAMI Detalle 1]
	,FAM2.fami_id AS [FAMI Cod 2]
	,FAM2.fami_detalle [FAMI Detalle 2]
	,COUNT(DISTINCT IFACT2.item_numero+IFACT2.item_tipo+IFACT2.item_sucursal) AS [Cantidad de facturas]
	,SUM(IFACT1.item_cantidad*IFACT1.item_precio) + SUM(IFACT2.item_cantidad*IFACT2.item_precio) AS [Total Vendido entre items de ambas familias]
FROM Familia FAM1
	INNER JOIN Producto P1 ON P1.prod_familia = FAM1.fami_id
	INNER JOIN Item_Factura IFACT1 ON IFACT1.item_producto = P1.prod_codigo
	,Familia FAM2
	INNER JOIN Producto P2
		ON P2.prod_familia = FAM2.fami_id
	INNER JOIN Item_Factura IFACT2
		ON IFACT2.item_producto = P2.prod_codigo
WHERE FAM1.fami_id < FAM2.fami_id
	AND IFACT1.item_numero+IFACT1.item_tipo+IFACT1.item_sucursal = IFACT2.item_numero+IFACT2.item_tipo+IFACT2.item_sucursal
GROUP BY FAM1.fami_id,FAM1.fami_detalle,FAM2.fami_id,FAM2.fami_detalle
HAVING COUNT(DISTINCT IFACT2.item_numero+IFACT2.item_tipo+IFACT2.item_sucursal) > 10
ORDER BY 6




/*33. Se requiere obtener una estadística de venta de productos que sean componentes. Para
ello se solicita que realiza la siguiente consulta que retorne la venta de los
componentes del producto más vendido del año 2012. Se deberá mostrar:
a. Código de producto
b. Nombre del producto
c. Cantidad de unidades vendidas
d. Cantidad de facturas en la cual se facturo
e. Precio promedio facturado de ese producto.
f. Total facturado para ese producto
El resultado deberá ser ordenado por el total vendido por producto para el año 2012.*/


--Esta sin terminar
SELECT P.prod_codigo
	,P.prod_detalle
	,SUM(IFACT.item_cantidad) AS [Cantidad unidades vendidas]
	,COUNT(DISTINCT IFACT.item_numero+IFACT.item_tipo+IFACT.item_sucursal) [Cant fact realizadas]
	,AVG(IFACT.item_precio) [Precio promedio facturado]
	,SUM(IFACT.item_precio*IFACT.item_cantidad) [Total Facturado]
FROM Producto P
	INNER JOIN Composicion C
		ON C.comp_componente = P.prod_codigo
	INNER JOIN Producto COMBO
		ON COMBO.prod_codigo = C.comp_producto
	INNER JOIN Item_Factura IFACT
		ON IFACT.item_producto = P.prod_codigo
	INNER JOIN Factura F
		ON F.fact_numero = IFACT.item_numero AND F.fact_tipo = IFACT.item_tipo AND F.fact_sucursal = IFACT.item_sucursal
WHERE C.comp_producto = (
							SELECT TOP 1 item_producto
							FROM Item_Factura
								INNER JOIN Factura
									ON fact_numero = item_numero AND fact_tipo = item_tipo AND fact_sucursal = item_sucursal
							WHERE item_producto IN (SELECT comp_producto FROM Composicion) AND YEAR(fact_fecha) = 2012
							GROUP BY item_producto
							ORDER BY SUM(item_cantidad) DESC
							)
GROUP BY P.prod_codigo,P.prod_detalle

/* 34. Escriba una consulta sql que retorne para todos los rubros la cantidad de facturas mal
facturadas por cada mes del año 2011 Se considera que una factura es incorrecta cuando
en la misma factura se factutan productos de dos rubros diferentes. Si no hay facturas
mal hechas se debe retornar 0. Las columnas que se deben mostrar son:
1- Codigo de Rubro
2- Mes
3- Cantidad de facturas mal realizadas.*/

SELECT P.prod_rubro AS [Rubro]
	,MONTH(F.fact_fecha) AS [MES]
	,COUNT(DISTINCT F.fact_tipo+F.fact_sucursal+F.fact_numero) AS [Fact mal realizadas]
FROM Producto P
	INNER JOIN Item_Factura IFACT
		ON IFACT.item_producto = P.prod_codigo
	INNER JOIN Factura F
		ON F.fact_tipo = IFACT.item_tipo AND F.fact_sucursal = IFACT.item_sucursal AND F.fact_numero = IFACT.item_numero
WHERE YEAR(F.fact_fecha) = 2011 AND (
										SELECT COUNT(DISTINCT prod_rubro)
										FROM Producto
											INNER JOIN Item_Factura
												ON item_producto = prod_codigo
										WHERE item_tipo+item_sucursal+item_numero = IFACT.item_tipo+IFACT.item_sucursal+IFACT.item_numero
										GROUP BY item_tipo+item_sucursal+item_numero
										) > 1
GROUP BY P.prod_rubro, MONTH(F.fact_fecha)
ORDER BY 1

/*35. Se requiere realizar una estadística de ventas por año y producto, para ello se solicita
que escriba una consulta sql que retorne las siguientes columnas:
1 Año
2 Codigo de producto
3 Detalle del producto
4 Cantidad de facturas emitidas a ese producto ese año
5 Cantidad de vendedores diferentes que compraron ese producto ese año.
6 Cantidad de productos a los cuales compone ese producto, si no compone a ninguno
se debera retornar 0.
7 Porcentaje de la venta de ese producto respecto a la venta total de ese año.
Los datos deberan ser ordenados por año y por producto con mayor cantidad vendida.*/

SELECT YEAR(F.fact_fecha) AS [Año]
	,P.prod_codigo
	,P.prod_detalle
	,COUNT(DISTINCT F.fact_tipo+F.fact_sucursal+F.fact_numero) AS [Cant Facturas]
	,COUNT(DISTINCT F.fact_vendedor) AS [Cant vendedores diferentes del prod]
	,(
		SELECT COUNT(comp_componente)
		FROM Composicion
		WHERE comp_componente = P.prod_codigo
	) AS [Cant de prods que compone]
	,(
		(SUM(IFACT.item_precio*IFACT.item_cantidad)
		* 100)
		/
		(
			SELECT SUM(item_precio*item_cantidad)
			FROM Item_Factura
				INNER JOIN Factura
					ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = fact_numero
			WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha)
		)
	) AS [Porcentaje de venta sobre el total]
	FROM Producto P
		INNER JOIN Item_Factura IFACT
			ON IFACT.item_producto = P.prod_codigo
		INNER JOIN Factura F
			ON F.fact_tipo = IFACT.item_tipo AND F.fact_sucursal = IFACT.item_sucursal AND F.fact_numero = IFACT.item_numero
GROUP BY YEAR(F.fact_fecha),P.prod_codigo,P.prod_detalle
ORDER BY 1, SUM(IFACT.item_cantidad) DESC