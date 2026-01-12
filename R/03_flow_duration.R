# =============================================================================
# MÓDULO DE CURVAS DE DURACIÓN - SISTEMA DE PRONÓSTICO HIDROLÓGICO
# =============================================================================
# Autor: Pablo Rojas
# Descripción: Pronóstico basado en percentiles históricos mensuales
# =============================================================================

#' Calcular distribución empírica mensual
#' 
#' Crea función de distribución acumulada para cada mes
#' 
#' @param ts_data Serie temporal mensual
#' @return Lista con ECDF para cada mes (1-12)
#' @examples
#' monthly_ecdf <- calculate_monthly_ecdf(caudal_ts)
calculate_monthly_ecdf <- function(ts_data) {
  library(stats)
  
  validate_ts(ts_data)
  
  monthly_distributions <- list()
  
  for (m in 1:12) {
    # Extraer valores del mes m
    month_values <- subset(ts_data, 
                           month.abb[cycle(ts_data)] == month.abb[m])
    month_values <- month_values[!is.na(month_values)]
    
    if (length(month_values) < 3) {
      warning(sprintf("Mes %d tiene muy pocas observaciones (%d)", 
                      m, length(month_values)))
      monthly_distributions[[m]] <- NULL
    } else {
      # Crear función ECDF
      monthly_distributions[[m]] <- ecdf(month_values)
    }
  }
  
  return(monthly_distributions)
}


#' Determinar percentil de un caudal observado
#' 
#' Calcula en qué percentil se encuentra un caudal dado
#' 
#' @param ts_data Serie temporal histórica
#' @param mes Mes del caudal (1-12)
#' @param caudal_observado Valor de caudal observado
#' @return Percentil (0-1) donde se ubica el caudal
#' @examples
#' percentil <- get_flow_percentile(ts_data, mes = 3, caudal_observado = 3.13)
get_flow_percentile <- function(ts_data, mes, caudal_observado) {
  
  # Extraer valores históricos del mes
  month_values <- subset(ts_data, 
                         month.abb[cycle(ts_data)] == month.abb[mes])
  month_values <- month_values[!is.na(month_values)]
  
  if (length(month_values) < 3) {
    stop(sprintf("Insuficientes datos para mes %d", mes))
  }
  
  # Crear ECDF y evaluar
  dist_ecdf <- ecdf(month_values)
  percentil <- dist_ecdf(caudal_observado)
  
  if (exists("log_msg")) {
    log_msg(sprintf("Caudal %.2f m³/s en mes %s corresponde a percentil %.1f%%",
                    caudal_observado, month.abb[mes], percentil * 100))
  }
  
  return(percentil)
}


#' Pronosticar usando percentil de referencia
#' 
#' Genera pronóstico mensual basado en percentil histórico
#' 
#' @param ts_data Serie temporal histórica
#' @param mes_inicio Mes de inicio del pronóstico (1-12)
#' @param n_meses Número de meses a pronosticar
#' @param percentil Percentil de referencia (0-1)
#' @param ajuste Factor de ajuste opcional (default 1.0)
#' @return Data frame con pronóstico mensual
#' @examples
#' # Pronóstico seco (percentil 85%)
#' fc <- forecast_by_percentile(ts_data, mes_inicio = 8, n_meses = 12, percentil = 0.85)
forecast_by_percentile <- function(ts_data, 
                                   mes_inicio,
                                   n_meses = 12,
                                   percentil = 0.50,
                                   ajuste = 1.0) {
  
  validate_ts(ts_data)
  
  # Generar secuencia de meses
  meses_fc <- forecast_months(mes_inicio, n_meses)
  
  # Inicializar resultados
  pronostico <- data.frame(
    mes_num = meses_fc,
    mes_nombre = month.abb[meses_fc],
    percentil = percentil,
    caudal_p = numeric(n_meses)
  )
  
  # Calcular pronóstico para cada mes
  for (i in 1:n_meses) {
    mes <- meses_fc[i]
    
    # Extraer valores históricos del mes
    month_values <- subset(ts_data, 
                           month.abb[cycle(ts_data)] == month.abb[mes])
    month_values <- month_values[!is.na(month_values)]
    
    if (length(month_values) == 0) {
      warning(sprintf("No hay datos para mes %d", mes))
      pronostico$caudal_p[i] <- NA
    } else {
      # Calcular percentil y ajustar
      q_value <- quantile(month_values, percentil, na.rm = TRUE)
      pronostico$caudal_p[i] <- as.numeric(q_value) * ajuste
    }
  }
  
  return(pronostico)
}


#' Pronosticar múltiples escenarios
#' 
#' Genera pronósticos para varios percentiles (húmedo, medio, seco)
#' 
#' @param ts_data Serie temporal histórica
#' @param mes_inicio Mes de inicio
#' @param n_meses Número de meses a pronosticar
#' @param percentiles Vector de percentiles a calcular
#' @param nombres_escenarios Nombres descriptivos de los escenarios
#' @return Data frame con múltiples escenarios
#' @examples
#' escenarios <- forecast_scenarios(ts_data, mes_inicio = 8, n_meses = 12)
forecast_scenarios <- function(ts_data,
                               mes_inicio,
                               n_meses = 12,
                               percentiles = c(0.15, 0.30, 0.50, 0.70, 0.85),
                               nombres_escenarios = c("P15_Muy_Humedo", 
                                                      "P30_Humedo",
                                                      "P50_Medio", 
                                                      "P70_Seco",
                                                      "P85_Muy_Seco")) {
  
  validate_ts(ts_data)
  
  if (length(percentiles) != length(nombres_escenarios)) {
    stop("El número de percentiles y nombres debe coincidir")
  }
  
  # Generar secuencia de meses
  meses_fc <- forecast_months(mes_inicio, n_meses)
  
  # Inicializar data frame
  result <- data.frame(
    mes_num = meses_fc,
    mes_nombre = month.abb[meses_fc]
  )
  
  # Calcular cada escenario
  for (i in seq_along(percentiles)) {
    p <- percentiles[i]
    nombre <- nombres_escenarios[i]
    
    if (exists("log_msg")) {
      log_msg(sprintf("Calculando escenario: %s (P%.0f)", nombre, p * 100))
    }
    
    # Pronosticar para este percentil
    fc <- forecast_by_percentile(ts_data, mes_inicio, n_meses, p)
    
    # Agregar columna al resultado
    result[[nombre]] <- fc$caudal_p
  }
  
  return(result)
}


#' Pronosticar basado en condición actual
#' 
#' Ajusta pronóstico según percentil de caudal actual observado
#' 
#' @param ts_data Serie temporal histórica
#' @param mes_actual Mes del último caudal observado (1-12)
#' @param caudal_actual Caudal observado más reciente
#' @param n_meses Número de meses a pronosticar
#' @param factor_ajuste Factor de persistencia (default 0.8)
#' @return Data frame con pronóstico ajustado
#' @examples
#' # Si en marzo se observaron 3.13 m³/s, pronosticar siguientes meses
#' fc <- forecast_from_current(ts_data, mes_actual = 3, 
#'                              caudal_actual = 3.13, n_meses = 12)
forecast_from_current <- function(ts_data,
                                  mes_actual,
                                  caudal_actual,
                                  n_meses = 12,
                                  factor_ajuste = 0.8) {
  
  validate_ts(ts_data)
  
  # Determinar percentil del caudal actual
  percentil_actual <- get_flow_percentile(ts_data, mes_actual, caudal_actual)
  
  # Ajustar percentil (regresión a la media)
  percentil_fc <- percentil_actual * factor_ajuste
  
  if (exists("log_msg")) {
    log_msg(sprintf("Percentil actual: %.1f%%, Percentil ajustado: %.1f%%",
                    percentil_actual * 100, percentil_fc * 100))
  }
  
  # Generar pronóstico
  pronostico <- forecast_by_percentile(ts_data, 
                                       mes_inicio = mes_actual,
                                       n_meses = n_meses,
                                       percentil = percentil_fc)
  
  # Agregar información de contexto
  pronostico$percentil_actual <- percentil_actual
  pronostico$caudal_actual <- caudal_actual
  
  return(pronostico)
}


#' Crear tabla resumen de percentiles mensuales
#' 
#' Tabla de referencia con percentiles para todos los meses
#' 
#' @param ts_data Serie temporal
#' @param percentiles Vector de percentiles
#' @return Data frame con percentiles por mes
#' @examples
#' tabla_ref <- create_percentile_table(caudal_ts)
create_percentile_table <- function(ts_data, 
                                    percentiles = c(0.15, 0.30, 0.50, 
                                                    0.70, 0.85)) {
  
  validate_ts(ts_data)
  
  result <- data.frame(mes = 1:12, mes_nombre = month.abb)
  
  for (p in percentiles) {
    col_name <- sprintf("P%.0f", p * 100)
    result[[col_name]] <- numeric(12)
    
    for (m in 1:12) {
      month_values <- subset(ts_data, 
                             month.abb[cycle(ts_data)] == month.abb[m])
      month_values <- month_values[!is.na(month_values)]
      
      if (length(month_values) > 0) {
        result[[col_name]][m] <- quantile(month_values, p, na.rm = TRUE)
      } else {
        result[[col_name]][m] <- NA
      }
    }
  }
  
  # Agregar estadísticas adicionales
  result$media <- numeric(12)
  result$n_obs <- numeric(12)
  
  for (m in 1:12) {
    month_values <- subset(ts_data, 
                           month.abb[cycle(ts_data)] == month.abb[m])
    month_values <- month_values[!is.na(month_values)]
    
    result$media[m] <- mean(month_values, na.rm = TRUE)
    result$n_obs[m] <- length(month_values)
  }
  
  return(result)
}

# Mensaje de confirmación
if (exists("log_msg")) {
  log_msg("Módulo de curvas de duración disponible")
}
