# =============================================================================
# MÓDULO DE VISUALIZACIÓN - SISTEMA DE PRONÓSTICO HIDROLÓGICO
# =============================================================================
# Autor: Pablo Rojas
# Descripción: Gráficos profesionales para análisis y pronóstico hidrológico
# =============================================================================

#' Graficar serie temporal con estadísticas mensuales
#' 
#' Visualiza serie completa con bandas de percentiles mensuales
#' 
#' @param ts_data Serie temporal
#' @param title Título del gráfico
#' @param save_plot TRUE para guardar en archivo
#' @param filename Nombre del archivo de salida
#' @return Objeto ggplot
#' @examples
#' p <- plot_flow_series(caudal_ts, title = "Caudales Históricos")
plot_flow_series <- function(ts_data, 
                             title = "Serie Temporal de Caudales",
                             save_plot = FALSE,
                             filename = "serie_temporal.png") {
  
  library(ggplot2)
  library(scales)
  
  validate_ts(ts_data)
  
  # Convertir a data frame
  df <- ts_to_df(ts_data, value_name = "caudal")
  
  # Calcular estadísticas mensuales
  stats <- calculate_monthly_stats(ts_data)
  
  # Crear data frame de bandas mensuales
  df$mes <- as.numeric(format(df$fecha, "%m"))
  df <- merge(df, stats[, c("mes", "p15", "p85", "media")], by = "mes")
  
  # Crear gráfico
  p <- ggplot(df, aes(x = fecha)) +
    # Banda de percentiles
    geom_ribbon(aes(ymin = p15, ymax = p85), alpha = 0.2, fill = "steelblue") +
    # Media mensual
    geom_line(aes(y = media), color = "gray60", linetype = "dashed", size = 0.5) +
    # Serie observada
    geom_line(aes(y = caudal), color = "steelblue", linewidth = 0.8) +
    # Etiquetas y tema
    labs(
      title = title,
      subtitle = sprintf("Período: %s - %s | Banda: P15-P85",
                        format(min(df$fecha), "%Y"),
                        format(max(df$fecha), "%Y")),
      x = "Fecha",
      y = "Caudal [m³/s]"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    ) +
    scale_x_date(date_breaks = "2 years", date_labels = "%Y")
  
  # Guardar si se solicita
  if (save_plot && exists("DIR_PLOTS")) {
    filepath <- file.path(DIR_PLOTS, filename)
    ggsave(filepath, p, width = 12, height = 6, dpi = 300)
    if (exists("log_msg")) {
      log_msg(sprintf("Gráfico guardado: %s", filepath))
    }
  }
  
  return(p)
}


#' Graficar climatología mensual (ciclo anual)
#' 
#' Muestra patrones mensuales con percentiles e incertidumbre
#' 
#' @param ts_data Serie temporal
#' @param title Título del gráfico
#' @param save_plot TRUE para guardar
#' @param filename Nombre del archivo
#' @return Objeto ggplot
plot_monthly_climatology <- function(ts_data,
                                     title = "Climatología Mensual",
                                     save_plot = FALSE,
                                     filename = "climatologia_mensual.png") {
  
  library(ggplot2)
  library(scales)
  
  validate_ts(ts_data)
  
  # Calcular estadísticas mensuales
  stats <- calculate_monthly_stats(ts_data)
  
  # Preparar datos
  stats$mes_nombre <- factor(stats$mes_nombre, levels = month.abb)
  
  # Crear gráfico
  p <- ggplot(stats, aes(x = mes_nombre, group = 1)) +
    # Banda min-max
    geom_ribbon(aes(ymin = min, ymax = max), alpha = 0.15, fill = "gray70") +
    # Banda P15-P85
    geom_ribbon(aes(ymin = p15, ymax = p85), alpha = 0.3, fill = "steelblue") +
    # Banda P30-P70
    geom_ribbon(aes(ymin = p30, ymax = p70), alpha = 0.4, fill = "steelblue") +
    # Mediana
    geom_line(aes(y = p50), color = "darkblue", linewidth = 1.2) +
    geom_point(aes(y = p50), color = "darkblue", size = 3) +
    # Media
    geom_line(aes(y = media), color = "darkred", linetype = "dashed", linewidth = 0.8) +
    # Etiquetas
    labs(
      title = title,
      subtitle = "Bandas: Mín-Máx (gris), P15-P85 (azul claro), P30-P70 (azul oscuro)",
      x = "Mes",
      y = "Caudal [m³/s]",
      caption = "Línea sólida: Mediana | Línea punteada: Media"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      panel.grid.major.x = element_blank(),
      panel.grid.minor = element_blank(),
      axis.text.x = element_text(angle = 0, hjust = 0.5)
    ) +
    scale_y_continuous(labels = comma)
  
  # Guardar
  if (save_plot && exists("DIR_PLOTS")) {
    filepath <- file.path(DIR_PLOTS, filename)
    ggsave(filepath, p, width = 10, height = 6, dpi = 300)
    if (exists("log_msg")) {
      log_msg(sprintf("Gráfico guardado: %s", filepath))
    }
  }
  
  return(p)
}


#' Graficar pronóstico de escenarios múltiples
#' 
#' Visualiza pronóstico con diferentes percentiles
#' 
#' @param forecast_df Data frame con escenarios (de forecast_scenarios)
#' @param title Título del gráfico
#' @param save_plot TRUE para guardar
#' @param filename Nombre del archivo
#' @return Objeto ggplot
plot_forecast_scenarios <- function(forecast_df,
                                    title = "Pronóstico de Caudales - Escenarios",
                                    save_plot = FALSE,
                                    filename = "pronostico_escenarios.png") {
  
  library(ggplot2)
  
  # Transformar a formato largo manualmente (evitar dependencia de tidyr)
  escenario_cols <- setdiff(names(forecast_df), c("mes_num", "mes_nombre"))
  
  df_long <- data.frame()
  for (col in escenario_cols) {
    temp_df <- data.frame(
      mes_nombre = forecast_df$mes_nombre,
      Escenario = col,
      Caudal = forecast_df[[col]],
      stringsAsFactors = FALSE
    )
    df_long <- rbind(df_long, temp_df)
  }
  
  # Ordenar meses
  df_long$mes_nombre <- factor(df_long$mes_nombre, levels = month.abb)
  
  # Mapear colores
  color_map <- c(
    "P15_Muy_Humedo" = "#2166AC",
    "P30_Humedo" = "#67A9CF",
    "P50_Medio" = "#FEE090",
    "P70_Seco" = "#F46D43",
    "P85_Muy_Seco" = "#A50026"
  )
  
  # Crear gráfico
  p <- ggplot(df_long, aes(x = mes_nombre, y = Caudal, 
                          color = Escenario, group = Escenario)) +
    geom_line(linewidth = 1.2) +
    geom_point(size = 3) +
    scale_color_manual(
      values = color_map,
      labels = c("P15 - Muy Húmedo", "P30 - Húmedo", "P50 - Medio",
                 "P70 - Seco", "P85 - Muy Seco")
    ) +
    labs(
      title = title,
      subtitle = "Pronóstico basado en percentiles históricos mensuales",
      x = "Mes",
      y = "Caudal Pronosticado [m³/s]",
      color = "Escenario"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      legend.position = "bottom",
      panel.grid.minor = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1)
    )
  
  # Guardar
  if (save_plot && exists("DIR_PLOTS")) {
    filepath <- file.path(DIR_PLOTS, filename)
    ggsave(filepath, p, width = 12, height = 7, dpi = 300)
    if (exists("log_msg")) {
      log_msg(sprintf("Gráfico guardado: %s", filepath))
    }
  }
  
  return(p)
}


#' Graficar pronóstico de modelo de series temporales
#' 
#' Visualiza pronóstico con intervalos de confianza
#' 
#' @param ts_data Serie histórica
#' @param fc_object Objeto forecast
#' @param title Título del gráfico
#' @param n_years Años históricos a mostrar
#' @param save_plot TRUE para guardar
#' @param filename Nombre del archivo
#' @return Objeto ggplot
plot_ts_forecast <- function(ts_data,
                             fc_object,
                             title = "Pronóstico - Modelo de Series Temporales",
                             n_years = 5,
                             save_plot = FALSE,
                             filename = "pronostico_ts_model.png") {
  
  library(ggplot2)
  library(ggfortify)
  
  # Usar autoplot de ggfortify para objetos forecast
  p <- autoplot(fc_object) +
    autolayer(window(ts_data, start = end(ts_data)[1] - n_years), 
              series = "Histórico") +
    labs(
      title = title,
      x = "Fecha",
      y = "Caudal [m³/s]",
      color = "",
      fill = ""
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      legend.position = "bottom",
      panel.grid.minor = element_blank()
    ) +
    scale_color_manual(values = c("Histórico" = "steelblue", 
                                  "Pronóstico" = "darkred")) +
    scale_fill_manual(values = c("darkred"))
  
  # Guardar
  if (save_plot && exists("DIR_PLOTS")) {
    filepath <- file.path(DIR_PLOTS, filename)
    ggsave(filepath, p, width = 12, height = 6, dpi = 300)
    if (exists("log_msg")) {
      log_msg(sprintf("Gráfico guardado: %s", filepath))
    }
  }
  
  return(p)
}


#' Comparar observado vs pronosticado
#' 
#' Gráfico de dispersión y series temporales para validación
#' 
#' @param actual Vector de valores observados
#' @param predicted Vector de valores pronosticados
#' @param dates Vector de fechas (opcional)
#' @param title Título del gráfico
#' @return Objeto ggplot combinado
plot_forecast_validation <- function(actual, 
                                     predicted,
                                     dates = NULL,
                                     title = "Validación del Pronóstico") {
  
  library(ggplot2)
  library(patchwork)
  
  # Crear data frame
  df <- data.frame(
    observado = actual,
    pronosticado = predicted
  )
  
  if (!is.null(dates)) {
    df$fecha <- dates
  }
  
  # Calcular métricas
  metrics <- calculate_forecast_metrics(actual, predicted)
  
  # Gráfico 1: Dispersión
  p1 <- ggplot(df, aes(x = observado, y = pronosticado)) +
    geom_point(alpha = 0.6, size = 3, color = "steelblue") +
    geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red") +
    annotate("text", x = min(actual, na.rm = TRUE), 
             y = max(predicted, na.rm = TRUE),
             label = sprintf("R² = %.3f\nRMSE = %.2f\nMAE = %.2f",
                           metrics$R2, metrics$RMSE, metrics$MAE),
             hjust = 0, vjust = 1, size = 3.5) +
    labs(
      title = "Observado vs Pronosticado",
      x = "Caudal Observado [m³/s]",
      y = "Caudal Pronosticado [m³/s]"
    ) +
    theme_minimal() +
    theme(plot.title = element_text(face = "bold"))
  
  # Gráfico 2: Series temporales (si hay fechas)
  if (!is.null(dates)) {
    df_long <- pivot_longer(df, cols = c(observado, pronosticado),
                           names_to = "tipo", values_to = "caudal")
    
    p2 <- ggplot(df_long, aes(x = fecha, y = caudal, color = tipo)) +
      geom_line(linewidth = 1) +
      geom_point(size = 2) +
      scale_color_manual(values = c("observado" = "black", 
                                   "pronosticado" = "steelblue"),
                        labels = c("Observado", "Pronosticado")) +
      labs(
        title = "Serie Temporal",
        x = "Fecha",
        y = "Caudal [m³/s]",
        color = ""
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(face = "bold"),
        legend.position = "bottom"
      )
    
    # Combinar gráficos
    p <- p1 + p2 + plot_annotation(title = title,
                                   theme = theme(plot.title = element_text(size = 16, face = "bold")))
  } else {
    p <- p1 + labs(title = title)
  }
  
  return(p)
}

# Mensaje de confirmación
if (exists("log_msg")) {
  log_msg("Módulo de visualización disponible")
}
