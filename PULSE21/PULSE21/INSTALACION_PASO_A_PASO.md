# Instalación de PULSE 21 desde cero

## Antes de empezar
**Para compilar una app nativa con HealthKit necesitás una Mac con Xcode.** No se puede compilar, firmar ni conceder acceso a HealthKit a una app nativa completa usando únicamente un iPhone. Si tenés Windows, podés editar los archivos, pero la compilación requiere una Mac local o un servicio remoto de Mac.

## 1. Descargar el proyecto
Descargá `PULSE21.zip` y descomprimilo. Deberías ver `PULSE21.xcodeproj`, la carpeta `PULSE21`, `README.md` y esta guía.

## 2. Instalar Xcode
1. En la Mac, abrí App Store.
2. Buscá **Xcode** de Apple e instalalo.
3. Abrilo una vez y aceptá los componentes/licencia si te lo solicita.
4. Esperá a que termine la instalación de componentes.

## 3. Abrir el proyecto
1. Hacé doble clic en `PULSE21.xcodeproj`.
2. En el panel izquierdo seleccioná el proyecto y luego el target **PULSE21**.
3. Abrí **Signing & Capabilities**.

## 4. Configurar identificador y firma
1. Activá **Automatically manage signing**.
2. En **Team**, elegí tu cuenta Apple. Si no aparece, agregala en Xcode → Settings → Accounts.
3. Cambiá `com.example.PULSE21` por un identificador único, por ejemplo `com.tunombre.pulse21`.
4. Si Xcode informa que el perfil no coincide, verificá que el identificador sea único y que la cuenta esté seleccionada.

## 5. Habilitar HealthKit
1. En el target, entrá a **Signing & Capabilities**.
2. Agregá la capacidad **HealthKit** si no aparece.
3. El proyecto incluye el entitlement y el texto que explica por qué se leen datos de Salud.
4. No agregues permisos de escritura: la versión actual solo lee datos.

## 6. Conectar el iPhone
1. Conectá el iPhone con un cable de datos.
2. Desbloquealo y aceptá **Confiar en este ordenador** si aparece.
3. En el iPhone, activá el modo desarrollador si iOS/Xcode lo solicita (Ajustes → Privacidad y seguridad → Modo desarrollador; la ruta puede variar).
4. En Xcode, elegí tu iPhone como destino de ejecución.

## 7. Compilar e instalar
1. Pulsá el botón triangular **Run**.
2. Esperá a que Xcode compile y copie la app al iPhone.
3. Si aparece un error de firma, revisá Team, Bundle Identifier y la conexión a internet.
4. Abrí PULSE 21 en el iPhone.

## 8. Dar acceso a Apple Salud
1. En PULSE 21, pulsá el botón circular de sincronización o entrá a **Settings → Conectar con Apple Salud**.
2. Aceptá los permisos de lectura que quieras conceder.
3. Para revisar después: abrí Salud → foto de perfil → Apps y servicios → PULSE 21. Los nombres exactos pueden variar según la versión de iOS.

## 9. Verificar la QWatch Pro
1. Abrí la app que sincroniza tu QWatch Pro y confirmá que esté habilitada la sincronización con Apple Salud.
2. Abrí Apple Salud y buscá, por ejemplo, frecuencia cardíaca, pasos, energía activa o sueño.
3. Verificá que existan datos con fecha reciente.
4. Volvé a PULSE 21 y actualizá.
5. Si PULSE 21 muestra «Sin datos», comprobá primero si Apple Salud tiene esa métrica. Una app no puede recuperar datos que la pulsera no haya escrito en Salud. Además, Apple no revela de forma fiable a una app si la lectura fue denegada o simplemente no existen muestras.

## Errores habituales
- **HealthKit no disponible en simulador:** probá en un iPhone físico; algunas capacidades no se comportan igual en simulador.
- **No aparecen datos:** verificá sincronización de QWatch Pro en Salud, permisos y rango temporal.
- **No se instala:** revisá firma automática, Team, identificador y que el iPhone esté desbloqueado.
- **La app no aparece en la lista de Salud:** ejecutala al menos una vez y solicitá permisos desde la app.
- **No hay puntuación de Recovery:** es intencional mientras no exista una línea de base personal suficiente. No es un error que se deba resolver inventando un valor.
