# =============================================================================
# CONFIGURACIÓN GLOBAL - SISTEMA DE PRONÓSTICO HIDROLÓGICO
# =============================================================================
# Autor: Pablo Rojas
# Descripción: Parámetros centralizados para análisis y pronóstico de caudales
# =============================================================================

# Rutas de directorios
# -----------------------------------------------------------------------------
DIR_BASE <- getwd()
DIR_DATA <- file.path(DIR_BASE, "data")
DIR_OUTPUT <- file.path(DIR_BASE, "output")
DIR_PLOTS <- file.path(DIR_BASE, "plots")
DIR_R <- file.path(DIR_BASE, "R")

# Crear directorios si no existen
for (dir in c(DIR_DATA, DIR_OUTPUT, DIR_PLOTS)) {
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }
}

# Parámetros de datos
# -----------------------------------------------------------------------------
# Series temporales
TS_FREQ <- 12  # Frecuencia mensual
START_YEAR <- 1997
START_MONTH <- 9

# Archivos de entrada (relativo a DIR_DATA o directorio padre)
FILE_ENTRADA <- "QHalgodones.csv"
FILE_SALIDA <- "salida_mensual_es.csv"
FILE_SALIDA_SIN_VERT <- "salida_mensual_esj_sin_vertedero.csv"

# Parámetros de pronóstico
# -----------------------------------------------------------------------------
# Curvas de duración
PERCENTILES <- c(0.15, 0.30, 0.50, 0.70, 0.85)
NOMBRES_PERCENTILES <- c("P15_Muy_Humedo", "P30_Humedo", "P50_Medio", 
                         "P70_Seco", "P85_Muy_Seco")

# Horizonte de pronóstico
MESES_PRONOSTICO <- 12

# Mes inicial para pronóstico (1-12)
MES_INICIAL <- 8  # Agosto por defecto

# Factor de ajuste para pronóstico basado en percentil actual
FACTOR_AJUSTE <- 0.8

# Parámetros de infraestructura
# -----------------------------------------------------------------------------
ACC_3ER_TRAMO <- 7200  # Acumulación tercer tramo [unidades específicas]

# Parámetros de visualización
# -----------------------------------------------------------------------------
# Colores para escenarios
COLORS_SCENARIOS <- c(
  "P15" = "#2166AC",   # Azul oscuro - Muy húmedo
  "P30" = "#67A9CF",   # Azul claro - Húmedo
  "P50" = "#FEE090",   # Amarillo - Medio
  "P70" = "#F46D43",   # Naranja - Seco
  "P85" = "#A50026"    # Rojo oscuro - Muy seco
)

# Tema de gráficos
PLOT_THEME <- "minimal"  # Options: minimal, bw, classic, light
PLOT_DPI <- 300
PLOT_WIDTH <- 12
PLOT_HEIGHT <- 8

# Idioma para etiquetas
LANG <- "es"  # Options: es, en

# Etiquetas en español
LABELS_ES <- list(
  caudal = "Caudal [m³/s]",
  mes = "Mes",
  año = "Año",
  fecha = "Fecha",
  percentil = "Percentil",
  pronostico = "Pronóstico",
  historico = "Histórico",
  observado = "Observado",
  meses = c("Ene", "Feb", "Mar", "Abr", "May", "Jun",
            "Jul", "Ago", "Sep", "Oct", "Nov", "Dic")
)

# Mensajes de registro
# -----------------------------------------------------------------------------
VERBOSE <- TRUE  # Mostrar mensajes detallados

# Función auxiliar para logging
log_msg <- function(msg, type = "INFO") {
  if (VERBOSE) {
    timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    cat(sprintf("[%s] %s: %s\n", timestamp, type, msg))
  }
}

# Opciones de R
# -----------------------------------------------------------------------------
options(
  stringsAsFactors = FALSE,
  scipen = 999,  # Evitar notación científica
  digits = 3
)

# Mensaje de confirmación
log_msg("Configuración cargada exitosamente")
