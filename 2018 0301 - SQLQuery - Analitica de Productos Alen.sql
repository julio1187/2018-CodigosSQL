
DECLARE @CedisTienda INT = 6, @CedisAlmacen INT = 21

SELECT COTI.*
	,ESTA.ExistUV,ESTA.ExistUC,ESTA.StockMinimoActUV,ESTA.StockMinimoActUC,ESTA.StockMinimoTriUV,ESTA.StockMinimoTriUC
	,PedidoSugeridoActCAL = CASE WHEN ( ESTA.StockMinimoActUC - ESTA.ExistUC ) - FLOOR( ESTA.StockMinimoActUC - ESTA.ExistUC ) >= 0.50 THEN (CASE WHEN (FLOOR( ESTA.StockMinimoActUC - ESTA.ExistUC ) + 1) >= 0 THEN FLOOR( ESTA.StockMinimoActUC - ESTA.ExistUC ) + 1 ELSE 0 END) ELSE (CASE WHEN FLOOR( ESTA.StockMinimoActUC - ESTA.ExistUC ) >= 0 THEN FLOOR( ESTA.StockMinimoActUC - ESTA.ExistUC ) ELSE 0 END) END
	,PedidoSugeridoTriCAL = CASE WHEN ( ESTA.StockMinimoTriUC - ESTA.ExistUC ) - FLOOR( ESTA.StockMinimoTriUC - ESTA.ExistUC ) >= 0.50 THEN (CASE WHEN (FLOOR( ESTA.StockMinimoTriUC - ESTA.ExistUC ) + 1) >= 0 THEN FLOOR( ESTA.StockMinimoTriUC - ESTA.ExistUC ) + 1 ELSE 0 END) ELSE (CASE WHEN FLOOR( ESTA.StockMinimoTriUC - ESTA.ExistUC ) >= 0 THEN FLOOR( ESTA.StockMinimoTriUC - ESTA.ExistUC ) ELSE 0 END) END
	,ExistZaragoza = EZ.ExistUC, MinZaragoza = EZ.StockMinimoActUC, MinTriZaragoza = EZ.StockMinimoTriUC
	,ExistVictoria = EV.ExistUC, MinVictoria = EV.StockMinimoActUC, MinTriVictoria = EV.StockMinimoTriUC
	,ExistOluta = EO.ExistUC, MinOluta = EO.StockMinimoActUC, MinTriOluta = EO.StockMinimoTriUC
	,ExistJaltipan = EJ.ExistUC, MinJaltipan = EJ.StockMinimoActUC, MinTriJaltipan = EJ.StockMinimoTriUC
	,ExistBodega = EB.ExistUC
	,FechaCompra = ISNULL(Compra.UltimaCompra,CAST('20110101' AS DATETIME))
	,Dias =	ISNULL(DATEDIFF(DAY,Compra.UltimaCompra,GETDATE()),DATEDIFF(DAY,CAST('20110101' AS DATETIME),GETDATE()))
	,UltimoCostoUV = ISNULL(Costo.UltimoCostoNeto,0.00)
	,UltimoCostoUC = ISNULL(Costo.UltimoCostoNetoUC,0.00)
FROM (
	SELECT E.CodigoBarras,Tipo = L.Tipo,Marca = L.Marca,
		E.DescripcionSubfamilia,X.Articulo,E.Nombre,
		Relacion = '[' + CAST(CAST(E.FactorCompra AS INT) AS NVARCHAR) + ' ' + E.UnidadCompra + ' - ' + CAST(CAST(E.FactorVenta AS INT) AS NVARCHAR) + ' ' + E.UnidadVenta + ']'
	FROM OrderListaCotizacionArticulos X
	LEFT JOIN OrderListaCatalogoArticulos() L ON L.Articulo = X.Articulo
	LEFT JOIN QVExistencias AS E ON E.Articulo = X.Articulo AND E.Tienda = @CedisTienda AND E.Almacen = @CedisAlmacen
) AS COTI
LEFT JOIN (
	SELECT Articulo
		,ExistUV = SUM(ExistUV), ExistUC = SUM(ExistUC)
		,StockMinimoActUV = SUM(StockMinimoActUV), StockMinimoActUC = SUM(StockMinimoActUC)
		,StockMinimoTriUV = SUM(StockMinimoTriUV), StockMinimoTriUC = SUM(StockMinimoTriUC)
	FROM CA2015.dbo.RESUMENALEN
	GROUP BY Articulo
) AS ESTA ON ESTA.Articulo = COTI.Articulo
LEFT JOIN (
	 SELECT
				ArticuloB		=	Articulo,
				UltimaCompra	=	MAX(Fecha+Hora)
	 FROM	SPABODEGA.dbo.QVDEMovAlmacen
	 WHERE		Almacen = @CedisAlmacen AND Tienda = @CedisTienda AND TipoDocumento = 'C' AND Estatus = 'E'
			AND Articulo IN (
					SELECT Articulo FROM CA2015.dbo.RESUMENALEN WHERE Almacen = @CedisAlmacen AND Tienda = @CedisTienda
				)
	 GROUP BY	Articulo
) Compra ON Compra.ArticuloB = COTI.Articulo
LEFT JOIN (
	SELECT 
		Articulo,UltimoCostoNeto,UltimoCostoNetoUC
	FROM SPABODEGA.dbo.QVExistencias
	WHERE Almacen = @CedisAlmacen AND Tienda = @CedisTienda
		AND Articulo IN (
			SELECT Articulo FROM CA2015.dbo.RESUMENALEN WHERE Almacen = @CedisAlmacen AND Tienda = @CedisTienda
		)
) Costo ON Costo.Articulo = COTI.Articulo
LEFT JOIN CA2015.dbo.RESUMENALEN EZ ON EZ.Articulo = COTI.Articulo AND EZ.Almacen = 2 AND EZ.Tienda = 1
LEFT JOIN CA2015.dbo.RESUMENALEN EV ON EV.Articulo = COTI.Articulo AND EV.Almacen = 3 AND EV.Tienda = 2
LEFT JOIN CA2015.dbo.RESUMENALEN EO ON EO.Articulo = COTI.Articulo AND EO.Almacen = 19 AND EO.Tienda = 5
LEFT JOIN CA2015.dbo.RESUMENALEN EJ ON EJ.Articulo = COTI.Articulo AND EJ.Almacen = 7 AND EJ.Tienda = 4
LEFT JOIN CA2015.dbo.RESUMENALEN EB ON EB.Articulo = COTI.Articulo AND EB.Almacen = 21 AND EB.Tienda = 6
ORDER BY Tipo,Marca,Coti.Articulo