# =============================================================================
# FUNCIONES UTILITARIAS - SISTEMA DE PRONÓSTICO HIDROLÓGICO
# =============================================================================
# Autor: Pablo Rojas
# Descripción: Funciones auxiliares y utilidades generales
# =============================================================================

#' Validar serie temporal
#' 
#' Verifica que una serie temporal tenga el formato correcto
#' 
#' @param ts_data Serie temporal a validar
#' @param min_length Longitud mínima requerida
#' @return TRUE si es válida, lanza error si no
#' @examples
#' validate_ts(my_ts, min_length = 12)
validate_ts <- function(ts_data, min_length = 12) {
  if (!is.ts(ts_data)) {
    stop("El objeto proporcionado no es una serie temporal (ts)")
  }
  
  if (length(ts_data) < min_length) {
    stop(sprintf("Serie temporal muy corta. Mínimo: %d, Actual: %d", 
                 min_length, length(ts_data)))
  }
  
  # Verificar NAs
  na_count <- sum(is.na(ts_data))
  if (na_count > 0) {
    warning(sprintf("Serie contiene %d valores NA (%.1f%%)", 
                    na_count, 100 * na_count / length(ts_data)))
  }
  
  return(TRUE)
}


#' Calcular estadísticas descriptivas mensuales
#' 
#' Calcula min, max, media, mediana y percentiles para cada mes
#' 
#' @param ts_data Serie temporal mensual
#' @param percentiles Vector de percentiles a calcular
#' @return Data frame con estadísticas por mes
#' @examples
#' stats <- calculate_monthly_stats(caudal_ts)
calculate_monthly_stats <- function(ts_data, percentiles = c(0.15, 0.5, 0.85)) {
  validate_ts(ts_data)
  
  library(data.table)
  
  # Extraer mes y valor
  meses <- cycle(ts_data)
  valores <- as.numeric(ts_data)
  
  # Crear data.table para procesamiento eficiente
  dt <- data.table(mes = meses, caudal = valores)
  dt <- dt[!is.na(caudal)]
  
  # Calcular estadísticas por mes
  stats <- dt[, .(
    n = .N,
    min = min(caudal),
    p15 = quantile(caudal, 0.15),
    p30 = quantile(caudal, 0.30),
    p50 = quantile(caudal, 0.50),
    media = mean(caudal),
    p70 = quantile(caudal, 0.70),
    p85 = quantile(caudal, 0.85),
    max = max(caudal),
    sd = sd(caudal),
    cv = sd(caudal) / mean(caudal)
  ), by = mes]
  
  # Ordenar por mes y agregar nombres
  setorder(stats, mes)
  stats[, mes_nombre := month.abb[mes]]
  
  return(as.data.frame(stats))
}


#' Ajustar mes para ciclo anual
#' 
#' Convierte mes > 12 a equivalente en ciclo 1-12
#' 
#' @param mes Número de mes (puede ser > 12)
#' @return Mes ajustado entre 1 y 12
#' @examples
#' adjust_month(14)  # Retorna 2 (febrero)
adjust_month <- function(mes) {
  return(((mes - 1) %% 12) + 1)
}


#' Crear secuencia de meses para pronóstico
#' 
#' Genera vector de meses consecutivos desde mes inicial
#' 
#' @param mes_inicio Mes de inicio (1-12)
#' @param n_meses Número de meses a pronosticar
#' @return Vector de meses ajustados
#' @examples
#' forecast_months(10, 6)  # Oct, Nov, Dic, Ene, Feb, Mar
forecast_months <- function(mes_inicio, n_meses) {
  meses <- mes_inicio + seq(1, n_meses)
  return(adjust_month(meses))
}


#' Formatear tabla de resultados
#' 
#' Formatea tabla de pronóstico para exportación
#' 
#' @param df Data frame con resultados
#' @param decimals Número de decimales
#' @return Data frame formateado
format_forecast_table <- function(df, decimals = 2) {
  # Redondear columnas numéricas
  num_cols <- sapply(df, is.numeric)
  df[num_cols] <- lapply(df[num_cols], round, decimals)
  
  return(df)
}


#' Exportar tabla a CSV
#' 
#' Guarda data frame en archivo CSV con formato apropiado
#' 
#' @param df Data frame a exportar
#' @param filename Nombre del archivo (sin ruta)
#' @param output_dir Directorio de salida
#' @examples
#' export_table(resultados, "pronostico_2024.csv")
export_table <- function(df, filename, output_dir = DIR_OUTPUT) {
  filepath <- file.path(output_dir, filename)
  
  write.csv(df, filepath, row.names = FALSE, fileEncoding = "UTF-8")
  
  if (exists("log_msg")) {
    log_msg(sprintf("Tabla exportada: %s", filepath))
  }
  
  return(filepath)
}


#' Calcular métricas de error de pronóstico
#' 
#' Calcula RMSE, MAE, MAPE para validación
#' 
#' @param actual Valores observados
#' @param predicted Valores pronosticados
#' @return Lista con métricas de error
#' @examples
#' metrics <- calculate_forecast_metrics(obs, pred)
calculate_forecast_metrics <- function(actual, predicted) {
  # Remover NAs
  valid_idx <- !is.na(actual) & !is.na(predicted)
  actual <- actual[valid_idx]
  predicted <- predicted[valid_idx]
  
  if (length(actual) == 0) {
    warning("No hay valores válidos para calcular métricas")
    return(NULL)
  }
  
  # Calcular errores
  errors <- actual - predicted
  abs_errors <- abs(errors)
  pct_errors <- abs_errors / abs(actual) * 100
  
  metrics <- list(
    n = length(actual),
    RMSE = sqrt(mean(errors^2)),
    MAE = mean(abs_errors),
    MAPE = mean(pct_errors[is.finite(pct_errors)]),
    R2 = cor(actual, predicted)^2,
    bias = mean(errors)
  )
  
  return(metrics)
}


#' Imprimir métricas formateadas
#' 
#' Muestra métricas de error en formato legible
#' 
#' @param metrics Lista de métricas (de calculate_forecast_metrics)
print_metrics <- function(metrics) {
  if (is.null(metrics)) {
    cat("No hay métricas disponibles\n")
    return(invisible())
  }
  
  cat("\n=== MÉTRICAS DE DESEMPEÑO ===\n")
  cat(sprintf("  N:          %d observaciones\n", metrics$n))
  cat(sprintf("  RMSE:       %.3f\n", metrics$RMSE))
  cat(sprintf("  MAE:        %.3f\n", metrics$MAE))
  cat(sprintf("  MAPE:       %.2f%%\n", metrics$MAPE))
  cat(sprintf("  R²:         %.3f\n", metrics$R2))
  cat(sprintf("  Sesgo:      %.3f\n", metrics$bias))
  cat("=============================\n\n")
}


#' Detectar outliers usando método IQR
#' 
#' Identifica valores atípicos en serie temporal
#' 
#' @param x Vector numérico
#' @param k Factor multiplicador de IQR (default 1.5)
#' @return Índices de outliers
detect_outliers <- function(x, k = 1.5) {
  q1 <- quantile(x, 0.25, na.rm = TRUE)
  q3 <- quantile(x, 0.75, na.rm = TRUE)
  iqr <- q3 - q1
  
  lower_bound <- q1 - k * iqr
  upper_bound <- q3 + k * iqr
  
  outliers <- which(x < lower_bound | x > upper_bound)
  
  return(outliers)
}


#' Convertir serie temporal a data frame para ggplot
#' 
#' Prepara serie temporal para visualización con ggplot2
#' 
#' @param ts_data Serie temporal
#' @param value_name Nombre de la columna de valores
#' @return Data frame con fecha y valores
ts_to_df <- function(ts_data, value_name = "caudal") {
  library(zoo)
  
  # Crear fechas
  fechas <- as.Date(as.yearmon(time(ts_data)))
  
  # Crear data frame
  df <- data.frame(
    fecha = fechas,
    valor = as.numeric(ts_data)
  )
  
  names(df)[2] <- value_name
  
  return(df)
}

# Mensaje de confirmación
if (exists("log_msg")) {
  log_msg("Módulo de utilidades cargado correctamente")
}
