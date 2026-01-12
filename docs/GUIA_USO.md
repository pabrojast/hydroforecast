# =============================================================================
# GUÍA DE USO - SISTEMA DE PRONÓSTICO HIDROLÓGICO
# =============================================================================

## INICIO RÁPIDO

### 1. Preparar el entorno

Asegúrate de tener instalado R (versión >= 4.0) y RStudio (opcional pero recomendado).

### 2. Copiar tus datos

Copia tus archivos CSV de caudales a la carpeta `data/` o al directorio raíz:
- `salida_mensual_es.csv`
- `QHalgodones.csv`
- Otros archivos según necesites

### 3. Ajustar configuración

Edita el archivo `config.R` para ajustar:
- Nombres de archivos de entrada
- Año y mes de inicio de las series
- Percentiles de interés
- Horizonte de pronóstico

### 4. Ejecutar análisis

En R o RStudio, desde el directorio del proyecto:

```r
source("main_forecast.R")
```

## EJEMPLOS DE USO

El directorio `examples/` contiene scripts demostrativos:

### Ejemplo 1: Curvas de Duración
```r
source("examples/ejemplo1_curvas_duracion.R")
```

Muestra cómo:
- Calcular percentiles históricos mensuales
- Generar pronósticos por escenarios (húmedo, medio, seco)
- Ajustar pronóstico según condición actual

### Ejemplo 2: Modelos ARIMA/ETS
```r
source("examples/ejemplo2_modelos_arima_ets.R")
```

Muestra cómo:
- Comparar diferentes modelos de series temporales
- Ajustar y diagnosticar modelos ARIMA
- Generar pronósticos con intervalos de confianza
- Validación cruzada

### Ejemplo 3: Modelo Híbrido
```r
source("examples/ejemplo3_modelo_hibrido.R")
```

Muestra cómo:
- Combinar múltiples modelos (ensemble)
- Optimizar pesos de los modelos
- Comparar diferentes estrategias de combinación

## USO MODULAR

También puedes usar los módulos individualmente:

```r
# Cargar configuración
source("config.R")

# Cargar solo los módulos que necesites
source("R/01_utilities.R")
source("R/02_data_loader.R")
source("R/03_flow_duration.R")

# Cargar datos
caudal <- prepare_flow_data("salida_mensual_es.csv", 
                           col_flow = "salida")

# Generar pronóstico simple
pronostico <- forecast_scenarios(caudal, 
                                 mes_inicio = 8, 
                                 n_meses = 12)
```

## ESTRUCTURA DE DATOS DE ENTRADA

Los archivos CSV deben tener el formato:

### Con encabezados:
```
año,mes,salida
1997,9,5.23
1997,10,4.87
...
```

### Sin encabezados (columnas V1, V2, V3):
```
1997,9,5.23
1997,10,4.87
...
```

Especifica `has_header = TRUE` o `FALSE` al cargar los datos.

## INTERPRETACIÓN DE RESULTADOS

### Percentiles
- **P15 (15%)**: Escenario muy húmedo - solo 15% de los años históricos tiene menos caudal
- **P30 (30%)**: Escenario húmedo
- **P50 (50%)**: Escenario medio (mediana)
- **P70 (70%)**: Escenario seco
- **P85 (85%)**: Escenario muy seco - 85% de los años tiene más caudal

### Modelos de Series Temporales

**ARIMA**: Captura patrones autorregresivos y de media móvil. Bueno para tendencias.

**ETS**: Suavizado exponencial. Bueno para estacionalidad fuerte.

**Híbrido**: Combina fortalezas de múltiples modelos. Más robusto pero computacionalmente costoso.

### Intervalos de Confianza

- **80%**: Mayor probabilidad, rango más estrecho
- **95%**: Mayor certeza, rango más amplio

## PERSONALIZACIÓN

### Agregar nuevas funciones

Crea un nuevo archivo en `R/` siguiendo el formato:
```r
# R/07_mi_modulo.R

mi_funcion <- function(parametro1, parametro2) {
  # Tu código aquí
  return(resultado)
}

if (exists("log_msg")) {
  log_msg("Mi módulo cargado")
}
```

### Modificar gráficos

Las funciones de visualización en `R/06_visualization.R` retornan objetos ggplot2 que puedes personalizar:

```r
p <- plot_flow_series(caudal)

# Personalizar
p <- p + 
  theme_bw() +
  scale_y_continuous(limits = c(0, 10))

print(p)
```

## SOLUCIÓN DE PROBLEMAS

### Error: "Archivo no encontrado"
- Verifica que el archivo esté en `data/` o el directorio raíz
- Revisa el nombre en `config.R`
- Usa rutas absolutas si es necesario

### Error: "Paquete no disponible"
```r
install.packages("nombre_del_paquete")
```

### Serie muy corta
- Curvas de duración: mínimo 12 observaciones
- ARIMA/ETS: mínimo 24 observaciones (2 años)
- Modelos híbridos: mínimo 60 observaciones (5 años)

### Valores faltantes (NA)
El sistema automáticamente rellena NAs usando el último valor observado (LOCF). Puedes cambiar el método en `prepare_flow_data()`:
- `fill_method = "locf"` (último valor)
- `fill_method = "interpolate"` (interpolación lineal)
- `fill_method = "mean"` (media mensual)

## BUENAS PRÁCTICAS

1. **Siempre revisa tus datos**: Usa `plot_flow_series()` para identificar valores anómalos
2. **Compara múltiples métodos**: No confíes en un solo modelo
3. **Valida con datos recientes**: Usa `compare_models()` con datos de prueba
4. **Documenta tus análisis**: Guarda scripts con parámetros específicos
5. **Actualiza regularmente**: Reajusta modelos con nuevos datos

## REFERENCIAS HIDROLÓGICAS

- **Curvas de duración**: Método estándar en hidrología aplicada para gestión de recursos
- **ARIMA estacional**: Captura ciclos anuales en caudales
- **Percentiles**: Base para definición de dotaciones y derechos de agua
- **Validación cruzada**: Esencial para evaluar pronósticos hidrológicos

## CONTACTO Y SOPORTE

Para reportar errores, sugerencias o contribuciones, contacta al autor:
Pablo Rojas - Hidrólogo

---
Última actualización: Enero 2024
