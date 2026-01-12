# =============================================================================
# EJEMPLO 2: Pronóstico con Modelos ARIMA y ETS
# =============================================================================
# Descripción: Comparación y pronóstico con modelos de series temporales
# =============================================================================

# Limpiar workspace
rm(list = ls())

# ============================================================================
# Configurar directorio base - Compatible con múltiples formas de ejecución
# ============================================================================

find_project_root <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  
  if (length(file_arg) > 0) {
    script_path <- normalizePath(sub("^--file=", "", file_arg))
    script_dir <- dirname(script_path)
    if (basename(script_dir) == "examples") {
      return(dirname(script_dir))
    } else {
      return(script_dir)
    }
  }
  
  current_dir <- getwd()
  if (basename(current_dir) == "examples") {
    parent_dir <- dirname(current_dir)
    if (file.exists(file.path(parent_dir, "config.R"))) {
      return(parent_dir)
    }
  }
  
  if (file.exists(file.path(current_dir, "config.R"))) {
    return(current_dir)
  }
  
  search_dir <- current_dir
  for (i in 1:3) {
    if (file.exists(file.path(search_dir, "config.R"))) {
      return(search_dir)
    }
    search_dir <- dirname(search_dir)
  }
  
  stop("No se pudo encontrar el directorio del proyecto (config.R no encontrado)")
}

project_root <- find_project_root()
setwd(project_root)

cat(sprintf("\n✓ Directorio de trabajo: %s\n\n", getwd()))

# Cargar configuración y módulos
source("config.R")
source(file.path(DIR_R, "01_utilities.R"))
source(file.path(DIR_R, "02_data_loader.R"))
source(file.path(DIR_R, "04_ts_models.R"))
source(file.path(DIR_R, "06_visualization.R"))

library(forecast)
library(ggplot2)

cat("\n=== EJEMPLO 2: MODELOS ARIMA Y ETS ===\n\n")

# -----------------------------------------------------------------------------
# 1. Cargar datos
# -----------------------------------------------------------------------------

log_msg("Cargando datos de caudal...")

caudal <- prepare_flow_data(
  FILE_SALIDA,
  col_flow = "salida",
  has_header = TRUE
)


# -----------------------------------------------------------------------------
# 2. Comparar diferentes modelos
# -----------------------------------------------------------------------------

log_msg("\nComparando modelos ARIMA y ETS...")

comparacion <- compare_models(caudal, test_size = 12)

print(comparacion)

# Exportar
export_table(comparacion, "ejemplo2_comparacion_modelos.csv")


# -----------------------------------------------------------------------------
# 3. Ajustar modelo ARIMA
# -----------------------------------------------------------------------------

log_msg("\nAjustando modelo ARIMA estacional...")

modelo_arima <- fit_auto_arima(caudal, seasonal = TRUE, approximation = FALSE)

# Resumen del modelo
print(summary(modelo_arima))

# Pronóstico 12 meses
fc_arima <- generate_forecast(modelo_arima, h = 12, level = c(80, 95))

# Extraer data frame
df_arima <- extract_forecast_df(fc_arima)
print(df_arima)

export_table(df_arima, "ejemplo2_pronostico_arima.csv")

# Visualizar
plot1 <- plot_ts_forecast(
  caudal,
  fc_arima,
  title = "Pronóstico ARIMA - 12 meses",
  n_years = 5,
  save_plot = TRUE,
  filename = "ejemplo2_arima.png"
)
print(plot1)


# -----------------------------------------------------------------------------
# 4. Ajustar modelo ETS
# -----------------------------------------------------------------------------

log_msg("\nAjustando modelo ETS...")

modelo_ets <- fit_ets_model(caudal)

# Resumen
print(summary(modelo_ets))

# Pronóstico
fc_ets <- generate_forecast(modelo_ets, h = 12)

# Visualizar
plot2 <- plot_ts_forecast(
  caudal,
  fc_ets,
  title = "Pronóstico ETS - 12 meses",
  n_years = 5,
  save_plot = TRUE,
  filename = "ejemplo2_ets.png"
)
print(plot2)


# -----------------------------------------------------------------------------
# 5. Diagnóstico del modelo
# -----------------------------------------------------------------------------

log_msg("\nDiagnóstico del modelo ARIMA...")

# Gráfico de residuales
png(file.path(DIR_PLOTS, "ejemplo2_diagnostico_arima.png"), 
    width = 12, height = 8, units = "in", res = 300)
checkresiduals(modelo_arima)
dev.off()

log_msg("Diagnóstico guardado")


# -----------------------------------------------------------------------------
# 6. Validación cruzada (opcional)
# -----------------------------------------------------------------------------

log_msg("\nRealizando validación cruzada...")

cv_results <- time_series_cv(caudal, h = 6, initial = 48)

# Mostrar RMSE por horizonte
cat("\nRMSE por horizonte de pronóstico:\n")
print(data.frame(Horizonte = 1:length(cv_results$RMSE), 
                 RMSE = cv_results$RMSE))


cat("\n=== EJEMPLO COMPLETADO ===\n")
cat("Archivos generados en:", DIR_OUTPUT, "\n")
cat("Gráficos generados en:", DIR_PLOTS, "\n\n")
