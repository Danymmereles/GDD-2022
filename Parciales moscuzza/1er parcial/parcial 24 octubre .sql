use GD2015C1

/*1. SQL
Realizar una consulta SQL que para el año anterior al vigente muestre las siguientes columnas
       Trimestre (Primero, Segundo, Tercero, Cuarto)
       Total Impuestos para ese trimestre (fact_total_impuestos)
       Cantidad de Facturas de ese trimestre
       Detalle del producto más vendido en ese trimestre
El resultado debe ser ordenado por el número de trimestre, debido a que esta consulta va a ejecutarse en reiteradas ocasiones el año no debe ser un valor prefijado.
Debe retornar como máximo 4 filas, si no hay facturación para un trimestre dado no se debe mostrar esa fila.
Por motivos de performance se establecen las siguientes restricciones a la solución:
       No se pueden utilizar sub selects en el from
       No se pueden utilizar operadores de conjuntos
       */
select
DATEPART(quarter, f.fact_fecha) as trimestre,
sum(f.fact_total_impuestos) as totalimpiestos,
COUNT(distinct f.fact_numero + f.fact_sucursal + f.fact_tipo) cantFacturas,

(select
top 1
p.prod_detalle

from Factura f2 left join Item_Factura i on i.item_numero= f2.fact_numero and i.item_sucursal= f2.fact_sucursal and i.item_tipo = f2.fact_tipo
left join Producto p on p.prod_codigo = i.item_producto

/*where fact_fecha = DATEADD(YEAR, -1, GETDATE()) group by DATEPART(quarter, f.fact_fecha)*/


where year(f2.fact_fecha )= year(DATEADD(YEAR, -1, GETDATE())) and DATEPART(quarter, f.fact_fecha) = DATEPART(quarter, f2.fact_fecha)

group by DATEPART(quarter, f2.fact_fecha), p.prod_detalle order by sum(i.item_cantidad) desc

) masVendido

from Factura f left join Item_Factura i on i.item_numero= fact_numero and i.item_sucursal= f.fact_sucursal and i.item_tipo = f.fact_tipo
left join Producto p on p.prod_codigo = i.item_producto

where year(f.fact_fecha )= year(DATEADD(YEAR, -1, GETDATE())) group by DATEPART(quarter, f.fact_fecha) order by DATEPART(quarter, f.fact_fecha)
go

/*********/


/*2. T-SQL
Se sabe que existen productos que poseen stock en un solo depósito, realizar un stored procedure que reciba un código de producto (ya está validado previamente que es uno con un solo deposito) y una cantidad como parámetros.
El stored procedure debe actualizar el stock sumando a la cantidad lo que acaba de ingresar y
en el caso de que el stock anterior fuera negativo informe con la funcionalidad de “Print” todas las facturas emitidas en las cuales se vendió dicho producto sin tener stock existente.

*/

Create PROCEDURE actualizarStock(@codigo_Prod varchar(10), @nuevaCantidad decimal(10,2)) as
	begin
		declare @cantidad decimal(10,2);
		declare @cantFact decimal(102);

		select @cantidad = s.stoc_cantidad from GD2015C1.dbo.STOCK s where s.stoc_producto = @codigo_Prod

		if @cantidad < 0
			begin
				print (select * 
						from GD2015C1.dbo.Factura f 
							left join D2015C1.dbo.Item_Factura i on i.item_numero= fact_numero and i.item_sucursal= f.fact_sucursal and i.item_tipo = f.fact_tipo 
						where i.item_producto = @codigo_Prod)

					select @cantFact = COUNT(distinct f.fact_numero + f.fact_sucursal + f.fact_tipo) 
						from GD2015C1.dbo.Factura f 
							left join GD2015C1.dbo.Item_Factura i on i.item_numero= fact_numero and i.item_sucursal= f.fact_sucursal and i.item_tipo = f.fact_tipo
						where i.item_producto = @codigo_Prod
						group by i.item_producto

				while 0 < @cantFact
					begin
						print (select *, row_number( ) over(order by f.fact_fecha) mrow 
								from GD2015C1.dbo.Factura f 
									left join GD2015C1.dbo.Item_Factura i on i.item_numero= fact_numero and i.item_sucursal= f.fact_sucursal and i.item_tipo = f.fact_tipo 
								where i.item_producto = @codigo_Prod and mrow=@cantFact)

						set @cantFact= @cantFact-1;
					end
			end

		else
			update GD2015C1.dbo.STOCK  set stoc_cantidad = @cantidad - @nuevaCantidad where stoc_producto = @codigo_Prod;
end
go