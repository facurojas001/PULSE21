# PULSE 21 — proyecto nativo iOS

Aplicación SwiftUI con integración de lectura de Apple Health/HealthKit, estética oscura deportiva y navegación Today / Strain / Sleep / Settings. No es una app oficial de WHOOP.

## Requisitos
- Mac compatible con una versión actual de macOS.
- Xcode 15 o posterior (recomendado Xcode actual).
- iPhone con iOS 16 o posterior para el conjunto completo de fases de sueño; el proyecto usa APIs base de HealthKit.
- Cuenta Apple para firmar e instalar en dispositivo. Una cuenta gratuita permite probar en un dispositivo propio con limitaciones de firma; distribución a terceros requiere el programa correspondiente.

## Abrir y compilar
1. Descomprimí `PULSE21.zip` si descargaste el archivo empaquetado.
2. Abrí `PULSE21.xcodeproj` con Xcode en una Mac.
3. Seleccioná el target **PULSE21** → **Signing & Capabilities**.
4. Activá **Automatically manage signing** y seleccioná tu Team de Apple.
5. Cambiá el Bundle Identifier `com.example.PULSE21` por uno único, por ejemplo `com.tunombre.pulse21`.
6. Confirmá que la capacidad **HealthKit** esté habilitada. El proyecto incluye `PULSE21.entitlements` y el texto de privacidad `NSHealthShareUsageDescription`.
7. Conectá el iPhone por cable (o configurá conexión inalámbrica desde Xcode), desbloquealo y aceptá **Confiar** si aparece.
8. En el selector de destino de Xcode, elegí tu iPhone.
9. Pulsá Run (▶). La primera compilación instala la app en el dispositivo.
10. Abrí PULSE 21 y pulsá el botón circular de sincronización o **Settings → Conectar con Apple Salud**. Concedé los permisos solicitados.
11. Para comprobar datos, abrí Apple Salud y verificá que la QWatch Pro sincronice datos recientes. Después volvé a PULSE 21 y actualizá.

## Revisar permisos en iPhone
En iOS, abrí **Salud → foto de perfil → Apps y servicios → PULSE 21** (el texto puede variar por versión) y revisá los tipos de datos permitidos. Apple no ofrece a una app un indicador fiable que distinga siempre entre permiso de lectura denegado y ausencia de datos; por eso PULSE 21 muestra estados vacíos como “Sin datos”.

## Cómo fluye la información
`QWatch Pro → app/servicio de la pulsera → Apple Salud → PULSE 21`. PULSE 21 no se conecta directamente a la pulsera y no puede leer mediciones que no estén en Salud.

## Qué está implementado
- SwiftUI nativo y navegación funcional de cuatro secciones.
- Interfaz oscura con tres anillos, tarjetas de métricas y estados vacíos.
- Solicitud de autorización de lectura HealthKit.
- Lectura de última frecuencia cardíaca, FC en reposo y HRV SDNN; sumas del día de pasos, energía activa y distancia caminada/corrida.
- Lectura de muestras de sueño recientes con fusión de intervalos solapados.
- Historial de entrenamientos de 30 días desde HealthKit.
- Registro manual de actividad con deporte, fecha, duración y RPE, guardado localmente.
- Algoritmo heurístico de esfuerzo documentado y función de recuperación que permanece en calibración si no tiene línea de base.
- Objetivo de sueño configurable y README en español.
- Pruebas unitarias de ejemplo para estados vacíos, límites de Strain y calibración de Recovery.

## Pendiente / limitaciones conocidas
- No se pudo compilar ni ejecutar Xcode/HealthKit en este entorno; las pruebas incluidas no se han ejecutado aquí. Es obligatorio compilar y validar en Xcode y en un iPhone real.
- La línea de base de HRV/FC en reposo y el historial de calibración aún no se construyen automáticamente; por seguridad, Recovery normalmente mostrará “Calibrando”.
- La vista de siete días, regularidad del sueño y desglose de fases todavía no están implementados, aunque no se inventan fases.
- La lectura de frecuencia cardíaca es la muestra más reciente disponible, no un flujo continuo del día. La integración completa de zonas/tiempo en zona y cálculo de carga desde muestras históricas queda pendiente.
- La detección de duplicados entre registros manuales y entrenamientos de Apple Salud no puede garantizarse todavía. Solo se filtran entradas manuales muy similares entre sí; el formulario recomienda no duplicar actividades ya registradas.
- La autorización HealthKit no permite confirmar de forma fiable si una categoría sin resultados se debe a permisos denegados o a falta de datos.
- El archivo de pruebas está preparado como fuente de XCTest, pero debe añadirse/confirmarse en un target de pruebas de Xcode si el proyecto creado no lo asocia automáticamente.

## Algoritmos
- **Strain**: aproximación propia, normalizada entre 1 y 21, basada en duración × RPE y una contribución opcional de muestras cardíacas. No equivale a un algoritmo validado ni al algoritmo de WHOOP.
- **Recovery**: combina desviación de HRV y FC en reposo respecto de la línea de base, sueño y carga reciente cuando están disponibles. Requiere al menos siete días de calibración y datos comparables; no es un diagnóstico.
- **Sleep**: fusiona intervalos solapados para evitar sumar dos veces los mismos períodos. Solo considera fases si están registradas como estados asleep compatibles.

## Privacidad
No hay backend, analítica ni transmisión de datos. Las actividades manuales se almacenan en UserDefaults en el dispositivo. La app solo solicita lectura de HealthKit y no escribe datos de salud.
