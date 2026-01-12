# =============================================================================
# EJEMPLO 1: Pronóstico Simple con Curvas de Duración
# =============================================================================
# Descripción: Ejemplo básico de pronóstico usando percentiles históricos
# =============================================================================

# Limpiar workspace
rm(list = ls())

# Configurar directorio base (directorio padre del script)
if (interactive()) {
  setwd(dirname(dirname(rstudioapi::getActiveDocumentContext()$path)))
} else {
  # Cuando se ejecuta con Rscript, ir al directorio padre
  script_dir <- dirname(sys.frame(1)$ofile)
  setwd(file.path(script_dir, ".."))
}

# Cargar configuración y módulos
source("config.R")
source(file.path(DIR_R, "01_utilities.R"))
source(file.path(DIR_R, "02_data_loader.R"))
source(file.path(DIR_R, "03_flow_duration.R"))
source(file.path(DIR_R, "06_visualization.R"))

library(ggplot2)

cat("\n=== EJEMPLO 1: PRONÓSTICO CON CURVAS DE DURACIÓN ===\n\n")

# -----------------------------------------------------------------------------
# 1. Cargar datos
# -----------------------------------------------------------------------------

log_msg("Cargando datos de caudal...")

caudal <- prepare_flow_data(
  FILE_SALIDA,
  col_flow = "salida",
  has_header = TRUE,
  fill_method = "locf"
)

log_msg(sprintf("Datos cargados: %d observaciones", length(caudal)))


# -----------------------------------------------------------------------------
# 2. Calcular tabla de referencia de percentiles
# -----------------------------------------------------------------------------

log_msg("\nCreando tabla de referencia mensual...")

tabla_ref <- create_percentile_table(
  caudal,
  percentiles = c(0.15, 0.30, 0.50, 0.70, 0.85)
)

print(tabla_ref)


# -----------------------------------------------------------------------------
# 3. Generar pronóstico para múltiples escenarios
# -----------------------------------------------------------------------------

log_msg("\nGenerando pronósticos desde agosto para 12 meses...")

# Configuración
MES_INICIO <- 8  # Agosto
N_MESES <- 12

# Escenarios: muy húmedo, húmedo, medio, seco, muy seco
escenarios <- forecast_scenarios(
  caudal,
  mes_inicio = MES_INICIO,
  n_meses = N_MESES,
  percentiles = c(0.15, 0.30, 0.50, 0.70, 0.85)
)

print(escenarios)

# Exportar
export_table(escenarios, "ejemplo1_escenarios.csv")


# -----------------------------------------------------------------------------
# 4. Visualizar pronóstico
# -----------------------------------------------------------------------------

log_msg("\nGenerando gráficos...")

# Climatología mensual
p1 <- plot_monthly_climatology(
  caudal,
  title = "Climatología Mensual - Histórico",
  save_plot = TRUE,
  filename = "ejemplo1_climatologia.png"
)
print(p1)

# Escenarios de pronóstico
p2 <- plot_forecast_scenarios(
  escenarios,
  title = "Pronóstico Mensual - Escenarios por Percentil",
  save_plot = TRUE,
  filename = "ejemplo1_pronostico.png"
)
print(p2)


# -----------------------------------------------------------------------------
# 5. Pronóstico ajustado según condición actual (OPCIONAL)
# -----------------------------------------------------------------------------

# Si tienes un caudal observado reciente, puedes ajustar el pronóstico
# Ejemplo: En julio se midieron 4.5 m³/s

log_msg("\nEjemplo de pronóstico ajustado por condición actual...")

CAUDAL_ACTUAL <- 4.5  # m³/s
MES_ACTUAL <- 7       # Julio

pronostico_ajustado <- forecast_from_current(
  caudal,
  mes_actual = MES_ACTUAL,
  caudal_actual = CAUDAL_ACTUAL,
  n_meses = 12,
  factor_ajuste = 0.8  # Ajuste de persistencia
)

print(pronostico_ajustado)
export_table(pronostico_ajustado, "ejemplo1_ajustado.csv")


cat("\n=== EJEMPLO COMPLETADO ===\n")
cat("Archivos generados en:", DIR_OUTPUT, "\n")
cat("Gráficos generados en:", DIR_PLOTS, "\n\n")
