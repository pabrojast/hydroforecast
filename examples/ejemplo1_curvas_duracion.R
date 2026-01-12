# =============================================================================
# EJEMPLO 1: Pronóstico Simple con Curvas de Duración
# =============================================================================
# Descripción: Ejemplo básico de pronóstico usando percentiles históricos
# =============================================================================

# Limpiar workspace
rm(list = ls())

# ============================================================================
# Configurar directorio base - Compatible con múltiples formas de ejecución
# ============================================================================

# Función para encontrar el directorio raíz del proyecto
find_project_root <- function() {
  # Método 1: Si se ejecuta con Rscript
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  
  if (length(file_arg) > 0) {
    # Obtener path del script
    script_path <- normalizePath(sub("^--file=", "", file_arg))
    script_dir <- dirname(script_path)
    
    # Si estamos en examples/, subir un nivel
    if (basename(script_dir) == "examples") {
      return(dirname(script_dir))
    } else {
      return(script_dir)
    }
  }
  
  # Método 2: Modo interactivo - buscar config.R
  current_dir <- getwd()
  
  # Si estamos en examples/, subir un nivel
  if (basename(current_dir) == "examples") {
    parent_dir <- dirname(current_dir)
    if (file.exists(file.path(parent_dir, "config.R"))) {
      return(parent_dir)
    }
  }
  
  # Si ya estamos en el directorio correcto
  if (file.exists(file.path(current_dir, "config.R"))) {
    return(current_dir)
  }
  
  # Buscar hacia arriba hasta encontrar config.R
  search_dir <- current_dir
  for (i in 1:3) {  # Buscar hasta 3 niveles arriba
    if (file.exists(file.path(search_dir, "config.R"))) {
      return(search_dir)
    }
    search_dir <- dirname(search_dir)
  }
  
  stop("No se pudo encontrar el directorio del proyecto (config.R no encontrado)")
}

# Establecer directorio de trabajo
project_root <- find_project_root()
setwd(project_root)

cat(sprintf("\n✓ Directorio de trabajo: %s\n\n", getwd()))

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
