# =============================================================================
# SCRIPT PRINCIPAL - SISTEMA DE PRONÓSTICO HIDROLÓGICO
# =============================================================================
# Autor: Pablo Rojas
# Descripción: Análisis completo y generación de pronósticos de caudal
# Fecha: 2024
# =============================================================================

# Limpiar workspace
rm(list = ls())

# =============================================================================
# 1. CONFIGURACIÓN Y CARGA DE MÓDULOS
# =============================================================================

cat("\n")
cat("========================================================================\n")
cat("  SISTEMA DE PRONÓSTICO HIDROLÓGICO - v2.0\n")
cat("  Análisis y Pronóstico de Caudales\n")
cat("========================================================================\n\n")

# Cargar configuración
source("config.R")

# Cargar módulos
source(file.path(DIR_R, "01_utilities.R"))
source(file.path(DIR_R, "02_data_loader.R"))
source(file.path(DIR_R, "03_flow_duration.R"))
source(file.path(DIR_R, "04_ts_models.R"))
source(file.path(DIR_R, "06_visualization.R"))

# Instalar paquetes faltantes
required_packages <- c("xts", "zoo", "hydroTSM", "ggplot2", "data.table",
                      "forecast", "tidyr", "dplyr", "scales", "viridis")

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    log_msg(sprintf("Instalando paquete: %s", pkg), "INFO")
    install.packages(pkg, quiet = TRUE)
    library(pkg, character.only = TRUE)
  }
}

log_msg("Todos los módulos y paquetes cargados correctamente\n")


# =============================================================================
# 2. CARGA Y PREPARACIÓN DE DATOS
# =============================================================================

log_msg("=== ETAPA 1: CARGA DE DATOS ===")

# Cargar datos de salida (embalse)
caudal_salida <- prepare_flow_data(
  FILE_SALIDA,
  col_year = 1,
  col_month = 2,
  col_flow = "salida",
  start_year = START_YEAR,
  start_month = START_MONTH,
  has_header = TRUE,
  fill_method = "locf",
  clean = TRUE
)

# Resumen de datos
log_msg(sprintf("\nDatos cargados: %d observaciones (%.1f años)",
                length(caudal_salida),
                length(caudal_salida) / 12))
log_msg(sprintf("Período: %s - %s",
                paste(start(caudal_salida), collapse = "-"),
                paste(end(caudal_salida), collapse = "-")))
log_msg(sprintf("Estadísticas: Min=%.2f, Media=%.2f, Max=%.2f m³/s",
                min(caudal_salida, na.rm = TRUE),
                mean(caudal_salida, na.rm = TRUE),
                max(caudal_salida, na.rm = TRUE)))


# =============================================================================
# 3. ANÁLISIS EXPLORATORIO
# =============================================================================

log_msg("\n=== ETAPA 2: ANÁLISIS EXPLORATORIO ===")

# Calcular estadísticas mensuales
stats_mensuales <- calculate_monthly_stats(caudal_salida)
log_msg("Estadísticas mensuales calculadas")

# Exportar tabla de estadísticas
export_table(stats_mensuales, "estadisticas_mensuales.csv")

# Crear gráficos exploratorios
log_msg("Generando gráficos exploratorios...")

# Gráfico 1: Serie completa
plot1 <- plot_flow_series(
  caudal_salida,
  title = "Serie Histórica de Caudales de Salida",
  save_plot = TRUE,
  filename = "01_serie_historica.png"
)

# Gráfico 2: Climatología mensual
plot2 <- plot_monthly_climatology(
  caudal_salida,
  title = "Climatología Mensual - Caudales de Salida",
  save_plot = TRUE,
  filename = "02_climatologia_mensual.png"
)


# =============================================================================
# 4. PRONÓSTICO POR CURVAS DE DURACIÓN (PERCENTILES)
# =============================================================================

log_msg("\n=== ETAPA 3: PRONÓSTICO POR CURVAS DE DURACIÓN ===")

# Configurar pronóstico
mes_actual <- 7  # Julio (ajustar según necesidad)
n_meses_fc <- 12

# Generar escenarios múltiples
log_msg(sprintf("Generando pronósticos desde mes %s para %d meses",
                month.abb[mes_actual], n_meses_fc))

escenarios <- forecast_scenarios(
  caudal_salida,
  mes_inicio = mes_actual,
  n_meses = n_meses_fc,
  percentiles = PERCENTILES,
  nombres_escenarios = NOMBRES_PERCENTILES
)

log_msg("Escenarios generados exitosamente")

# Exportar resultados
export_table(escenarios, "pronostico_escenarios.csv")

# Visualizar escenarios
plot3 <- plot_forecast_scenarios(
  escenarios,
  title = sprintf("Pronóstico de Caudales - Inicio: %s", month.abb[mes_actual]),
  save_plot = TRUE,
  filename = "03_pronostico_escenarios.png"
)

# Crear tabla de referencia de percentiles
tabla_percentiles <- create_percentile_table(caudal_salida, percentiles = PERCENTILES)
export_table(tabla_percentiles, "tabla_referencia_percentiles.csv")

# Pronóstico ajustado por condición actual (ejemplo)
# Si se tiene un caudal observado reciente:
# caudal_observado_actual <- 3.13  # Ejemplo
# fc_ajustado <- forecast_from_current(
#   caudal_salida,
#   mes_actual = mes_actual,
#   caudal_actual = caudal_observado_actual,
#   n_meses = n_meses_fc,
#   factor_ajuste = FACTOR_AJUSTE
# )
# export_table(fc_ajustado, "pronostico_ajustado_actual.csv")


# =============================================================================
# 5. PRONÓSTICO CON MODELOS DE SERIES TEMPORALES
# =============================================================================

log_msg("\n=== ETAPA 4: MODELOS DE SERIES TEMPORALES ===")

# Verificar longitud suficiente
if (length(caudal_salida) >= 48) {
  
  # Comparar modelos
  log_msg("Comparando diferentes modelos...")
  comparacion <- compare_models(caudal_salida, test_size = 12)
  print(comparacion)
  export_table(comparacion, "comparacion_modelos.csv")
  
  # Seleccionar y ajustar mejor modelo
  mejor_modelo_nombre <- comparacion$Modelo[1]
  log_msg(sprintf("Ajustando modelo final: %s", mejor_modelo_nombre))
  
  if (mejor_modelo_nombre == "ARIMA_Seasonal") {
    modelo_final <- fit_auto_arima(caudal_salida, seasonal = TRUE)
  } else if (mejor_modelo_nombre == "ARIMA") {
    modelo_final <- fit_auto_arima(caudal_salida, seasonal = FALSE)
  } else if (mejor_modelo_nombre == "ETS") {
    modelo_final <- fit_ets_model(caudal_salida)
  } else {
    # Default
    modelo_final <- fit_auto_arima(caudal_salida, seasonal = TRUE)
  }
  
  # Generar pronóstico
  fc_ts <- generate_forecast(modelo_final, h = n_meses_fc, level = c(80, 95))
  
  # Extraer y exportar pronóstico
  df_fc_ts <- extract_forecast_df(fc_ts)
  export_table(df_fc_ts, "pronostico_modelo_ts.csv")
  
  # Visualizar
  plot4 <- plot_ts_forecast(
    caudal_salida,
    fc_ts,
    title = sprintf("Pronóstico - Modelo %s", mejor_modelo_nombre),
    n_years = 5,
    save_plot = TRUE,
    filename = "04_pronostico_modelo_ts.png"
  )
  
  log_msg("Pronóstico con modelo de series temporales completado")
  
} else {
  log_msg("Serie muy corta para modelos de series temporales", "WARNING")
}


# =============================================================================
# 6. MODELO HÍBRIDO (OPCIONAL - REQUIERE DATOS SUFICIENTES)
# =============================================================================

# Solo ejecutar si hay suficientes datos
if (length(caudal_salida) >= 60) {
  
  log_msg("\n=== ETAPA 5: MODELO HÍBRIDO (ENSEMBLE) ===")
  
  tryCatch({
    # Intentar ajustar modelo híbrido
    if (require("forecastHybrid", quietly = TRUE)) {
      log_msg("Ajustando modelo híbrido (esto puede tomar varios minutos)...")
      
      modelo_hibrido <- fit_hybrid_model(
        caudal_salida,
        weights = "insample",
        models = "aens"  # ARIMA, ETS, NNETAR, STLM
      )
      
      # Generar pronóstico
      fc_hibrido <- generate_forecast(modelo_hibrido, h = n_meses_fc)
      
      # Extraer y exportar
      df_fc_hibrido <- extract_forecast_df(fc_hibrido)
      export_table(df_fc_hibrido, "pronostico_modelo_hibrido.csv")
      
      # Visualizar
      plot5 <- plot_ts_forecast(
        caudal_salida,
        fc_hibrido,
        title = "Pronóstico - Modelo Híbrido (Ensemble)",
        n_years = 5,
        save_plot = TRUE,
        filename = "05_pronostico_hibrido.png"
      )
      
      log_msg("Modelo híbrido completado exitosamente")
    }
  }, error = function(e) {
    log_msg(sprintf("Error en modelo híbrido: %s", e$message), "WARNING")
    log_msg("Continuando sin modelo híbrido...", "INFO")
  })
}


# =============================================================================
# 7. RESUMEN Y REPORTE FINAL
# =============================================================================

log_msg("\n=== RESUMEN FINAL ===")

cat("\n")
cat("========================================================================\n")
cat("  ANÁLISIS COMPLETADO\n")
cat("========================================================================\n\n")

cat("Archivos generados:\n")
cat("  DATOS:\n")
cat("    - estadisticas_mensuales.csv\n")
cat("    - tabla_referencia_percentiles.csv\n")
cat("    - pronostico_escenarios.csv\n")
if (exists("df_fc_ts")) {
  cat("    - pronostico_modelo_ts.csv\n")
  cat("    - comparacion_modelos.csv\n")
}
if (exists("df_fc_hibrido")) {
  cat("    - pronostico_modelo_hibrido.csv\n")
}

cat("\n  GRÁFICOS:\n")
cat("    - 01_serie_historica.png\n")
cat("    - 02_climatologia_mensual.png\n")
cat("    - 03_pronostico_escenarios.png\n")
if (exists("plot4")) {
  cat("    - 04_pronostico_modelo_ts.png\n")
}
if (exists("plot5")) {
  cat("    - 05_pronostico_hibrido.png\n")
}

cat("\n")
cat(sprintf("Ubicación de resultados:\n"))
cat(sprintf("  Datos:    %s\n", DIR_OUTPUT))
cat(sprintf("  Gráficos: %s\n", DIR_PLOTS))

cat("\n========================================================================\n")
cat("  Proceso finalizado exitosamente\n")
cat(sprintf("  Fecha: %s\n", Sys.time()))
cat("========================================================================\n\n")

# Limpiar objetos temporales
rm(required_packages, pkg)
