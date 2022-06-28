/*1. SQL

 

Realizar una consulta SQL que para el año anterior al vigente muestre las siguientes columnas

       Trimestre (Primero, Segundo, Tercero, Cuarto)

       Total facturado para ese trimestre (fact_total más impuestos)

       Cantidad de Facturas de ese trimestre

       Detalle del producto que habiendo tenido al menos una venta sea el menos vendido en ese trimestre

 

El resultado debe ser ordenado por el número de trimestre, debido a que esta consulta va a ejecutarse en reiteradas ocasiones el año no debe ser un valor prefijado.

Debe retornar como máximo 4 filas, si no hay facturación para un trimestre dado no se debe mostrar esa fila.

 

Por motivos de performance se establecen las siguientes restricciones a la solución:

       No se pueden utilizar sub selects en el from

       No se pueden utilizar operadores de conjuntos
*/

SELECT
CASE WHEN datepart(quarter, f.fact_fecha) = 1 THEN 'Primero'
WHEN datepart(quarter, f.fact_fecha) = 2 THEN 'Segundo'
WHEN datepart(quarter, f.fact_fecha) = 3 THEN 'Tercero'
WHEN datepart(quarter, f.fact_fecha) = 4 THEN 'Cuarto' END Trimestre,
SUM(f.fact_total) as [Total Facturado], -- Tomo en cuenta que el total incluye a los impuestos, sino seria SUM(f.fact_total - f.fact_total_impuestos) as [Total Facturado]
COUNT(DISTINCT f.fact_numero) as [Cantidad Facturas],
(SELECT TOP 1 prod_detalle FROM PRODUCTO p2
JOIN Item_Factura i2 on i2.item_producto = p2.prod_codigo
JOIN Factura f2 ON f2.fact_tipo = i2.item_tipo AND f2.fact_sucursal = i2.item_sucursal AND f2.fact_numero = i2.item_numero
WHERE (f2.fact_fecha BETWEEN DATEADD(YYYY, -1, GETDATE()) AND GETDATE()) AND DATEPART(QUARTER, f.fact_fecha) = DATEPART(QUARTER, f2.fact_fecha)
GROUP BY p2.prod_codigo, p2.prod_detalle
ORDER BY COUNT(*) ASC) as [Producto menos vendido]
FROM PRODUCTO p
JOIN Item_Factura i on i.item_producto = p.prod_codigo
JOIN Factura f ON f.fact_tipo = i.item_tipo AND f.fact_sucursal = i.item_sucursal AND f.fact_numero = i.item_numero
WHERE f.fact_fecha BETWEEN DATEADD(YYYY, -1, GETDATE()) AND GETDATE()
GROUP BY DATEPART(QUARTER, f.fact_fecha)
go
/*
2. T-SQL

 

Realizar una función que dado un tipo de factura y sucursal, devuelva el próximo número de factura consecutivo y en caso de que no exista ninguno informar el primero
El tipo de dato y formato de retorno debe coincidir con el de la tabla (Ej. '00002021').

-----

Usando la función anterior realizar un stored procedure que inserte un nuevo registro de factura y un ítem
Se debe recibir como parámetros todos los datos obligatorios de las 2 tablas, la fecha y un código de depósito, guardar solo los valores no nulos en ambas tablas y restar el stock de ese producto en la tabla correspondiente.  Se debe validar previamente la existencia del stock en ese depósito y en caso de no haber no realizar nada.

El total de factura se calcula como el precio de ese único ítem, y en los impuestos es el 21% de dicho valor redondeado a 2 decimales.

Se debe programar una transacción para que las 3 operaciones se realicen atómicamente, se asume que todos los parámetros recibidos están validados a excepción de la cantidad del producto en stock.

Queda a criterio del alumno, que acciones tomar en caso de que no se cumpla la única validación o se produzca un error no previsto.
*/

/*
2. T-SQL


Realizar una función que dado un tipo de factura y sucursal, devuelva el próximo número de factura consecutivo y en caso de que no 
exista ninguno informar el primero, el tipo de dato y formato de retorno debe coincidir con el de la tabla (Ej. '00002021').

Usando la función anterior realizar un stored procedure que inserte un nuevo registro de factura y un ítem, se debe recibir como 
parámetros todos los datos obligatorios de las 2 tablas, la fecha y un código de depósito, guardar solo los valores no nulos en ambas
tablas y restar el stock de ese producto en la tabla correspondiente.  

Se debe validar previamente la existencia del stock en ese depósito y en caso de no haber no realizar nada.

El total de factura se calcula como el precio de ese único ítem, y en los impuestos es el 21% de dicho valor redondeado a 2 decimales.

Se debe programar una transacción para que las 3 operaciones se realicen atómicamente, se asume que todos los parámetros recibidos están 
validados a excepción de la cantidad del producto en stock.

Queda a criterio del alumno, que acciones tomar en caso de que no se cumpla la única validación o se produzca un error no previsto.*/



CREATE FUNCTION prox_numero_factura(@p_tipo_factura CHAR(1), @p_sucursal_factura CHAR(4))
RETURNS CHAR(8)
AS
BEGIN
DECLARE @proximo INT

SELECT @proximo = CAST(ISNULL(Max(fact_numero),0) as INT) + 1 FROM Factura
WHERE @p_tipo_factura = fact_tipo AND @p_sucursal_factura = fact_sucursal

RETURN RIGHT('0000000'+CAST(@proximo AS CHAR(8)),8)
END
GO

SELECT MAX(fact_numero) FROM Factura

CREATE PROCEDURE insertar_venta(
										@p_tipo_factura CHAR(1),
										@p_sucursal_factura CHAR(4),
										@p_item_producto CHAR(8),
										@p_fecha DATETIME,
										@p_cod_deposito CHAR(2)
										)
AS

DECLARE 
@tiene_cantidad as int

SELECT 
@tiene_cantidad = 
(CASE WHEN ISNULL(SUM(stoc_cantidad), -1) < 0 THEN 0
ELSE 1 END)
FROM Stock
WHERE stoc_producto = @p_item_producto AND stoc_deposito = @p_cod_deposito


BEGIN TRY
BEGIN TRANSACTION

DECLARE 
@numero_factura as int,
@cantidad as int = 1,
@precio as FLOAT
EXEC @numero_factura = prox_numero_factura @p_tipo_factura, @p_sucursal_factura

SELECT @precio = prod_precio From Producto WHERE prod_codigo = @p_item_producto


INSERT INTO Factura (fact_tipo, fact_numero, fact_sucursal, fact_total, fact_total_impuestos, fact_fecha) VALUES
(@p_tipo_factura, @numero_factura, @p_sucursal_factura, @precio, ROUND(@precio * 0.21, 2, 0), @p_fecha)


INSERT INTO Item_Factura (item_tipo, item_numero, item_sucursal, item_producto, item_precio, item_cantidad) VALUES
(
@p_tipo_factura,
@numero_factura,
@p_sucursal_factura,
@p_item_producto,
@precio,
@cantidad
)

UPDATE STOCK SET stoc_cantidad -= @cantidad WHERE stoc_producto = @p_item_producto AND stoc_deposito = @p_cod_deposito

COMMIT TRANSACTION
END TRY

BEGIN CATCH
IF @@TRANCOUNT > 0 OR @tiene_cantidad = 0
ROLLBACK TRAN 

    RAISERROR('Se produjo un error',1,1)
END CATCH




