import sys
import os
from pathlib import Path
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QPushButton, QLabel, QLineEdit, QFileDialog, QTextEdit, QComboBox,
    QSpinBox, QCheckBox, QProgressBar, QMessageBox, QTabWidget, QFormLayout
)
from PyQt6.QtCore import Qt, QThread, pyqtSignal
from PyQt6.QtGui import QIcon, QFont
import threading

# Import the core functions from the original script
from RenameMyFolders import (
    rename_folders_parallel, rename_folder_with_tmdb_info,
    get_movie_info, parse_title_year
)


class WorkerThread(QThread):
    """Thread to run the renaming process without freezing the GUI."""
    progress = pyqtSignal(str)
    finished = pyqtSignal()
    error = pyqtSignal(str)

    def __init__(self, base_directory, max_workers):
        super().__init__()
        self.base_directory = base_directory
        self.max_workers = max_workers

    def run(self):
        """Run the renaming process in a separate thread."""
        try:
            # Redirect stdout to emit signals
            original_stdout = sys.stdout
            
            class SignalEmitter:
                def __init__(self, signal):
                    self.signal = signal
                
                def write(self, text):
                    if text.strip():
                        self.signal.emit(text)
                
                def flush(self):
                    pass
            
            sys.stdout = SignalEmitter(self.progress)
            rename_folders_parallel(self.base_directory, self.max_workers)
            sys.stdout = original_stdout
            self.progress.emit("✓ Procesamiento completado exitosamente")
            self.finished.emit()
        except Exception as e:
            sys.stdout = original_stdout
            self.error.emit(f"Error: {str(e)}")
            self.finished.emit()


class RenameGUI(QMainWindow):
    """Main GUI application for Movie Folder Renamer."""

    def __init__(self):
        super().__init__()
        self.worker_thread = None
        self.init_ui()

    def init_ui(self):
        """Initialize the user interface."""
        self.setWindowTitle("Movie Folder Renamer - GUI")
        self.setGeometry(100, 100, 900, 700)
        
        # Create central widget and main layout
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)

        # Create tab widget
        tabs = QTabWidget()
        main_layout.addWidget(tabs)

        # Tab 1: Main Processing
        tab_main = QWidget()
        tab_main_layout = QVBoxLayout(tab_main)
        
        # Directory selection section
        dir_layout = QHBoxLayout()
        dir_label = QLabel("Directorio de películas:")
        dir_label.setFont(QFont("Arial", 10, QFont.Weight.Bold))
        self.dir_path = QLineEdit()
        self.dir_path.setPlaceholderText("Selecciona una carpeta...")
        self.dir_path.setText(os.getcwd())
        browse_btn = QPushButton("Explorar")
        browse_btn.clicked.connect(self.select_directory)
        browse_btn.setMaximumWidth(100)
        dir_layout.addWidget(dir_label)
        dir_layout.addWidget(self.dir_path)
        dir_layout.addWidget(browse_btn)
        tab_main_layout.addLayout(dir_layout)

        # Settings section
        settings_layout = QFormLayout()
        settings_layout.setSpacing(10)

        # Max workers setting
        workers_label = QLabel("Número de hilos:")
        self.workers_spinbox = QSpinBox()
        self.workers_spinbox.setMinimum(1)
        self.workers_spinbox.setMaximum(16)
        self.workers_spinbox.setValue(4 if os.uname().sysname == "Darwin" else 8)
        settings_layout.addRow(workers_label, self.workers_spinbox)

        # API Key setting
        api_key_label = QLabel("Clave API de TMDB:")
        self.api_key_input = QLineEdit()
        self.api_key_input.setEchoMode(QLineEdit.EchoMode.Password)
        self.api_key_input.setPlaceholderText("Introduce tu clave API de TMDB")
        settings_layout.addRow(api_key_label, self.api_key_input)

        # Language setting
        lang_label = QLabel("Idioma:")
        self.lang_combo = QComboBox()
        self.lang_combo.addItems(["es (Español)", "en (Inglés)", "fr (Francés)", "de (Alemán)"])
        settings_layout.addRow(lang_label, self.lang_combo)

        tab_main_layout.addLayout(settings_layout)

        # Output section
        output_label = QLabel("Registro de procesamiento:")
        output_label.setFont(QFont("Arial", 10, QFont.Weight.Bold))
        tab_main_layout.addWidget(output_label)
        self.output_text = QTextEdit()
        self.output_text.setReadOnly(True)
        self.output_text.setMaximumHeight(300)
        tab_main_layout.addWidget(self.output_text)

        # Progress bar
        self.progress_bar = QProgressBar()
        self.progress_bar.setVisible(False)
        tab_main_layout.addWidget(self.progress_bar)

        # Buttons section
        buttons_layout = QHBoxLayout()
        start_btn = QPushButton("Iniciar procesamiento")
        start_btn.setFont(QFont("Arial", 10, QFont.Weight.Bold))
        start_btn.setStyleSheet("background-color: #4CAF50; color: white; padding: 10px;")
        start_btn.clicked.connect(self.start_processing)
        
        clear_btn = QPushButton("Limpiar registro")
        clear_btn.clicked.connect(self.clear_output)
        clear_btn.setMaximumWidth(150)
        
        stop_btn = QPushButton("Detener")
        stop_btn.setMaximumWidth(100)
        stop_btn.clicked.connect(self.stop_processing)
        
        buttons_layout.addWidget(start_btn)
        buttons_layout.addWidget(clear_btn)
        buttons_layout.addWidget(stop_btn)
        
        tab_main_layout.addLayout(buttons_layout)
        tab_main_layout.addStretch()

        tabs.addTab(tab_main, "Procesamiento")

        # Tab 2: About/Help
        tab_help = QWidget()
        tab_help_layout = QVBoxLayout(tab_help)
        
        help_text = QTextEdit()
        help_text.setReadOnly(True)
        help_text.setMarkdown("""# Movie Folder Renamer - Guía de Uso

## Características

- **Renombrado automático**: Renombra carpetas de películas con el formato: Título (Año) Director
- **Información de TMDB**: Obtiene datos directamente de The Movie Database
- **Procesamiento paralelo**: Procesa múltiples carpetas simultáneamente
- **Información NFO**: Actualiza o crea archivos .nfo con metadatos
- **Compatibilidad**: Funciona en macOS y Linux

## Configuración

1. **Clave API de TMDB**: Obtén una gratis en https://www.themoviedb.org/
2. **Número de hilos**: Ajusta según tu sistema (macOS: 4, Linux: 8)
3. **Idioma**: Selecciona el idioma para los títulos de películas

## Instrucciones

1. Selecciona la carpeta con tus películas
2. Ingresa tu clave API de TMDB
3. Ajusta el número de hilos si es necesario
4. Haz clic en "Iniciar procesamiento"
5. El registro te mostrará el progreso

## Requisitos de archivos

Las carpetas deben contener al menos uno de estos archivos:
- `.nfo` (recomendado para mejor precisión)
- `.mp4`, `.avi`, `.mkv`, `.mov`, `.wmv`

## Licencia

MIT License - Código abierto
""")
        tab_help_layout.addWidget(help_text)
        tabs.addTab(tab_help, "Ayuda")

    def select_directory(self):
        """Open file dialog to select directory."""
        directory = QFileDialog.getExistingDirectory(
            self,
            "Selecciona la carpeta de películas",
            os.path.expanduser("~")
        )
        if directory:
            self.dir_path.setText(directory)
            self.output_text.append(f"📁 Directorio seleccionado: {directory}")

    def start_processing(self):
        """Start the renaming process in a separate thread."""
        base_dir = self.dir_path.text()
        api_key = self.api_key_input.text()
        
        if not base_dir:
            QMessageBox.warning(self, "Error", "Por favor selecciona un directorio")
            return
        
        if not os.path.isdir(base_dir):
            QMessageBox.warning(self, "Error", "El directorio especificado no existe")
            return
        
        if not api_key:
            QMessageBox.warning(self, "Error", "Por favor ingresa tu clave API de TMDB")
            return
        
        # Update API key and language in the imported module
        import RenameMyFolders
        RenameMyFolders.tmdb.api_key = api_key
        
        lang_map = {"es (Español)": "es", "en (Inglés)": "en", "fr (Francés)": "fr", "de (Alemán)": "de"}
        RenameMyFolders.tmdb.language = lang_map.get(self.lang_combo.currentText(), "es")
        
        self.output_text.append("\n" + "="*60)
        self.output_text.append("🎬 Iniciando procesamiento de carpetas...")
        self.output_text.append("="*60 + "\n")
        
        max_workers = self.workers_spinbox.value()
        self.worker_thread = WorkerThread(base_dir, max_workers)
        self.worker_thread.progress.connect(self.update_output)
        self.worker_thread.finished.connect(self.on_processing_finished)
        self.worker_thread.error.connect(self.on_processing_error)
        self.worker_thread.start()

    def update_output(self, text):
        """Update the output text area."""
        self.output_text.append(text)
        # Auto-scroll to bottom
        self.output_text.verticalScrollBar().setValue(
            self.output_text.verticalScrollBar().maximum()
        )

    def on_processing_finished(self):
        """Called when processing finishes."""
        self.output_text.append("\n" + "="*60)
        self.output_text.append("✅ Procesamiento finalizado")
        self.output_text.append("="*60)
        QMessageBox.information(self, "Éxito", "Procesamiento completado exitosamente")

    def on_processing_error(self, error_msg):
        """Called when an error occurs."""
        self.output_text.append(f"\n❌ {error_msg}")
        QMessageBox.critical(self, "Error", error_msg)

    def stop_processing(self):
        """Stop the processing thread."""
        if self.worker_thread and self.worker_thread.isRunning():
            self.worker_thread.quit()
            self.worker_thread.wait()
            self.output_text.append("\n⛔ Procesamiento detenido por el usuario")

    def clear_output(self):
        """Clear the output text area."""
        self.output_text.clear()


def main():
    """Main entry point for the application."""
    app = QApplication(sys.argv)
    window = RenameGUI()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
