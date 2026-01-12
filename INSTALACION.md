# =============================================================================
# INSTALACIÓN Y CONFIGURACIÓN INICIAL
# =============================================================================

## Requisitos del Sistema

- **R**: Versión 4.0 o superior
- **RStudio**: Recomendado (opcional)
- **Espacio en disco**: ~50 MB para paquetes

## Instalación de Dependencias

### Opción 1: Instalación Automática

Al ejecutar `main_forecast.R` por primera vez, los paquetes faltantes se instalarán automáticamente.

### Opción 2: Instalación Manual

Ejecuta el siguiente código en R:

```r
# Paquetes principales
install.packages(c(
  "xts",           # Series temporales extendidas
  "zoo",           # Manejo de series temporales irregulares
  "hydroTSM",      # Análisis hidrológico de series temporales
  "ggplot2",       # Visualización avanzada
  "data.table",    # Manipulación eficiente de datos
  "tidyr",         # Transformación de datos
  "dplyr",         # Manipulación de datos
  "scales",        # Escalas para gráficos
  "viridis"        # Paletas de colores
))

# Paquetes de pronóstico
install.packages(c(
  "forecast",       # Modelos ARIMA, ETS, etc.
  "ggfortify"       # Visualización de modelos forecast
))

# Paquete opcional para modelos híbridos (avanzado)
install.packages("forecastHybrid")
```

## Configuración Inicial

### 1. Verificar Instalación

```r
# Cargar paquetes principales
library(forecast)
library(ggplot2)
library(xts)

# Si no hay errores, la instalación fue exitosa
print("✓ Instalación correcta")
```

### 2. Configurar Rutas de Datos

Edita `config.R` para especificar tus archivos:

```r
# Nombres de archivos (en data/ o directorio raíz)
FILE_ENTRADA <- "QHalgodones.csv"
FILE_SALIDA <- "salida_mensual_es.csv"

# Parámetros de series temporales
START_YEAR <- 1997
START_MONTH <- 9
```

### 3. Verificar Estructura de Datos

Tus archivos CSV deben tener una de estas estructuras:

**Opción A - Con encabezados:**
```
año,mes,caudal
1997,9,5.23
1997,10,4.87
```

**Opción B - Sin encabezados:**
```
1997,9,5.23
1997,10,4.87
```

Ajusta en `config.R` o al llamar `load_flow_data()`:
- `has_header = TRUE` o `FALSE`
- `col_flow = "caudal"` (nombre) o `col_flow = 3` (número de columna)

### 4. Primera Ejecución

```r
# Configurar directorio de trabajo
setwd("/ruta/a/hydrological_forecast")

# Ejecutar análisis completo
source("main_forecast.R")
```

Si todo está correcto, verás:
```
========================================================================
  SISTEMA DE PRONÓSTICO HIDROLÓGICO - v2.0
  Análisis y Pronóstico de Caudales
========================================================================

[TIMESTAMP] INFO: Configuración cargada exitosamente
[TIMESTAMP] INFO: Módulo de utilidades cargado correctamente
...
```

## Solución de Problemas Comunes

### Error: "there is no package called 'XXX'"

**Solución:**
```r
install.packages("XXX")
```

### Error: "archivo no encontrado"

**Solución 1:** Verificar ruta
```r
getwd()  # Ver directorio actual
# Debe ser: .../hydrological_forecast
```

**Solución 2:** Usar ruta completa en config.R
```r
FILE_SALIDA <- "/ruta/completa/salida_mensual_es.csv"
```

**Solución 3:** Copiar archivos a `data/`
```bash
cp *.csv hydrological_forecast/data/
```

### Error: "objeto no encontrado"

**Causa:** No se cargaron los módulos

**Solución:**
```r
source("config.R")
source("R/01_utilities.R")
source("R/02_data_loader.R")
# ... resto de módulos
```

### Warning: "Serie contiene X valores NA"

**Normal:** El sistema lo maneja automáticamente
**Acción:** Revisar si el porcentaje es muy alto (>10%)

### Error en modelos híbridos: "not enough observations"

**Causa:** Serie temporal muy corta

**Solución:** Usa solo modelos simples (ARIMA, ETS) o consigue más datos
```r
# En lugar de modelo híbrido, usa:
modelo <- fit_auto_arima(caudal)
```

## Verificación de la Instalación

Ejecuta este script de prueba:

```r
# test_instalacion.R
source("config.R")
source("R/01_utilities.R")
source("R/02_data_loader.R")

# Crear datos de prueba
set.seed(123)
caudal_test <- ts(
  rnorm(120, mean = 5, sd = 2),
  frequency = 12,
  start = c(2010, 1)
)

# Probar funciones básicas
stats <- calculate_monthly_stats(caudal_test)
print("✓ Módulo de utilidades funcional")

# Probar pronóstico
source("R/03_flow_duration.R")
fc <- forecast_scenarios(caudal_test, mes_inicio = 6, n_meses = 12)
print("✓ Módulo de pronóstico funcional")

# Probar visualización
source("R/06_visualization.R")
library(ggplot2)
p <- plot_monthly_climatology(caudal_test, save_plot = FALSE)
print("✓ Módulo de visualización funcional")

cat("\n========================================\n")
cat("  INSTALACIÓN VERIFICADA EXITOSAMENTE\n")
cat("========================================\n")
```

Si ves el mensaje final, ¡estás listo para usar el sistema!

## Próximos Pasos

1. **Lee la documentación:**
   - `README.md`: Descripción general
   - `docs/GUIA_USO.md`: Guía detallada de uso
   - `docs/MEJORAS_IMPLEMENTADAS.md`: Detalles técnicos

2. **Ejecuta los ejemplos:**
   - `examples/ejemplo1_curvas_duracion.R`: Inicio rápido
   - `examples/ejemplo2_modelos_arima_ets.R`: Modelos estándar
   - `examples/ejemplo3_modelo_hibrido.R`: Avanzado

3. **Adapta a tus datos:**
   - Copia tus CSV a `data/`
   - Ajusta `config.R`
   - Ejecuta `main_forecast.R`

4. **Personaliza:**
   - Modifica parámetros en `config.R`
   - Ajusta colores y estilos en visualizaciones
   - Agrega tus propias funciones en nuevos módulos

## Soporte

Para problemas técnicos:
1. Revisa la sección "Solución de Problemas" en `docs/GUIA_USO.md`
2. Verifica que tus datos tengan el formato correcto
3. Consulta la documentación de las funciones (comentarios en código)

¡Buena suerte con tus pronósticos hidrológicos! 🌊📊
