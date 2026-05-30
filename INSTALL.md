# Instalación Rápida - Movie Folder Renamer

## 🚀 Instalación Automática (Recomendado)

### macOS

```bash
git clone https://github.com/Danibos/folder_rename.git
cd folder_rename
git checkout gui-interface
chmod +x setup.sh
./setup.sh
```

Luego abre la aplicación:
```bash
open Movie\ Folder\ Renamer.app
```

O ejecuta desde terminal:
```bash
movie-folder-renamer
```

### Linux (Ubuntu/Debian, Fedora, Arch)

```bash
git clone https://github.com/Danibos/folder_rename.git
cd folder_rename
git checkout gui-interface
chmod +x setup.sh
./setup.sh
```

Luego ejecuta desde terminal o desde el menú de aplicaciones:
```bash
movie-folder-renamer
```

## 📋 Lo que hace el script de instalación

✅ Detecta automáticamente tu sistema operativo (macOS o Linux)
✅ Verifica e instala Python 3.8+ si es necesario
✅ Instala todas las dependencias del sistema
✅ Crea un entorno virtual Python aislado
✅ Instala todas las dependencias Python (PyQt6, requests, tmdbv3api)
✅ Crea un ejecutable de aplicación:
   - **macOS**: Crea un `.app` bundle que puedes mover a Applications
   - **Linux**: Crea un entrada de escritorio y ejecutable en `~/.local/bin`

## 🎯 Primeros pasos después de instalar

1. **Obtén una API key de TMDB** (gratis):
   - Visita https://www.themoviedb.org/settings/api
   - Crea una cuenta o inicia sesión
   - Acepta los términos de servicio
   - Copia tu **API Key (v3 auth)**

2. **Lanza la aplicación**:
   - **macOS**: `open Movie\ Folder\ Renamer.app` o desde el Finder
   - **Linux**: `movie-folder-renamer` o desde el menú de aplicaciones

3. **Configura en la GUI**:
   - Pega tu API key de TMDB
   - Selecciona tu carpeta de películas
   - Elige el idioma y número de hilos
   - ¡Haz clic en "Iniciar procesamiento"!

## 🔧 Solución de problemas durante la instalación

### Error: "Permission denied" al ejecutar setup.sh

```bash
chmod +x setup.sh
./setup.sh
```

### Error: "Python 3 not found" en macOS

Instala Homebrew primero:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Luego vuelve a ejecutar `setup.sh`.

### Error: "sudo password" en Linux

El script necesita permisos de administrador para instalar dependencias del sistema.
Te pedirá contraseña solo una vez.

### Error: "pip: No such file or directory"

Asegúrate de que Python 3 y pip están instalados:
```bash
python3 --version
pip3 --version
```

## 📱 Uso de la aplicación GUI

### Interfaz principal (pestaña "Procesamiento")

1. **Directorio de películas**: 
   - Haz clic en "Explorar" para seleccionar tu carpeta
   - O escribe la ruta manualmente

2. **Clave API de TMDB**:
   - Campo protegido para tu seguridad
   - Obtén una en https://www.themoviedb.org/settings/api

3. **Idioma**:
   - Español (es) - Por defecto
   - Inglés (en)
   - Francés (fr)
   - Alemán (de)

4. **Número de hilos**:
   - macOS: 4 por defecto
   - Linux: 8 por defecto
   - Ajusta según tu CPU

5. **Botones**:
   - **Iniciar procesamiento**: Comienza el renombrado
   - **Limpiar registro**: Borra el log
   - **Detener**: Cancela la operación

### Pestaña "Ayuda"

Información y requisitos dentro de la aplicación.

## 📂 Estructura esperada de carpetas

```
Tu carpeta de películas/
├── The Shawshank Redemption/
│   ├── the.shawshank.redemption.1994.mkv
│   └── the.shawshank.redemption.1994.nfo (opcional)
├── Forrest Gump 1994/
│   ├── forrest.gump.1994.mp4
���   └── forrest.gump.1994.srt
└── The Dark Knight/
    └── the.dark.knight.2008.avi
```

## 📤 Resultado después del procesamiento

```
Tu carpeta de películas/
├── The Shawshank Redemption (1994) Frank Darabont/
│   ├── The Shawshank Redemption (1994).mkv
│   ├── The Shawshank Redemption (1994).nfo
│   └── The Shawshank Redemption (1994).srt
├── Forrest Gump (1994) Robert Zemeckis/
│   ├── Forrest Gump (1994).mp4
│   └── Forrest Gump (1994).nfo
└── The Dark Knight (2008) Christopher Nolan/
    └── The Dark Knight (2008).avi
```

## 🐛 Reportar problemas

Si encuentras algún problema:

1. Verifica que tienes conexión a internet
2. Comprueba que tu API key es válida
3. Revisa el registro en la GUI para mensajes de error
4. Abre un issue en GitHub con:
   - Tu sistema operativo y versión
   - El error que recibiste
   - Los pasos que hiciste

## 📚 Documentación completa

Para más información, consulta:
- `GUI_README.md` - Guía completa de la GUI
- `README.md` - Información del script original
- [TMDB API Docs](https://www.themoviedb.org/settings/api)

## ⚙️ Instalación manual (avanzado)

Si prefieres instalar manualmente sin el script:

```bash
# Clonar repositorio
git clone https://github.com/Danibos/folder_rename.git
cd folder_rename
git checkout gui-interface

# Crear entorno virtual
python3 -m venv venv
source venv/bin/activate  # macOS/Linux

# Instalar dependencias
pip install -r requirements.txt

# Ejecutar
python3 gui_app.py
```

## 📝 Licencia

MIT License - Software libre y de código abierto

---

**¿Necesitas ayuda?** Consulta la documentación completa en `GUI_README.md`
