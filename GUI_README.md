# Movie Folder Renamer GUI

Una interfaz gráfica moderna y fácil de usar para renombrar carpetas de películas automáticamente.

## Características

✨ **Interfaz Gráfica Intuitiva**
- Diseño limpio y moderno con PyQt6
- Dos pestañas: Procesamiento y Ayuda
- Visualización en tiempo real del progreso

🎬 **Renombrado Automático**
- Obtiene información directamente de TMDB (The Movie Database)
- Formato de renombrado: `Título (Año) Director`
- Soporte multiidioma (Español, Inglés, Francés, Alemán)

⚙️ **Características Técnicas**
- Procesamiento paralelo configurable
- Compatibilidad total con macOS y Linux
- Actualización automática de archivos .nfo
- Eliminación de duplicados
- Manejo robusto de caracteres especiales

## Requisitos

- Python 3.8 o superior
- macOS 10.13+ o Linux (cualquier distribución moderna)
- Clave API gratuita de TMDB (obtén la tuya en https://www.themoviedb.org/settings/api)

## Instalación

### 1. Clonar o descargar el repositorio

```bash
git clone https://github.com/Danibos/folder_rename.git
cd folder_rename
git checkout gui-interface
```

### 2. Crear un entorno virtual (recomendado)

```bash
# macOS y Linux
python3 -m venv venv
source venv/bin/activate
```

### 3. Instalar dependencias

```bash
pip install -r requirements.txt
```

## Uso

### Iniciar la aplicación

```bash
python3 gui_app.py
```

### Pasos para usar la GUI

1. **Selecciona carpeta**: Haz clic en "Explorar" y elige la carpeta con tus películas
2. **Configura opciones**:
   - Ingresa tu clave API de TMDB
   - Selecciona el idioma deseado
   - Ajusta el número de hilos (por defecto: 4 en macOS, 8 en Linux)
3. **Inicia procesamiento**: Haz clic en "Iniciar procesamiento"
4. **Monitorea el progreso**: El registro en tiempo real muestra todo lo que ocurre

### Estructura de carpetas esperada

```
Tu carpeta de películas/
├── Película 1/
│   ├── película1.mkv
│   ├── película1.nfo (opcional pero recomendado)
│   └── película1.srt
├── Película 2/
│   ├── película2.mp4
│   └── película2.nfo
└── Película 3/
    └── película3.avi
```

### Resultado esperado

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

## Configuración de la API de TMDB

1. Ve a https://www.themoviedb.org/settings/api
2. Inicia sesión (crea una cuenta si es necesario)
3. Aceptar los términos de uso
4. Copia tu **API Key (v3 auth)**
5. Pégala en la aplicación GUI

## Solución de problemas

### "Error de API"
- Verifica que tu clave API sea correcta
- Asegúrate de tener conexión a internet
- Espera unos minutos si has realizado muchas solicitudes (hay límite de velocidad)

### "Carpeta no encontrada"
- Verifica que la ruta es correcta
- Usa rutas absolutas si es posible
- Asegúrate de que tienes permisos de lectura/escritura

### "No se encontraron películas"
- Verifica que las carpetas contienen archivos de video válidos
- Asegúrate de que los nombres de archivo contienen el título y año
- Crea archivos .nfo para mayor precisión

## Extensiones de archivo soportadas

**Video:** `.mp4`, `.avi`, `.mkv`, `.mov`, `.wmv`
**Metadatos:** `.nfo`
**Subtítulos:** `.srt`, `.ass`, `.ssa`, `.sub`

## Comparación: CLI vs GUI

| Característica | CLI (script original) | GUI |
|---|---|---|
| Facilidad de uso | Para usuarios avanzados | Para todos |
| Visualización | Salida en terminal | Interfaz gráfica |
| Configuración | Editar código | Controles visuales |
| Monitoreo | Difícil | Fácil y en tiempo real |
| Multiidioma | Requiere editar código | Selector en GUI |

## Notas de desarrollo

### Modificar la lógica de renombrado

Edita el archivo `RenameMyFolders.py` para personalizar el comportamiento.

### Agregar más idiomas

En `gui_app.py`, modifica el `QComboBox` de idiomas:

```python
self.lang_combo.addItems([
    "es (Español)",
    "en (Inglés)",
    "fr (Francés)",
    "de (Alemán)",
    "it (Italiano)"  # Agregar nuevo
])
```

Y actualiza el mapa de idiomas:

```python
lang_map = {
    "es (Español)": "es",
    "en (Inglés)": "en",
    "fr (Francés)": "fr",
    "de (Alemán)": "de",
    "it (Italiano)": "it"  # Agregar nuevo
}
```

## Licencia

MIT License - Código abierto y libre para usar

## Créditos

- Script original por Danibos
- GUI creada con PyQt6
- Datos de películas de TMDB

## Soporte

Para reportar problemas o sugerir mejoras, abre un issue en GitHub.

---

**Versión de GUI**: 1.0.0  
**Última actualización**: Mayo 2026
