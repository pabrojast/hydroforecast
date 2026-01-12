# =============================================================================
# MÓDULO DE CARGA DE DATOS - SISTEMA DE PRONÓSTICO HIDROLÓGICO
# =============================================================================
# Autor: Pablo Rojas
# Descripción: Funciones para cargar, validar y preparar datos hidrológicos
# =============================================================================

#' Cargar datos de caudal desde CSV
#' 
#' Lee archivo CSV con datos de caudal y crea serie temporal
#' 
#' @param filename Nombre del archivo CSV
#' @param data_dir Directorio de datos
#' @param col_year Nombre o índice de columna con año
#' @param col_month Nombre o índice de columna con mes
#' @param col_flow Nombre o índice de columna con caudal
#' @param start_year Año de inicio de la serie
#' @param start_month Mes de inicio de la serie
#' @param has_header TRUE si el archivo tiene encabezados
#' @return Serie temporal (ts object)
#' @examples
#' caudal <- load_flow_data("salida_mensual_es.csv", col_flow = "salida")
load_flow_data <- function(filename, 
                           data_dir = NULL,
                           col_year = 1,
                           col_month = 2, 
                           col_flow = 3,
                           start_year = NULL,
                           start_month = NULL,
                           has_header = TRUE) {
  
  # Determinar ruta completa
  if (is.null(data_dir)) {
    # Buscar en directorio actual y en directorio padre
    if (file.exists(filename)) {
      filepath <- filename
    } else if (file.exists(file.path("..", filename))) {
      filepath <- file.path("..", filename)
    } else if (exists("DIR_DATA") && file.exists(file.path(DIR_DATA, filename))) {
      filepath <- file.path(DIR_DATA, filename)
    } else {
      stop(sprintf("No se encontró el archivo: %s", filename))
    }
  } else {
    filepath <- file.path(data_dir, filename)
  }
  
  if (!file.exists(filepath)) {
    stop(sprintf("Archivo no encontrado: %s", filepath))
  }
  
  # Leer datos
  if (exists("log_msg")) {
    log_msg(sprintf("Cargando datos desde: %s", filepath))
  }
  
  data <- read.csv(filepath, 
                   header = has_header, 
                   sep = ",",
                   dec = ".",
                   stringsAsFactors = FALSE,
                   na.strings = c("", "NA", "NaN", "-"))
  
  # Detectar si tiene columna de fechas
  if (has_header && ncol(data) == 2 && any(grepl("salida|caudal|flow", tolower(names(data))))) {
    # Formato con fecha y caudal
    if (exists("log_msg")) {
      log_msg("Formato detectado: fecha + caudal")
    }
    
    # Parsear fechas
    fechas <- as.Date(data[, 1])
    flows <- as.numeric(data[, 2])
    
    # Extraer año y mes
    years <- as.numeric(format(fechas, "%Y"))
    months <- as.numeric(format(fechas, "%m"))
    
    # Determinar inicio
    if (is.null(start_year)) start_year <- min(years, na.rm = TRUE)
    if (is.null(start_month)) start_month <- months[which(years == start_year)[1]]
    
  } else {
    # Formato tradicional con columnas separadas
    
    # Convertir nombres de columna a índices si es necesario
    if (is.character(col_year)) col_year <- which(names(data) == col_year)
    if (is.character(col_month)) col_month <- which(names(data) == col_month)
    if (is.character(col_flow)) col_flow_idx <- which(names(data) == col_flow) else col_flow_idx <- col_flow
    
    # Validar estructura
    if (ncol(data) < max(col_year, col_month, col_flow_idx)) {
      stop(sprintf("El archivo tiene %d columnas, pero se requieren al menos %d", 
                   ncol(data), max(col_year, col_month, col_flow_idx)))
    }
    
    # Extraer columnas
    years <- data[, col_year]
    months <- data[, col_month]
    flows <- data[, col_flow_idx]
    
    # Determinar inicio de serie si no se especifica
    if (is.null(start_year)) {
      start_year <- min(years, na.rm = TRUE)
    }
    if (is.null(start_month)) {
      start_month <- months[which(years == start_year)[1]]
    }
  }
  
  # Crear serie temporal
  ts_data <- ts(flows, 
                frequency = 12, 
                start = c(start_year, start_month))
  
  # Estadísticas básicas
  n_total <- length(ts_data)
  n_na <- sum(is.na(ts_data))
  pct_na <- 100 * n_na / n_total
  
  if (exists("log_msg")) {
    log_msg(sprintf("Serie cargada: %d observaciones (%d años)", 
                    n_total, floor(n_total / 12)))
    if (n_na > 0) {
      log_msg(sprintf("Valores NA: %d (%.1f%%)", n_na, pct_na), "WARNING")
    }
    log_msg(sprintf("Rango: %.2f - %.2f m³/s", 
                    min(ts_data, na.rm = TRUE), 
                    max(ts_data, na.rm = TRUE)))
  }
  
  return(ts_data)
}


#' Rellenar valores faltantes en serie temporal
#' 
#' Imputa NAs usando diferentes métodos
#' 
#' @param ts_data Serie temporal con NAs
#' @param method Método de imputación: "locf", "mean", "interpolate"
#' @return Serie temporal sin NAs
#' @examples
#' ts_filled <- fill_missing_values(ts_data, method = "interpolate")
fill_missing_values <- function(ts_data, method = "locf") {
  library(zoo)
  
  n_na <- sum(is.na(ts_data))
  
  if (n_na == 0) {
    if (exists("log_msg")) {
      log_msg("No hay valores faltantes que rellenar")
    }
    return(ts_data)
  }
  
  if (exists("log_msg")) {
    log_msg(sprintf("Rellenando %d NAs usando método: %s", n_na, method))
  }
  
  ts_filled <- switch(method,
    "locf" = {
      # Last observation carried forward
      na.locf(ts_data, na.rm = FALSE)
    },
    "mean" = {
      # Reemplazar con media mensual
      monthly_means <- tapply(ts_data, cycle(ts_data), mean, na.rm = TRUE)
      ts_temp <- ts_data
      for (i in which(is.na(ts_data))) {
        month <- cycle(ts_data)[i]
        ts_temp[i] <- monthly_means[month]
      }
      ts_temp
    },
    "interpolate" = {
      # Interpolación lineal
      na.approx(ts_data, na.rm = FALSE)
    },
    stop(sprintf("Método no reconocido: %s", method))
  )
  
  return(ts_filled)
}


#' Validar y limpiar datos de caudal
#' 
#' Detecta y opcionalmente corrige problemas en datos
#' 
#' @param ts_data Serie temporal
#' @param remove_outliers Eliminar outliers extremos
#' @param outlier_k Factor para detección de outliers
#' @return Lista con serie limpia y reporte de problemas
validate_and_clean <- function(ts_data, 
                               remove_outliers = FALSE,
                               outlier_k = 3) {
  
  issues <- list()
  ts_clean <- ts_data
  
  # Verificar valores negativos
  neg_idx <- which(ts_data < 0)
  if (length(neg_idx) > 0) {
    issues$negative <- neg_idx
    if (exists("log_msg")) {
      log_msg(sprintf("Encontrados %d valores negativos", length(neg_idx)), 
              "WARNING")
    }
    ts_clean[neg_idx] <- NA
  }
  
  # Detectar outliers
  if (remove_outliers) {
    outlier_idx <- detect_outliers(ts_data, k = outlier_k)
    if (length(outlier_idx) > 0) {
      issues$outliers <- outlier_idx
      if (exists("log_msg")) {
        log_msg(sprintf("Encontrados %d outliers (k=%.1f)", 
                        length(outlier_idx), outlier_k), "WARNING")
      }
      ts_clean[outlier_idx] <- NA
    }
  }
  
  # Verificar secuencias anómalas (valores constantes largos)
  rle_result <- rle(as.numeric(ts_data))
  long_sequences <- which(rle_result$lengths > 6)  # Más de 6 meses igual
  if (length(long_sequences) > 0) {
    issues$constant_sequences <- long_sequences
    if (exists("log_msg")) {
      log_msg(sprintf("Detectadas %d secuencias anómalamente constantes", 
                      length(long_sequences)), "WARNING")
    }
  }
  
  return(list(
    ts_clean = ts_clean,
    issues = issues,
    n_issues = length(neg_idx) + length(if(remove_outliers) outlier_idx else 0)
  ))
}


#' Preparar datos completos para análisis
#' 
#' Pipeline completo: cargar, validar, limpiar, rellenar
#' 
#' @param filename Nombre del archivo
#' @param ... Parámetros adicionales para load_flow_data
#' @param fill_method Método para rellenar NAs
#' @param clean TRUE para limpiar datos automáticamente
#' @return Serie temporal lista para análisis
#' @examples
#' caudal <- prepare_flow_data("salida_mensual_es.csv")
prepare_flow_data <- function(filename, 
                              ...,
                              fill_method = "locf",
                              clean = TRUE) {
  
  # Cargar datos
  ts_data <- load_flow_data(filename, ...)
  
  # Validar y limpiar
  if (clean) {
    result <- validate_and_clean(ts_data, remove_outliers = FALSE)
    ts_data <- result$ts_clean
    
    if (result$n_issues > 0 && exists("log_msg")) {
      log_msg(sprintf("Se corrigieron %d problemas en los datos", 
                      result$n_issues))
    }
  }
  
  # Rellenar NAs si es necesario
  if (sum(is.na(ts_data)) > 0) {
    ts_data <- fill_missing_values(ts_data, method = fill_method)
  }
  
  if (exists("log_msg")) {
    log_msg("Datos preparados exitosamente")
  }
  
  return(ts_data)
}

# Mensaje de confirmación
if (exists("log_msg")) {
  log_msg("Módulo de carga de datos disponible")
}
