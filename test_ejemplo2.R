#!/usr/bin/env Rscript

# =============================================================================
# TEST EJEMPLO 2: Modelos ARIMA y ETS
# =============================================================================

setwd("/home/pablo/Descargas/script r/Script de pronostico/hydrological_forecast")

cat("\n=== EJEMPLO 2: MODELOS ARIMA Y ETS ===\n\n")

# Cargar configuración y módulos
source("config.R")
source(file.path(DIR_R, "01_utilities.R"))
source(file.path(DIR_R, "02_data_loader.R"))
source(file.path(DIR_R, "04_ts_models.R"))
source(file.path(DIR_R, "06_visualization.R"))

suppressPackageStartupMessages({
  library(forecast)
  library(ggplot2)
})

# 1. Cargar datos
log_msg("Cargando datos de caudal...")

caudal <- prepare_flow_data(
  FILE_SALIDA,
  col_flow = "salida",
  has_header = TRUE
)

# 2. Ajustar modelo ARIMA
log_msg("\nAjustando modelo ARIMA estacional...")

modelo_arima <- fit_auto_arima(caudal, seasonal = TRUE, approximation = FALSE)

cat("\nResumen del modelo ARIMA:\n")
print(summary(modelo_arima))

# 3. Pronóstico 12 meses
fc_arima <- generate_forecast(modelo_arima, h = 12, level = c(80, 95))

# Extraer data frame
df_arima <- extract_forecast_df(fc_arima)
cat("\nPronóstico ARIMA:\n")
print(df_arima)

export_table(df_arima, "test_ejemplo2_pronostico_arima.csv")

# 4. Ajustar modelo ETS
log_msg("\nAjustando modelo ETS...")

modelo_ets <- fit_ets_model(caudal)

cat("\nResumen del modelo ETS:\n")
print(summary(modelo_ets))

# 5. Pronóstico ETS
fc_ets <- generate_forecast(modelo_ets, h = 12)

df_ets <- extract_forecast_df(fc_ets)
export_table(df_ets, "test_ejemplo2_pronostico_ets.csv")

# 6. Comparar modelos
log_msg("\nComparando modelos...")

comparacion <- compare_models(caudal, test_size = 12)

cat("\nComparación de modelos:\n")
print(comparacion)

export_table(comparacion, "test_ejemplo2_comparacion.csv")

cat("\n=== EJEMPLO 2 COMPLETADO EXITOSAMENTE ===\n")
cat("Archivos generados en:", DIR_OUTPUT, "\n\n")
