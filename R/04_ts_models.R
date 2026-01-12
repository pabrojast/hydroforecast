# =============================================================================
# MÓDULO DE MODELOS DE SERIES TEMPORALES - PRONÓSTICO HIDROLÓGICO
# =============================================================================
# Autor: Pablo Rojas
# Descripción: Modelos ARIMA, ETS, híbridos para pronóstico de caudales
# =============================================================================

#' Ajustar modelo ARIMA automático
#' 
#' Selecciona y ajusta mejor modelo ARIMA para serie temporal
#' 
#' @param ts_data Serie temporal mensual
#' @param seasonal TRUE para incluir componente estacional
#' @param approximation FALSE para búsqueda exhaustiva
#' @return Objeto del modelo ajustado
#' @examples
#' modelo_arima <- fit_auto_arima(caudal_ts)
fit_auto_arima <- function(ts_data, 
                           seasonal = TRUE,
                           approximation = FALSE) {
  
  library(forecast)
  
  validate_ts(ts_data, min_length = 24)
  
  if (exists("log_msg")) {
    log_msg("Ajustando modelo ARIMA automático...")
  }
  
  # Ajustar modelo
  fit <- auto.arima(ts_data, 
                    seasonal = seasonal,
                    approximation = approximation,
                    stepwise = !approximation,
                    trace = FALSE)
  
  if (exists("log_msg")) {
    log_msg(sprintf("Modelo seleccionado: %s", 
                    paste(arimaorder(fit), collapse = "-")))
    log_msg(sprintf("AIC: %.2f, BIC: %.2f", AIC(fit), BIC(fit)))
  }
  
  return(fit)
}


#' Ajustar modelo ETS (suavizado exponencial)
#' 
#' Ajusta modelo de suavizado exponencial con tendencia y estacionalidad
#' 
#' @param ts_data Serie temporal mensual
#' @param model Especificación del modelo ("ZZZ" = automático)
#' @return Objeto del modelo ajustado
#' @examples
#' modelo_ets <- fit_ets_model(caudal_ts)
fit_ets_model <- function(ts_data, model = "ZZZ") {
  
  library(forecast)
  
  validate_ts(ts_data, min_length = 24)
  
  if (exists("log_msg")) {
    log_msg("Ajustando modelo ETS...")
  }
  
  # Ajustar modelo
  fit <- ets(ts_data, model = model)
  
  if (exists("log_msg")) {
    log_msg(sprintf("Modelo ETS: %s", fit$method))
    log_msg(sprintf("AIC: %.2f, BIC: %.2f", AIC(fit), BIC(fit)))
  }
  
  return(fit)
}


#' Ajustar modelo STL + ARIMA
#' 
#' Descomposición STL seguida de pronóstico con ARIMA
#' 
#' @param ts_data Serie temporal mensual
#' @param h Horizonte de pronóstico
#' @return Objeto de pronóstico
#' @examples
#' fc_stl <- fit_stl_forecast(caudal_ts, h = 12)
fit_stl_forecast <- function(ts_data, h = 12) {
  
  library(forecast)
  
  validate_ts(ts_data, min_length = 36)
  
  if (exists("log_msg")) {
    log_msg("Ajustando modelo STL + ARIMA...")
  }
  
  # Pronóstico con STL
  fit <- stlf(ts_data, h = h, method = "arima")
  
  return(fit)
}


#' Ajustar modelo híbrido (ensemble)
#' 
#' Combina múltiples modelos: ARIMA, ETS, NNETAR, STLM, TBATS
#' 
#' @param ts_data Serie temporal mensual
#' @param weights Método de ponderación: "equal", "insample", "cv"
#' @param models Modelos a incluir en el ensemble
#' @return Modelo híbrido ajustado
#' @examples
#' modelo_hybrid <- fit_hybrid_model(caudal_ts, weights = "insample")
fit_hybrid_model <- function(ts_data,
                             weights = "insample",
                             models = "aenst") {
  
  library(forecastHybrid)
  
  validate_ts(ts_data, min_length = 48)
  
  if (exists("log_msg")) {
    log_msg(sprintf("Ajustando modelo híbrido (weights: %s, models: %s)...",
                    weights, models))
  }
  
  # Ajustar modelo híbrido
  # a = auto.arima, e = ets, n = nnetar, s = stlm, t = tbats
  fit <- hybridModel(ts_data, 
                     models = models,
                     weights = weights,
                     verbose = FALSE)
  
  if (exists("log_msg")) {
    log_msg("Modelo híbrido ajustado exitosamente")
  }
  
  return(fit)
}


#' Generar pronóstico desde modelo ajustado
#' 
#' Crea pronóstico con intervalo de confianza
#' 
#' @param modelo Modelo ajustado (ARIMA, ETS, etc.)
#' @param h Horizonte de pronóstico en meses
#' @param level Nivel de confianza (%) para intervalos
#' @return Objeto forecast con predicciones e intervalos
#' @examples
#' pronostico <- generate_forecast(modelo_arima, h = 12, level = c(80, 95))
generate_forecast <- function(modelo, h = 12, level = c(80, 95)) {
  
  library(forecast)
  
  if (exists("log_msg")) {
    log_msg(sprintf("Generando pronóstico para %d meses...", h))
  }
  
  # Generar pronóstico
  fc <- forecast(modelo, h = h, level = level)
  
  return(fc)
}


#' Extraer pronóstico como data frame
#' 
#' Convierte objeto forecast a data frame con fechas
#' 
#' @param fc_object Objeto forecast
#' @param mes_inicio Mes de inicio del pronóstico (opcional)
#' @return Data frame con pronóstico y intervalos
#' @examples
#' df_fc <- extract_forecast_df(pronostico)
extract_forecast_df <- function(fc_object, mes_inicio = NULL) {
  
  library(zoo)
  
  # Extraer componentes del pronóstico
  fechas <- as.Date(as.yearmon(time(fc_object$mean)))
  
  # Construir data frame base
  df <- data.frame(
    fecha = fechas,
    mes = as.numeric(format(fechas, "%m")),
    año = as.numeric(format(fechas, "%Y")),
    mes_nombre = month.abb[as.numeric(format(fechas, "%m"))],
    pronostico = as.numeric(fc_object$mean)
  )
  
  # Agregar intervalos de confianza si existen
  if (!is.null(fc_object$lower) && !is.null(fc_object$upper)) {
    # Tomar primer nivel de confianza
    df$lower_80 <- as.numeric(fc_object$lower[, 1])
    df$upper_80 <- as.numeric(fc_object$upper[, 1])
    
    # Segundo nivel si existe
    if (ncol(fc_object$lower) > 1) {
      df$lower_95 <- as.numeric(fc_object$lower[, 2])
      df$upper_95 <- as.numeric(fc_object$upper[, 2])
    }
  }
  
  return(df)
}


#' Comparar múltiples modelos
#' 
#' Ajusta varios modelos y compara su desempeño
#' 
#' @param ts_data Serie temporal
#' @param test_size Número de observaciones para validación
#' @return Data frame con métricas de comparación
#' @examples
#' comparacion <- compare_models(caudal_ts, test_size = 12)
compare_models <- function(ts_data, test_size = 12) {
  
  library(forecast)
  
  validate_ts(ts_data, min_length = 48)
  
  if (exists("log_msg")) {
    log_msg(sprintf("Comparando modelos (validación: %d meses)...", test_size))
  }
  
  # Dividir en entrenamiento y prueba
  n_total <- length(ts_data)
  n_train <- n_total - test_size
  
  train_data <- window(ts_data, end = time(ts_data)[n_train])
  test_data <- window(ts_data, start = time(ts_data)[n_train + 1])
  
  # Modelos a comparar
  models_list <- list(
    "ARIMA" = NULL,
    "ETS" = NULL,
    "ARIMA_Seasonal" = NULL,
    "STL" = NULL
  )
  
  # Ajustar modelos
  tryCatch({
    models_list$ARIMA <- auto.arima(train_data, seasonal = FALSE)
  }, error = function(e) {
    warning("Error al ajustar ARIMA no estacional")
  })
  
  tryCatch({
    models_list$ARIMA_Seasonal <- auto.arima(train_data, seasonal = TRUE)
  }, error = function(e) {
    warning("Error al ajustar ARIMA estacional")
  })
  
  tryCatch({
    models_list$ETS <- ets(train_data)
  }, error = function(e) {
    warning("Error al ajustar ETS")
  })
  
  tryCatch({
    models_list$STL <- stlf(train_data, h = test_size)
  }, error = function(e) {
    warning("Error al ajustar STL")
  })
  
  # Evaluar modelos
  results <- data.frame(
    Modelo = character(),
    RMSE = numeric(),
    MAE = numeric(),
    MAPE = numeric(),
    AIC = numeric(),
    stringsAsFactors = FALSE
  )
  
  for (model_name in names(models_list)) {
    model <- models_list[[model_name]]
    
    if (!is.null(model)) {
      # Generar pronóstico
      if (model_name == "STL") {
        fc <- model  # Ya es un objeto forecast
      } else {
        fc <- forecast(model, h = test_size)
      }
      
      # Calcular métricas
      metrics <- calculate_forecast_metrics(as.numeric(test_data), 
                                            as.numeric(fc$mean))
      
      # Agregar resultado
      results <- rbind(results, data.frame(
        Modelo = model_name,
        RMSE = metrics$RMSE,
        MAE = metrics$MAE,
        MAPE = metrics$MAPE,
        AIC = if(model_name != "STL") AIC(model) else NA,
        stringsAsFactors = FALSE
      ))
    }
  }
  
  # Ordenar por RMSE
  results <- results[order(results$RMSE), ]
  
  if (exists("log_msg")) {
    log_msg("Comparación completada")
    log_msg(sprintf("Mejor modelo: %s (RMSE = %.3f)", 
                    results$Modelo[1], results$RMSE[1]))
  }
  
  return(results)
}


#' Validación cruzada de series temporales
#' 
#' Evalúa estabilidad del modelo usando ventanas deslizantes
#' 
#' @param ts_data Serie temporal
#' @param h Horizonte de pronóstico
#' @param initial Tamaño inicial de ventana
#' @param window Tamaño de ventana (NULL = expanding)
#' @return Lista con resultados de CV
time_series_cv <- function(ts_data, h = 6, initial = 48, window = NULL) {
  
  library(forecast)
  
  if (exists("log_msg")) {
    log_msg("Realizando validación cruzada de series temporales...")
  }
  
  # Usar tsCV de forecast
  arima_cv <- tsCV(ts_data, forecastfunction = function(x, h) {
    forecast(auto.arima(x), h = h)
  }, h = h, initial = initial, window = window)
  
  # Calcular métricas
  rmse_cv <- sqrt(colMeans(arima_cv^2, na.rm = TRUE))
  mae_cv <- colMeans(abs(arima_cv), na.rm = TRUE)
  
  if (exists("log_msg")) {
    log_msg(sprintf("RMSE promedio (h=1): %.3f", rmse_cv[1]))
  }
  
  return(list(
    errors = arima_cv,
    RMSE = rmse_cv,
    MAE = mae_cv
  ))
}

# Mensaje de confirmación
if (exists("log_msg")) {
  log_msg("Módulo de modelos de series temporales disponible")
}
