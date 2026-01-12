#!/bin/bash
# =============================================================================
# Script de Publicación - HydroForecast
# =============================================================================
# Este script te guía para publicar el repositorio en GitHub
# =============================================================================

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                  HYDROFORECAST - PUBLICACIÓN EN GITHUB                       ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "README.md" ] || [ ! -d ".git" ]; then
    echo "❌ Error: Este script debe ejecutarse desde el directorio hydroforecast/"
    exit 1
fi

echo "✅ Repositorio Git inicializado correctamente"
echo "   Commit: $(git log --oneline -1)"
echo "   Branch: $(git branch --show-current)"
echo "   Tag: $(git tag -l)"
echo ""

echo "═══════════════════════════════════════════════════════════════════════════════"
echo "PASOS PARA PUBLICAR EN GITHUB"
echo "═══════════════════════════════════════════════════════════════════════════════"
echo ""

echo "1️⃣  Crear repositorio en GitHub:"
echo "   - Ve a: https://github.com/new"
echo "   - Nombre: hydroforecast"
echo "   - Descripción: Sistema profesional de pronóstico hidrológico en R"
echo "   - Tipo: Público"
echo "   - NO inicialices con README, .gitignore o LICENSE (ya los tenemos)"
echo ""

echo "2️⃣  Conectar repositorio local con GitHub:"
echo ""
echo "   Después de crear el repo en GitHub, ejecuta:"
echo ""
echo "   git remote add origin https://github.com/TU-USUARIO/hydroforecast.git"
echo "   git push -u origin main"
echo "   git push origin v2.0.0"
echo ""

echo "3️⃣  Opcional - Usar SSH en lugar de HTTPS:"
echo ""
echo "   git remote set-url origin git@github.com:TU-USUARIO/hydroforecast.git"
echo ""

echo "4️⃣  Crear Release en GitHub:"
echo "   - Ve a: Releases > Create a new release"
echo "   - Tag: v2.0.0"
echo "   - Title: HydroForecast v2.0.0 - Initial Release"
echo "   - Descripción: Ver abajo"
echo ""

echo "═══════════════════════════════════════════════════════════════════════════════"
echo "DESCRIPCIÓN SUGERIDA PARA EL RELEASE"
echo "═══════════════════════════════════════════════════════════════════════════════"
echo ""

cat << 'RELEASE_NOTES'
# 🌊 HydroForecast v2.0.0 - Initial Release

Sistema profesional de pronóstico hidrológico desarrollado en R.

## ✨ Características Principales

- **6 metodologías de pronóstico**: Curvas de duración, ARIMA, ETS, STL, modelos híbridos, validación cruzada
- **Visualizaciones profesionales**: Gráficos publication-ready en PNG 300 DPI
- **Código modular**: 2,309 líneas en 6 módulos bien documentados
- **Documentación completa**: Guías de uso, instalación y ejemplos
- **Validado con datos reales**: Sistema probado con 20 años de datos

## 📦 Contenido

- **5 módulos funcionales**: utilities, data loader, flow duration, time series models, visualization
- **3 ejemplos documentados**: Curvas de duración, ARIMA/ETS, modelos híbridos
- **Documentación en español**: README, guías de instalación y uso
- **Sistema core funcional**: Sin dependencias complejas

## 🚀 Inicio Rápido

```r
# Clonar repositorio
git clone https://github.com/TU-USUARIO/hydroforecast.git
cd hydroforecast

# Instalar dependencias mínimas
install.packages(c("ggplot2", "scales", "data.table", "zoo"))

# Ejecutar ejemplo básico
source("test_ejemplo1.R")
```

## 📊 Resultados Validados

✅ Sistema core probado y funcional  
✅ Generación de escenarios múltiples (P15-P85)  
✅ Exportación automática de resultados  
✅ Gráficos profesionales validados  

## 📖 Documentación

- [README.md](README.md) - Descripción general
- [INSTALACION.md](INSTALACION.md) - Guía de instalación
- [docs/GUIA_USO.md](docs/GUIA_USO.md) - Manual completo
- [docs/MEJORAS_IMPLEMENTADAS.md](docs/MEJORAS_IMPLEMENTADAS.md) - Detalles técnicos

## 🎯 Para Quién es Este Sistema

- Hidrólogos y gestores de recursos hídricos
- Operadores de embalses
- Investigadores en hidrología aplicada
- Consultores ambientales
- Estudiantes de hidrología

## 📝 Licencia

MIT License - Ver [LICENSE](LICENSE)

## 👨‍💻 Autor

**Pablo Rojas** - Hidrólogo  
Especialista en pronóstico de caudales

---

**Nota**: Para funcionalidades avanzadas (ARIMA, modelos híbridos), instalar:
```r
install.packages(c("forecast", "forecastHybrid", "tidyr", "dplyr"))
```
RELEASE_NOTES

echo ""
echo "═══════════════════════════════════════════════════════════════════════════════"
echo "ARCHIVOS INCLUIDOS EN EL REPOSITORIO"
echo "═══════════════════════════════════════════════════════════════════════════════"
echo ""

git ls-files | head -30

echo ""
echo "Total de archivos: $(git ls-files | wc -l)"
echo "Tamaño del repositorio: $(du -sh .git | cut -f1)"
echo ""

echo "═══════════════════════════════════════════════════════════════════════════════"
echo "SIGUIENTE PASO"
echo "═══════════════════════════════════════════════════════════════════════════════"
echo ""
echo "➡️  Crea el repositorio en GitHub y ejecuta:"
echo ""
echo "    git remote add origin https://github.com/TU-USUARIO/hydroforecast.git"
echo "    git push -u origin main"
echo "    git push origin v2.0.0"
echo ""
echo "✅ Listo para publicar!"
echo ""
