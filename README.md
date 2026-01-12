# HydroForecast

## Descripción
Sistema modular para pronóstico de caudales utilizando múltiples metodologías:
- Curvas de duración de caudales (percentiles históricos)
- Modelos ARIMA y ETS
- Modelos híbridos (ARIMA + ETS + NNETAR + STLM + TBATS)
- Pronóstico basado en cobertura de nieve

## Estructura del Proyecto

```
hydroforecast/
├── R/                      # Módulos de funciones
│   ├── 01_utilities.R      # Funciones auxiliares
│   ├── 02_data_loader.R    # Carga y validación de datos
│   ├── 03_flow_duration.R  # Curvas de duración
│   ├── 04_ts_models.R      # Modelos de series temporales
│   ├── 05_snow_forecast.R  # Pronóstico por nieve
│   └── 06_visualization.R  # Visualizaciones profesionales
├── data/                   # Datos de entrada
├── output/                 # Resultados (CSV, tablas)
├── plots/                  # Gráficos generados
├── docs/                   # Documentación adicional
├── config.R               # Configuración global
├── main_forecast.R        # Script principal
└── examples/              # Ejemplos de uso
```

## Instalación de Dependencias

```r
# Instalar paquetes requeridos
install.packages(c(
  "xts", "zoo", "hydroTSM", "ggplot2", "data.table",
  "forecast", "forecastHybrid", "ggfortify",
  "tidyverse", "scales", "patchwork", "viridis"
))
```

## Uso Básico

```r
# Cargar configuración
source("config.R")

# Cargar módulos
source("R/01_utilities.R")
source("R/02_data_loader.R")
source("R/03_flow_duration.R")
source("R/04_ts_models.R")
source("R/06_visualization.R")

# Ejecutar pronóstico
source("main_forecast.R")
```

## Metodologías

### 1. Curva de Duración de Caudales
Pronóstico basado en percentiles históricos mensuales. Permite estimar escenarios:
- Húmedos (P15, P30)
- Medios (P50)
- Secos (P70, P85)

### 2. Modelos de Series Temporales
- **ARIMA**: Auto-regresivo integrado de media móvil
- **ETS**: Suavizado exponencial
- **Híbridos**: Combinación de múltiples modelos para mejor precisión

### 3. Pronóstico Basado en Nieve
Correlación entre cobertura de nieve satelital y caudales futuros.

## Mejoras Implementadas

✅ **Código Modular**: Funciones reutilizables en módulos separados
✅ **Documentación**: Funciones documentadas con roxygen2-style
✅ **Visualizaciones**: Gráficos profesionales con ggplot2 y paletas científicas
✅ **Manejo de Errores**: Validación de datos y mensajes informativos
✅ **Configuración Centralizada**: Parámetros en archivo único
✅ **Reproducibilidad**: Estructura clara y scripts de ejemplo
✅ **Buenas Prácticas**: Nombres descriptivos, código limpio, comentarios apropiados

## Autor
Pablo Rojas - Hidrólogo
Versión mejorada con mejores prácticas de programación

## Licencia
MIT
