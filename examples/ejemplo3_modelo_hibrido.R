# =============================================================================
# EJEMPLO 3: Modelo Híbrido (Ensemble)
# =============================================================================
# Descripción: Combina múltiples modelos para pronóstico robusto
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

# Verificar instalación de forecastHybrid
if (!require("forecastHybrid", quietly = TRUE)) {
  log_msg("Instalando paquete forecastHybrid...")
  install.packages("forecastHybrid")
}

library(forecastHybrid)
library(forecast)
library(ggplot2)
library(ggfortify)

cat("\n=== EJEMPLO 3: MODELO HÍBRIDO (ENSEMBLE) ===\n\n")

# -----------------------------------------------------------------------------
# 1. Cargar datos
# -----------------------------------------------------------------------------

log_msg("Cargando datos de caudal...")

caudal <- prepare_flow_data(
  FILE_SALIDA,
  col_flow = "salida",
  has_header = TRUE
)

# Verificar longitud suficiente
if (length(caudal) < 60) {
  stop("Se requieren al menos 60 observaciones para modelos híbridos")
}


# -----------------------------------------------------------------------------
# 2. Ajustar modelo híbrido con ponderación igual
# -----------------------------------------------------------------------------

log_msg("\nAjustando modelo híbrido con pesos iguales...")
log_msg("NOTA: Este proceso puede tardar varios minutos...")

modelo_h1 <- fit_hybrid_model(
  caudal,
  weights = "equal",
  models = "aens"  # ARIMA, ETS, NNETAR, STLM
)

# Resumen
print(summary(modelo_h1))


# -----------------------------------------------------------------------------
# 3. Ajustar modelo híbrido con ponderación por desempeño
# -----------------------------------------------------------------------------

log_msg("\nAjustando modelo híbrido con pesos por desempeño in-sample...")

modelo_h2 <- fit_hybrid_model(
  caudal,
  weights = "insample",
  models = "aens"
)

# Ver pesos asignados
cat("\nPesos de los modelos (optimizados):\n")
print(modelo_h2$weights)


# -----------------------------------------------------------------------------
# 4. Generar pronósticos
# -----------------------------------------------------------------------------

log_msg("\nGenerando pronósticos...")

# Modelo con pesos iguales
fc_h1 <- generate_forecast(modelo_h1, h = 12, level = c(80, 95))

# Modelo con pesos optimizados
fc_h2 <- generate_forecast(modelo_h2, h = 12, level = c(80, 95))


# -----------------------------------------------------------------------------
# 5. Comparar pronósticos
# -----------------------------------------------------------------------------

# Extraer pronósticos
df_h1 <- extract_forecast_df(fc_h1)
df_h2 <- extract_forecast_df(fc_h2)

# Crear tabla comparativa
comparacion <- data.frame(
  mes_num = df_h1$mes,
  mes_nombre = df_h1$mes_nombre,
  hibrido_igual = df_h1$pronostico,
  hibrido_optim = df_h2$pronostico,
  diferencia = df_h2$pronostico - df_h1$pronostico
)

print(comparacion)
export_table(comparacion, "ejemplo3_comparacion_hibridos.csv")


# -----------------------------------------------------------------------------
# 6. Visualizar resultados
# -----------------------------------------------------------------------------

log_msg("\nGenerando visualizaciones...")

# Pronóstico con pesos iguales
plot1 <- autoplot(fc_h1) +
  autolayer(window(caudal, start = end(caudal)[1] - 5), 
            series = "Histórico") +
  labs(
    title = "Modelo Híbrido - Pesos Iguales",
    subtitle = "Combinación: ARIMA + ETS + NNETAR + STLM",
    x = "Fecha",
    y = "Caudal [m³/s]"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave(file.path(DIR_PLOTS, "ejemplo3_hibrido_igual.png"), 
       plot1, width = 12, height = 6, dpi = 300)
print(plot1)


# Pronóstico con pesos optimizados
plot2 <- autoplot(fc_h2) +
  autolayer(window(caudal, start = end(caudal)[1] - 5), 
            series = "Histórico") +
  labs(
    title = "Modelo Híbrido - Pesos Optimizados",
    subtitle = "Ponderación basada en desempeño in-sample",
    x = "Fecha",
    y = "Caudal [m³/s]"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave(file.path(DIR_PLOTS, "ejemplo3_hibrido_optim.png"), 
       plot2, width = 12, height = 6, dpi = 300)
print(plot2)


# -----------------------------------------------------------------------------
# 7. Comparación visual de ambos modelos
# -----------------------------------------------------------------------------

library(tidyr)
library(dplyr)

df_comp_long <- pivot_longer(
  comparacion, 
  cols = c(hibrido_igual, hibrido_optim),
  names_to = "Modelo",
  values_to = "Caudal"
)

df_comp_long$mes_nombre <- factor(df_comp_long$mes_nombre, levels = month.abb)

plot3 <- ggplot(df_comp_long, aes(x = mes_nombre, y = Caudal, 
                                  color = Modelo, group = Modelo)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_color_manual(
    values = c("hibrido_igual" = "steelblue", "hibrido_optim" = "darkred"),
    labels = c("Pesos Iguales", "Pesos Optimizados")
  ) +
  labs(
    title = "Comparación de Modelos Híbridos",
    subtitle = "Pronóstico a 12 meses",
    x = "Mes",
    y = "Caudal Pronosticado [m³/s]",
    color = "Modelo"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "bottom",
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

ggsave(file.path(DIR_PLOTS, "ejemplo3_comparacion.png"), 
       plot3, width = 10, height = 6, dpi = 300)
print(plot3)


cat("\n=== EJEMPLO COMPLETADO ===\n")
cat("Archivos generados en:", DIR_OUTPUT, "\n")
cat("Gráficos generados en:", DIR_PLOTS, "\n\n")
cat("\nNOTA: Los modelos híbridos suelen tener mejor desempeño que modelos\n")
cat("individuales al combinar sus fortalezas. El modelo con pesos optimizados\n")
cat("asigna mayor peso a los modelos con mejor desempeño histórico.\n\n")
