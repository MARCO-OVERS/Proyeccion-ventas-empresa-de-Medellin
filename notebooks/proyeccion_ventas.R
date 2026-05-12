#============================================================================#
#                     Proyeccion de ventas, empresa de aburra                #
#                                                                            #
#                        Marco Antonio Rolon Oliveros                        #
#                                                                            #
#============================================================================#
install.packages("renv")
renv::init()

install.packages("tidyverse")
install.packages("seasonal")
install.packages("forecast")
install.packages("tseries")
install.packages("ggthemes")
install.packages("dynlm")
install.packages("writexl")
install.packages("readxl")
# ================================
# 1. LIBRERIAS
# ================================
library(tidyverse)
library(seasonal)
library(tseries)
library(car)
library(forecast)
library(zoo)
library(ggthemes)
library(dynlm)
library(writexl)
library(readxl)
# ================================
# 2. CARGA DE DATOS
# ================================

datos_aburra <- read_excel("C:/Users/marco/OneDrive/Desktop/CURSO AD UQ/Empresa camara de comercio aburra sur.xlsx")

# Inspeccion inicial
head(datos_aburra)
names(datos_aburra)

## comportamiento natural de la varible "activos"
ggplot(datos_aburra, aes(x = anno, y = activos)) +
  geom_col(fill = "#4CE051") +
  scale_x_continuous(breaks = seq(min(datos_aburra$anno),
                                  max(datos_aburra$anno),
                                  by = 10)) +
  ggtitle("Activos en el tiempo (serie original)") +
  xlab("Año") +
  ylab("Activos") +
  theme_bw()


## Empleados a lo largo de la historia
ggplot(datos_aburra, aes(x = anno, y = empleos)) +
  geom_col(fill = "#75C0F0") +
  scale_x_continuous(breaks = seq(min(datos_aburra$anno),
                                  max(datos_aburra$anno),
                                  by = 10)) +
  ggtitle("Empleos en el tiempo (serie original)") +
  xlab("Año") +
  ylab("empleos") +
  theme_bw()

# ================================
# 3. CREAR SERIE DE TIEMPO
# ================================

e_activo <- ts(datos_aburra$activos, 
                frequency = 1,   
                start = c(1950))


plot(e_activo,
     main = "Serie original de los activos",
     xlab = "Tiempo",
     ylab = "Activos",
     xaxt = "n")   # n para quitar automatico

#  eje cada 10 años
axis(1, at = seq(1950, 2024, by = 10))

# ================================
# 4. TRANSFORMACION LOGARITMICA
# ================================
# Se usa para estabilizar la varianza

log_activo <- log(e_activo)

plot(log_activo,
     main = "Serie en logaritmos",
     xlab = "Tiempo",
     ylab = "Log(Activos)")

# ================================
# 5. PRIMERA DIFERENCIACION DEL MODELO
# ================================

dlog_activo <- diff(log_activo) # mata tendencia
# se ve las tendencias 
plot(dlog_activo,
     main = "Primera diferencia del log(activos)",
     ylab = "log(activos)",
     xlab = "Tiempo")

# ================================
# 6. TEST DE ESTACIONARIEDAD
# ================================
p_cri <- 0.05

# Dickey-Fuller asume que la series es terrible
adf <- adf.test(dlog_activo)

# KPSS
kpss <- kpss.test(dlog_activo)

# Interpretacion:
adf$p.value < p_cri      # TRUE -> estacionaria
kpss$p.value > p_cri     # TRUE -> estacionaria


# ================================
# 7. VISUALIZACION FINAL BONITA
# ================================
autoplot(dlog_activo) +
  ggtitle("Modelo Con Estacionariedad") +
  xlab("Tiempo") +
  ylab("Tasa de Cambio en los activos") +
  theme_bw() +
  geom_line(color = "#8C1C07") +
  scale_x_continuous(breaks = seq(1950, 2024, by = 10))

#================================
# 8. ACF y PACF
# ================================

par(mfrow = c(1,2))

acf(dlog_activo, main = "ACF - Diferencia log(activos)")
pacf(dlog_activo, main = "PACF - Diferencia log(activos)")

par(mfrow = c(1,1))


# Modelo auto.arima
modelo_auto <- auto.arima(log_activo)
summary(modelo_auto)

# Diagnóstico de residuos
checkresiduals(modelo_auto)
Box.test(modelo_auto$residuals, type=("Ljung-Box")) # Son ruido blanco

# pronostico como el taller o sea 12 periodos 
pronostico <- forecast(modelo_auto, h = 12)

autoplot(pronostico) +
  ggtitle("Pronóstico de los activos") +
  xlab("Tiempo") +
  ylab("Log(activos)")
