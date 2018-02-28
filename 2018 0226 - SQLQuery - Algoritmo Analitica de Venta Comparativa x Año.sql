

DECLARE @toDay DATETIME = GETDATE()
DECLARE @toDayBack DATETIME = DATEADD(YY,-1,@toDay)
DECLARE @MesActualInicio DATETIME = CAST('20180101' AS DATETIME) --DATEADD(MM,DATEDIFF(MM,0,@toDay),0)
DECLARE @MesActualFinal DATETIME = CAST('20180131' AS DATETIME) --DATEADD(MM,DATEDIFF(MM,0,@toDay) + 1,0) - 1
DECLARE @MesActualInicio2 DATETIME = CAST('20170101' AS DATETIME) --DATEADD(MM,DATEDIFF(MM,0,@toDayBack),0)
DECLARE @MesActualFinal2 DATETIME = CAST('20170131' AS DATETIME) --DATEADD(MM,DATEDIFF(MM,0,@toDayBack) + 1,0) - 1

DECLARE @Sucursal NVARCHAR(2) = 'ZR'
DECLARE @Almacen INT = 2
DECLARE @Tienda INT = 1

WITH articulosCTE (Articulo)
AS
(
	SELECT Articulo FROM Catalogo WHERE Tienda = @Tienda AND Baja = 0		
)

SELECT * FROM (
SELECT 
	Suc,Subfamilia,DescripcionSubfamilia,
	Articulo,Nombre,ExistUV,Relacion,CostoNet,CostoExist,Precio,Util,
	Estatus,Stock30,uvAñoAnterior,uvAñoActual,
	Tendencia = CASE
		WHEN uvAñoActual > uvAñoAnterior THEN 1 - (uvAñoAnterior/uvAñoActual)
		WHEN uvAñoActual < uvAñoAnterior THEN (1 - (uvAñoActual/uvAñoAnterior)) * -1
		ELSE 0.00
	END,
	mxnAñoAnterior,mxnAñoActual
FROM (
SELECT Suc = @Sucursal,
	Subfamilia,DescripcionSubfamilia,
	A.Articulo,Nombre,ExistUV = ExistenciaActualRegular,
	Relacion = CAST(CAST(FactorCompra AS INT) AS NVARCHAR) + '/' + UnidadCompra + ' - ' + CAST(CAST(FactorVenta AS INT) AS NVARCHAR) + '/' + UnidadVenta,
	CostoNet = UltimoCostoNeto,
	CostoExist = CostoExistenciaNeto,
	Precio = ISNULL(Precio1IVAUV,0.00),
	Util = CASE WHEN Precio1IVAUV = 0 THEN 0.00 ELSE ISNULL(1 - (UltimoCostoNeto/Precio1IVAUV),0.00) END,
	Estatus = CASE WHEN ExistenciaActualRegular >= StockMinimo AND ExistenciaActualRegular <= StockMaximo THEN 'OK' WHEN ExistenciaActualRegular < StockMinimo THEN 'BAJO' WHEN ExistenciaActualRegular > StockMaximo THEN 'SOBRE' ELSE '' END,
	Stock30	= StockMinimo,
	uvAñoAnterior = ISNULL(añoAnterior.CantUV,0.00),
	uvAñoActual = ISNULL(añoActual.CantUV,0.00),
	mxnAñoAnterior = ISNULL(añoAnterior.VentUV,0.00),
	mxnAñoActual = ISNULL(añoActual.VentUV,0.00)
FROM QVListaprecioConCosto A
LEFT JOIN (
	SELECT 
		Articulo,CantUV,CantUC,VentUV 
	FROM OrderListaMovimientosVentaPorPeriodo(@MesActualInicio2,@MesActualFinal2)
	WHERE Articulo IN (SELECT Articulo FROM articulosCTE)
) AS añoAnterior ON añoAnterior.Articulo = A.Articulo
LEFT JOIN (
	SELECT 
		Articulo,CantUV,CantUC,VentUV 
	FROM OrderListaMovimientosVentaPorPeriodo(@MesActualInicio,@MesActualFinal)
	WHERE Articulo IN (SELECT Articulo FROM articulosCTE)
) AS añoActual ON añoActual.Articulo = A.Articulo
WHERE Almacen = @Almacen AND Tienda = @Tienda
	AND A.Articulo IN  (SELECT Articulo FROM articulosCTE)
) AS Tabla
) AS SuperTabla
WHERE Tendencia < 0
