# PULSE 21: compilar desde Windows con Codemagic

Esta configuración sirve para comprobar si el proyecto nativo de iOS compila en un servidor macOS remoto. La primera compilación es **sin firma**: no instala la app en el iPhone ni habilita su distribución. Para instalarla en un dispositivo físico hace falta resolver la firma y el perfil de aprovisionamiento de Apple.

## Archivos
- `PULSE21.xcodeproj/`: proyecto de Xcode.
- `PULSE21/`: código SwiftUI, HealthKit, Info.plist y entitlements.
- `codemagic.yaml`: flujo de compilación en Codemagic. Debe estar en la raíz del repositorio de GitHub, al mismo nivel que `PULSE21.xcodeproj`.
- `README.md`: descripción, funciones y limitaciones conocidas.
- `INSTALACION_PASO_A_PASO.md`: instalación tradicional desde una Mac con Xcode.

## Pasos
1. Descargá y extraé `PULSE21.zip` en Windows.
2. Creá un repositorio en GitHub y subí **el contenido extraído**, no el ZIP como único archivo. La raíz del repositorio debe mostrar `PULSE21.xcodeproj`, `PULSE21/` y `codemagic.yaml`.
3. En Codemagic, conectá GitHub, elegí el repositorio y agregalo como aplicación nativa iOS.
4. Confirmá que `codemagic.yaml` esté en la rama seleccionada y en la raíz. En la configuración de Codemagic, ejecutá el workflow `pulse21-ios-unsigned`.
5. Si falla, descargá `xcodebuild.log` o los logs del build y revisá el primer error real de Xcode. No supongas que el proyecto funciona hasta que el build figure como exitoso.
6. Si el build tiene éxito, el artefacto `.app` de esta fase es solo para comprobar la compilación. Para instalarlo en tu iPhone necesitás una compilación firmada y un provisioning profile compatible.

## Firma de Apple
La configuración de firma de Codemagic normalmente requiere una membresía activa de Apple Developer Program y credenciales/perfiles adecuados para el método de distribución elegido. No subas contraseñas de Apple ni claves privadas al repositorio de GitHub. Consultá la documentación oficial de firma de Codemagic antes de cargar certificados o claves: https://docs.codemagic.io/yaml-code-signing/signing-ios/

## Documentación oficial
- Codemagic: app iOS nativa y `codemagic.yaml`: https://docs.codemagic.io/yaml-quick-start/building-a-native-ios-app/
- Codemagic: firma de apps iOS: https://docs.codemagic.io/yaml-code-signing/signing-ios/
- GitHub Desktop: https://desktop.github.com/
- GitHub: crear repositorio: https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository
