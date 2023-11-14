--SQL
SELECT
  P.prod_codigo [Código de producto]
  ,P.prod_detalle [Nombre de Producto]

  ,CASE WHEN 
(SELECT
    COUNT(1)
  FROM
    Item_Factura ITF
    LEFT JOIN Factura F ON ITF.item_tipo+ITF.item_sucursal+ITF.item_numero = F.fact_tipo+F.fact_sucursal+F.fact_numero
  WHERE P.prod_codigo=ITF.item_producto AND YEAR(F.fact_fecha)=2011) > 0 THEN 'Si'
ELSE 'No'
END
[Fue Vendido]
,COUNT(C.comp_componente) [Cantidad de componentes]
FROM
  Producto P
  LEFT JOIN Composicion C ON C.comp_producto=P.prod_codigo
GROUP BY P.prod_codigo,P.prod_detalle

ORDER BY (SELECT
  COUNT(F1.fact_cliente)
FROM
  Factura F1 INNER JOIN Item_Factura ITF1 ON ITF1.item_tipo+ITF1.item_sucursal+ITF1.item_numero = F1.fact_tipo+F1.fact_sucursal+F1.fact_numero
WHERE P.prod_codigo=ITF1.item_producto
GROUP BY ITF1.item_producto) ASC
GO

--TSQL
CREATE TRIGGER trControlPrecioInflacion ON Item_factura AFTER INSERT
AS
BEGIN

  SET NOCOUNT ON
  DECLARE @item_precio [DECIMAL](12, 2),@item_producto [CHAR](8)
  DECLARE cursor_ventas CURSOR FOR
  SELECT
    item_producto
    ,item_precio
  FROM
    inserted
  OPEN cursor_ventas

  BEGIN TRY
  
  FETCH cursor_ventas INTO @item_producto ,@item_precio

  WHILE @@FETCH_STATUS=0
  BEGIN
    DECLARE @ValorMaximoMesPasado   [DECIMAL](12, 2)
    DECLARE @ValorMaximoAnioPasado   [DECIMAL](12, 2)
    SELECT
      @ValorMaximoMesPasado=MAX(Item_precio)
    FROM
      Factura f INNER JOIN Item_Factura ITF ON ITF.item_tipo+ITF.item_sucursal+ITF.item_numero = F.fact_tipo+F.fact_sucursal+F.fact_numero
    WHERE item_producto=@item_producto
      --Reviso en todo el mes hace 1 mes
      AND MONTH(DATEADD(month,-1,GETDATE()))=MONTH(fact_fecha)
      AND YEAR(DATEADD(month,-1,GETDATE()))=YEAR(fact_fecha)
    SELECT
      @ValorMaximoAnioPasado=MAX(Item_precio)
    FROM
      Factura f INNER JOIN Item_Factura ITF ON ITF.item_tipo+ITF.item_sucursal+ITF.item_numero = F.fact_tipo+F.fact_sucursal+F.fact_numero
    WHERE item_producto=@item_producto
      --Reviso en todo el mes hace 12 meses
      AND MONTH(DATEADD(month,-12,GETDATE()))=MONTH(fact_fecha)
      AND YEAR(DATEADD(month,-12,GETDATE()))=YEAR(fact_fecha)


    IF ((@item_precio-@ValorMaximoMesPasado)/@ValorMaximoMesPasado)*100 > 5
    BEGIN
      RAISERROR('El producto de <%s> superó el 5 por ciento del lo que se vendio el mes pasado',1,1,@item_producto)
    END
    IF ((@item_precio-@ValorMaximoAnioPasado)/@ValorMaximoAnioPasado)*100 > 50
    BEGIN
      RAISERROR('El producto de <%s> superó el 50 por ciento del lo que se vendio el año pasado',1,1,@item_producto)
    END

    FETCH cursor_ventas INTO @item_producto ,@item_precio
  END
  CLOSE cursor_ventas
  DEALLOCATE cursor_ventas
  END TRY
  BEGIN CATCH
    -- Creo el bloque de catch ya que ante cualquier RAISERROR rollbackeo la transaccion
    ROLLBACK TRANSACTION
    CLOSE cursor_ventas
    DEALLOCATE cursor_ventas
  END CATCH

END
GO

