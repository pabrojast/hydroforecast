#!/usr/bin/env Rscript

# =============================================================================
# TEST EJEMPLO 1: Curvas de Duración
# =============================================================================

# Establecer directorio de trabajo
setwd("/home/pablo/Descargas/script r/Script de pronostico/hydrological_forecast")

cat("\n=== EJEMPLO 1: PRONÓSTICO CON CURVAS DE DURACIÓN ===\n\n")

# Cargar configuración y módulos
source("config.R")
source(file.path(DIR_R, "01_utilities.R"))
source(file.path(DIR_R, "02_data_loader.R"))
source(file.path(DIR_R, "03_flow_duration.R"))
source(file.path(DIR_R, "06_visualization.R"))

suppressPackageStartupMessages({
  library(ggplot2)
  library(data.table)
})

# 1. Cargar datos
log_msg("Cargando datos de caudal...")

caudal <- prepare_flow_data(
  FILE_SALIDA,
  col_flow = "salida",
  has_header = TRUE,
  fill_method = "locf"
)

log_msg(sprintf("Datos cargados: %d observaciones", length(caudal)))

# 2. Calcular tabla de referencia de percentiles
log_msg("\nCreando tabla de referencia mensual...")

tabla_ref <- create_percentile_table(
  caudal,
  percentiles = c(0.15, 0.30, 0.50, 0.70, 0.85)
)

cat("\nTabla de Percentiles Mensuales:\n")
print(head(tabla_ref, 12))

# 3. Generar pronóstico para múltiples escenarios
log_msg("\nGenerando pronósticos desde agosto para 12 meses...")

MES_INICIO <- 8  # Agosto
N_MESES <- 12

escenarios <- forecast_scenarios(
  caudal,
  mes_inicio = MES_INICIO,
  n_meses = N_MESES,
  percentiles = c(0.15, 0.30, 0.50, 0.70, 0.85)
)

cat("\nPronóstico por Escenarios:\n")
print(escenarios)

# Exportar
export_table(escenarios, "test_ejemplo1_escenarios.csv")

# 4. Visualizar pronóstico
log_msg("\nGenerando gráficos...")

# Climatología mensual
p1 <- plot_monthly_climatology(
  caudal,
  title = "Climatología Mensual - Histórico",
  save_plot = TRUE,
  filename = "test_ejemplo1_climatologia.png"
)

# Escenarios de pronóstico
p2 <- plot_forecast_scenarios(
  escenarios,
  title = "Pronóstico Mensual - Escenarios por Percentil",
  save_plot = TRUE,
  filename = "test_ejemplo1_pronostico.png"
)

# 5. Pronóstico ajustado según condición actual
log_msg("\nEjemplo de pronóstico ajustado por condición actual...")

CAUDAL_ACTUAL <- 4.5  # m³/s
MES_ACTUAL <- 7       # Julio

pronostico_ajustado <- forecast_from_current(
  caudal,
  mes_actual = MES_ACTUAL,
  caudal_actual = CAUDAL_ACTUAL,
  n_meses = 12,
  factor_ajuste = 0.8
)

cat("\nPronóstico Ajustado:\n")
print(head(pronostico_ajustado, 12))

export_table(pronostico_ajustado, "test_ejemplo1_ajustado.csv")

cat("\n=== EJEMPLO 1 COMPLETADO EXITOSAMENTE ===\n")
cat("Archivos generados en:", DIR_OUTPUT, "\n")
cat("Gráficos generados en:", DIR_PLOTS, "\n\n")
