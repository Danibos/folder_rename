# Información Técnica - Cómo se Crea el Ejecutable

## 🎯 Resumen

El script `setup.sh` automatiza completamente el proceso de instalación y creación de aplicaciones ejecutables para macOS y Linux.

## 📊 Flujo de Instalación

```
setup.sh
├── 1. Detectar SO (macOS/Linux)
├── 2. Instalar Python 3
├── 3. Instalar dependencias del sistema
├── 4. Crear entorno virtual (venv)
├── 5. Instalar dependencias Python
├── 6. Crear wrappers/ejecutables
│   ├── Si es macOS → Crear app bundle (.app)
│   └── Si es Linux → Crear desktop entry + ejecutable
└── 7. Mostrar instrucciones finales
```

## 🍎 Cómo funciona en macOS

### 1. App Bundle (.app)

El script crea una estructura de carpeta especial que macOS reconoce como aplicación:

```
Movie Folder Renamer.app/
├── Contents/
│   ├── MacOS/
│   │   └── launcher.sh (script ejecutable)
│   ├── Resources/
│   └── Info.plist (metadatos de la aplicación)
└── (macOS reconoce esto como una "aplicación")
```

### 2. Componentes principales

**`Info.plist`**: Archivo de configuración XML que contiene:
- Nombre de la aplicación
- Versión
- Identificador único (bundle ID)
- Ejecutable
- Requisitos del sistema (macOS 10.13+)

**`launcher.sh`**: Script bash que:
1. Detecta la ubicación de la carpeta
2. Activa el entorno virtual
3. Ejecuta `gui_app.py`

### 3. Instalación en macOS

```bash
# El app bundle se crea en el directorio actual
open Movie\ Folder\ Renamer.app

# Para usar como app normal, mover a Applications
mv 'Movie Folder Renamer.app' ~/Applications/
```

### 4. Ventajas

✅ Se ve como una aplicación nativa macOS  
✅ Aparece en Launchpad  
✅ Se puede mover a Applications  
✅ Puede tener iconos personalizados  
✅ Integración completa con el sistema  

## 🐧 Cómo funciona en Linux

### 1. Desktop Entry

El script crea un archivo `.desktop` que permite que Linux reconozca la aplicación:

```
~/.local/share/applications/movie-folder-renamer.desktop
```

Contenido del archivo:
```ini
[Desktop Entry]
Version=1.0
Type=Application
Name=Movie Folder Renamer
Comment=Rename your movie folders
Icon=movie-folder-renamer
Exec=/home/usuario/.local/bin/movie-folder-renamer
Categories=Utility;
Terminal=false
```

### 2. Ejecutable

El script crea un ejecutable en `~/.local/bin/`:

```bash
~/.local/bin/movie-folder-renamer
```

Este archivo:
- Es un script bash ejecutable
- Activa el entorno virtual
- Ejecuta la aplicación GUI
- Se añade automáticamente al PATH

### 3. Iconos

El script crea un icono SVG en:
```
~/.local/share/icons/hicolor/256x256/apps/movie-folder-renamer.svg
```

### 4. Ubicación e instalación

La aplicación se registra en:
- **Ejecutable**: `~/.local/bin/movie-folder-renamer`
- **Desktop Entry**: `~/.local/share/applications/movie-folder-renamer.desktop`
- **Icono**: `~/.local/share/icons/hicolor/256x256/apps/movie-folder-renamer.svg`

### 5. Formas de ejecutar en Linux

```bash
# Desde terminal
movie-folder-renamer

# Desde el menú de aplicaciones
# (aparece bajo "Utility")

# Desde la terminal con argumentos
movie-folder-renamer --help
```

### 6. Ventajas

✅ Se integra con el menú de aplicaciones del escritorio  
✅ Ejecutable desde terminal en cualquier directorio  
✅ Sigue los estándares XDG de Linux  
✅ Compatible con múltiples entornos de escritorio  

## 🔍 Estructura de directorios creada

### macOS

```
/ruta/proyecto/
├── setup.sh
├── gui_app.py
├── RenameMyFolders.py
├── requirements.txt
├── venv/ (entorno virtual)
├── Movie Folder Renamer.app/ (aplicación)
│   └── Contents/
│       ├── MacOS/launcher.sh
│       ├── Resources/
│       └── Info.plist
└── movie-folder-renamer (wrapper script)
```

### Linux

```
/home/usuario/proyecto/
├── setup.sh
├── gui_app.py
├── RenameMyFolders.py
├── requirements.txt
├── venv/ (entorno virtual)
└── movie-folder-renamer (wrapper script)

/home/usuario/.local/
├── bin/movie-folder-renamer (ejecutable)
├── share/
│   ├── applications/
│   │   └── movie-folder-renamer.desktop
│   └── icons/
│       └── hicolor/256x256/apps/
│           └── movie-folder-renamer.svg
```

## 🛠️ Características técnicas del script

### Detección automática del sistema

```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_TYPE="linux"
fi
```

### Instalación de dependencias por distribución

El script detecta y usa el gestor de paquetes correcto:
- **Debian/Ubuntu**: `apt-get`
- **Fedora/RHEL**: `dnf` o `yum`
- **Arch Linux**: `pacman`
- **macOS**: `brew`

### Manejo de errores

```bash
set -e  # Exit on error
# Cada comando que falla detiene el script
```

### Colores en la salida

```bash
RED='\033[0;31m'      # Errores
GREEN='\033[0;32m'    # Éxito
YELLOW='\033[1;33m'   # Información
BLUE='\033[0;34m'     # Headers
```

## 📝 Qué hace el setup.sh paso a paso

### 1️⃣ Detección del SO
- Identifica si es macOS o Linux
- Detecta la distribución específica en Linux

### 2️⃣ Instalación de Python
```bash
# Si no existe, instala Python 3
brew install python3      # macOS
sudo apt-get install ...  # Linux
```

### 3️⃣ Dependencias del sistema
Instala las librerías necesarias para PyQt6:
- Qt6 (GUI framework)
- libxkbcommon (input)
- DBus (comunicación del sistema)
- Fuentes y librerías gráficas

### 4️⃣ Entorno virtual
```bash
python3 -m venv venv
source venv/bin/activate
```

### 5️⃣ Dependencias Python
```bash
pip install -r requirements.txt
# Instala: requests, tmdbv3api, PyQt6
```

### 6️⃣ Creación de ejecutables
- **macOS**: Crea `.app` bundle
- **Linux**: Crea `desktop entry` + ejecutable

### 7️⃣ Instrucciones finales
Muestra cómo usar la aplicación recién instalada

## 🔒 Seguridad

El script:
- ✅ No requiere modificar archivos del sistema innecesariamente
- ✅ Usa `~/.local` en Linux (no necesita sudo)
- ✅ Usa `venv` para aislar dependencias Python
- ✅ Valida la existencia de archivos antes de usarlos
- ✅ Maneja errores apropiadamente

## 📦 Distribución de la aplicación (Avanzado)

Si quisieras distribuir la aplicación:

### macOS
```bash
# Empaquetar como ZIP
zip -r "Movie Folder Renamer.zip" "Movie Folder Renamer.app"

# O crear un DMG (disk image)
hdiutil create -volname "Movie Folder Renamer" \
               -srcfolder . \
               -ov -format UDZO \
               "MovieFolderRenamer.dmg"
```

### Linux
```bash
# Crear un AppImage
# Requiere: appimagetool y otros

# O crear un paquete deb/rpm
# Requiere: configuración de packaging
```

## 🐛 Debugging

Si el script falla:

### Ver los pasos en detalle
```bash
bash -x setup.sh  # Modo verbose
```

### Revisar logs
```bash
# macOS - Ver logs de instalación
tail -f setup.log

# Linux - Ver qué está haciendo apt
# El script muestra salida en tiempo real
```

### Reinstalar
```bash
# Limpiar venv
rm -rf venv

# Volver a ejecutar
./setup.sh
```

---

**Versión del documento**: 1.0  
**Compatible con**: macOS 10.13+, Linux (Ubuntu, Fedora, Arch, etc.)  
**Última actualización**: Mayo 2026
