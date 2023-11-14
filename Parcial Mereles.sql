-- EXAMEN MERELES
/*
Se necesita saber:
- Codigo de Producto
- Nombre de Producto
- Fue vendido en 2011 (SI o NO)
- Cantidad de componentes

Condicion:
- Ordenado por cantidad total de clientes que lo compraron en la historia (ASC)
*/

Select [prod_codigo],
	   [prod_detalle],
	   Case (
				Select 1
				From GD2015C1.dbo.Item_Factura
				Join GD2015C1.dbo.Factura On item_tipo + [item_sucursal] + [item_numero] = fact_tipo + [fact_sucursal] + [fact_numero]
				Where Year(fact_fecha) = 2011 and
					  item_producto = prod_codigo
			) 
			When Null then 'No'
			else 'Si'
		end,
	   Count (prod_codigo) as CantidadComponentes
From GD2015C1.dbo.Producto
Left Join GD2015C1.dbo.Composicion On [comp_producto] = [prod_codigo]
Group by [prod_codigo],
		 [prod_detalle]
Order By (
			Select Count (*)
			From GD2015C1.dbo.Item_Factura
			Where [item_producto] = [prod_codigo]
			Group by [item_producto]
		 )
GO

/*
No se puede permitir vender un producto:
- El precio actual es mayor al 5% del mes anterior
- El precio actual es mayor al 50% del año anterior
Los productos nuevos o sin ventas antes no aplica
*/

Create Function CumpleMesAnterior(@producto char(8), @precio decimal(12,2)) Returns Bit As
BEGIN
	Declare @retorno bit, @precioMesAnterior decimal(12,2)

	Select [item_precio] = @precioMesAnterior
	From GD2015C1.dbo.Item_Factura
	Where (
			Select Month([fact_fecha])
			From [GD2015C1].[dbo].[Factura]
			Where item_tipo = fact_tipo And
				  [item_sucursal] = fact_sucursal And
				  [item_numero] = fact_numero
		  ) = Month(GetDate()) - 1 and
		  item_producto = @producto

	If (@precioMesAnterior*100/@precio <= 105 and @precioMesAnterior*100/@precio >= 100)
		Set @retorno = 1
	Else
		Set @retorno = 0
	Return @retorno
END

GO

Create Function CumpleYearAnterior(@producto char(8), @precio decimal(12,2)) Returns Bit As
BEGIN
	Declare @retorno bit, @precioYearAnterior decimal(12,2)

	Select [item_precio] = @precioYearAnterior
	From GD2015C1.dbo.Item_Factura
	Where (
			Select Month([fact_fecha])
			From [GD2015C1].[dbo].[Factura]
			Where item_tipo = fact_tipo And
				  [item_sucursal] = fact_sucursal And
				  [item_numero] = fact_numero
		  ) = Month(GetDate()) - 1 and
		  item_producto = @producto

	If (@precioYearAnterior*100/@precio <= 150)
		Set @retorno = 1
	Else
		Set @retorno = 0
	Return @retorno
END

GO

Create Trigger VenderProducto
On GD2015C1.dbo.Item_Factura
For Insert As
	Begin
		Declare @tipo char(1), @sucursal char(4), @numero char(8)
		Declare @producto char(8), @precio decimal(12,2)

		Select [item_precio] = @precio,
			   [item_producto] =  @producto
		From inserted

		If (CumpleMesAnterior(@producto, @precio) = 1 and CumpleYearAnterior(@producto, @precio) = 1)
			print 'Se vendio exitosamente el producto'
		else
			print 'El producto no cumple con los requisitos'
			Delete From GD2015C1.dbo.Item_Factura
			Where item_tipo = @tipo And
				  [item_sucursal] = @sucursal And
				  [item_numero] = @numero
	End