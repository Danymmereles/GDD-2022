
/*
Devuelve el stock que tenia el producto a esta fecha
*/
create function ej2 (@producto char(8), @fecha smalldatetime)
returns numeric(12,2)
as
begin
return (select sum(stoc_cantidad) from stock where stoc_producto=@producto) + 
		(select sum(item_cantidad) from item_factura join factura on fact_tipo+fact_sucursal+fact_numero =
					item_tipo+item_sucursal+item_numero 
				where fact_fecha >= @fecha and item_producto = @producto) 
end
