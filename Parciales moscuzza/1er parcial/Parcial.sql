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
       No se pueden utilizar operadores de conjuntos*/
USE GD2015C1
GO

select case 
        WHEN (MONTH(f.fact_fecha) + MONTH(f.fact_fecha)%3) / 3 = 1 THEN '1° Trimestre'
        WHEN (MONTH(f.fact_fecha) + MONTH(f.fact_fecha)%3) / 3 = 2 THEN '2° Trimestre'
        WHEN (MONTH(f.fact_fecha) + MONTH(f.fact_fecha)%3) / 3 = 3 THEN '3° Trimestre'
        WHEN (MONTH(f.fact_fecha) + MONTH(f.fact_fecha)%3) / 3 = 4 THEN '4° Trimestre'
         end Trimestre
		, sum(f.fact_total + fact_total_impuestos) [Total Facturado]
		, count(fact_numero) [Cantidad de Facturas]
		, (select top 1 p.prod_detalle from Producto p
		   inner join Item_Factura i on i.item_producto = p.prod_codigo
		   inner join Factura f2 on f2.fact_numero = i.item_numero and f2.fact_tipo = i.item_tipo and f2.fact_sucursal = i.item_sucursal
		   where YEAR(f2.fact_fecha) = 2011 AND (MONTH(f2.fact_fecha) + MONTH(f2.fact_fecha)%3) / 3 = (MONTH(f2.fact_fecha) + MONTH(f2.fact_fecha)%3) / 3
		   group by (MONTH(f2.fact_fecha) + MONTH(f2.fact_fecha)%3) / 3, p.prod_detalle
			order by sum(i.item_cantidad) desc
		   ) as Detalle
	from Factura f
where f.fact_fecha < dateadd(year,-1,'2012-10-24 12:22:52.297')
  and f.fact_fecha > dateadd(year,-2,'2012-10-24 12:22:52.297')
group by (MONTH(f.fact_fecha) + MONTH(f.fact_fecha)%3) / 3
order by (MONTH(f.fact_fecha) + MONTH(f.fact_fecha)%3) / 3

select getdate()

/*2. T-SQL
Realizar una función que dado un tipo de factura y sucursal, devuelva el próximo número de factura consecutivo 
y en caso de que no exista ninguno informar el primero, el tipo de dato y formato de retorno debe coincidir 
con el de la tabla (Ej. '00002021').

Usando la función anterior realizar un stored procedure que inserte un nuevo registro de factura y un ítem, 
se debe recibir como parámetros todos los datos obligatorios de las 2 tablas, la fecha y un código de depósito, 
guardar solo los valores no nulos en ambas tablas y restar el stock de ese producto en la tabla correspondiente.  

Se debe validar previamente la existencia del stock en ese depósito y en caso de no haber no realizar nada.
El total de factura se calcula como el precio de ese único ítem, y en los impuestos es el 21% de dicho valor 
redondeado a 2 decimales.

Se debe programar una transacción para que las 3 operaciones se realicen atómicamente, 
se asume que todos los parámetros recibidos están validados a excepción de la cantidad del producto en stock.

Queda a criterio del alumno, que acciones tomar en caso de que no se cumpla la única validación o se produzca un 
error no previsto.*/

USE GD2015C1 
GO 

CREATE PROCEDURE pr_insert_item 
(@tipo CHAR(01), @sucursal CHAR(04), @item char(08), @fecha smalldatetime, @codigoDepo char(02),
 @factVendedor numeric(06), @factClient char(06),
@retorno VARCHAR(5000) OUTPUT) AS 
BEGIN
	DECLARE @fact_numer CHAR(8)
	DECLARE @stock_disponible decimal(12,2)
	DECLARE @total decimal(12,2)
	Declare @totalImp decimal(12,2)

	set @stock_disponible = (select s.stoc_cantidad
	from Stock s where s.stoc_deposito = @codigoDepo and s.stoc_producto = @item)

	if @@ROWCOUNT = 0
	begin
		set @retorno = '1'
		return
	end

	if @stock_disponible <= 0
	begin
		set @retorno = '1'
		return
	end
	set @fact_numer = (select [dbo].[fx_parcial_factura](@tipo,@sucursal))
	set @total = ( select p.prod_precio from Producto p where p.prod_codigo = @item)
	set @totalImp = ROUND((@total * 0.21),2,0) 

	BEGIN TRANSACTION
		INSERT INTO Factura
		(fact_tipo, fact_sucursal, fact_numero, fact_fecha, fact_vendedor, fact_total, 
		fact_total_impuestos, fact_cliente )
		VALUES (@tipo, @sucursal, @fact_numer, @fecha, @factVendedor, @total, @totalImp, @factClient)
	
		Insert into Item_Factura
		(item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
		values(@tipo, @sucursal, @fact_numer, @item, 1, (select p.prod_precio from Producto p where p.prod_codigo = @item))
	
		update STOCK
		set stoc_cantidad = stoc_cantidad - 1
		where stoc_deposito = @codigoDepo and stoc_producto = @item

	COMMIT TRANSACTION
	return
END
GO


CREATE FUNCTION [dbo].[fx_parcial_factura] (@tipoFact CHAR(1), @sucursal char(4))
RETURNS CHAR(08) AS
BEGIN
	DECLARE @retorno CHAR(08) = null
	DECLARE @aux INT

	SELECT @retorno = isnull(max(f.fact_numero),' ') from Factura f where f.fact_tipo = @tipoFact and f.fact_sucursal = @sucursal

	if @retorno = ' ' 
		begin
			SET @retorno = '00000001'
			return @retorno
		end
	
	select @aux = CAST(@retorno as int)
	SET @aux = @aux + 1 
	set @retorno= right('00000000' + cast(@aux as varchar(08)),8)
	RETURN @retorno 

END