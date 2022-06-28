/*
Realizar una consulta SQL que retorne: 
	Año 
	Cantidad de productos compuestos vendidos en el Año 
	Cantidad de facturas realizadas en el Año 
	Monto total facturado en el Año 
	Monto total facturado en el Año anterior.

Considerar:
	Aquellos Años donde la cantidad de unidades vendidas de todos los artículos sea mayor a 1000.
	Ordenar el resultado por cantidad vendida en el año

NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto.
*/

select 
	year(f1.fact_fecha) 'Año',
	(	select count(*)
		from Item_Factura
		JOIN FACTURA f2 on (f2.fact_tipo = item_tipo AND f2.fact_sucursal = item_sucursal AND f2.fact_numero = item_numero)
		join Composicion on (comp_producto = item_producto)
		where year(f2.fact_fecha) = year(f1.fact_fecha)
	) 'Cantidad Compuestos Vendidos',
	count(distinct f1.fact_tipo+f1.fact_sucursal+f1.fact_numero) 'Cantidad de facturas emitidas',
	(
		select sum(fact_total)
		from FACTURA f2
		where year(f2.fact_fecha) = year(f1.fact_fecha)
	) 'Monto facturado en el año',
	(
		select isnull(sum(fact_total),0)
		from FACTURA f2
		where year(f2.fact_fecha) = year(f1.fact_fecha) - 1
	) 'Monto facturado en el año anterior'
from Factura f1
join Item_Factura on (f1.fact_tipo = item_tipo AND f1.fact_sucursal = item_sucursal AND f1.fact_numero = item_numero)
group by year(f1.fact_fecha)
having (isnull(sum(item_cantidad),0) > 1000)
order by sum(item_cantidad) desc
go

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


create function func_parcial2021 (@tipo char(1), @sucursal char(4))
returns char(8) as
begin 
	return right('00000000'+cast((select max(fact_numero) from Factura where fact_tipo = @tipo and fact_sucursal = @sucursal)+1  as varchar(8)),8)
end

DROP FUNCTION parcial2021
SELECT dbo.parcial2021('A', '0003')
go
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

create procedure sp_parcial2021(@tipo char(1),@sucursal char(4),@numero char(8), @producto char(8), @deposito char(2), @precio decimal(12,2), @cantidad decimal(12,2))
as
begin
	declare @stock as decimal(12,2)
	declare @fecha as smalldatetime
	set @fecha = GETDATE()
	select @stock = isnull(stoc_cantidad,0) from STOCK where stoc_deposito = @deposito and stoc_producto = @producto

	if @stock > @cantidad
	begin
		begin transaction
		begin try
			insert into Factura(fact_tipo, fact_sucursal,fact_numero,fact_fecha,fact_total,fact_total_impuestos) 
			values (@tipo,@sucursal,@numero,@fecha,coalesce(@precio*@cantidad,0),round(coalesce(@precio*21/100,0),2))

			insert into Item_Factura(item_tipo, item_sucursal, item_numero, item_producto, item_precio, item_cantidad) 
			values (@tipo,@sucursal,@numero,@producto,coalesce(@precio,0),@cantidad)

			update Stock set stoc_cantidad = @stock - @cantidad where stoc_deposito = @deposito and stoc_producto = @producto
		end try
		begin catch
			rollback transaction;
			throw 50001,'Error: No se ha podido realizar la operación',1
		end catch
	end
	else 
	begin
		throw 50002,'Error: No hay Stock disponible para el producto elegido',1
	end
	commit transaction;
end

drop procedure sp_parcial2021

execute sp_parcial2021 
@tipo = 'T', @sucursal = '9999', @numero ='00000001', @producto = '00000849',  @deposito ='00', @precio = 2, @cantidad = 4

select * from factura where fact_tipo = 'T'
select * from Item_Factura where item_tipo = 'T'
select * from stock where stoc_producto = '00000849' and stoc_deposito = '00'

update Stock set stoc_cantidad = 20 where stoc_producto = '00000849' and stoc_deposito = '00'

delete from Item_Factura where item_tipo = 'T'
delete from Factura where fact_tipo = 'T'