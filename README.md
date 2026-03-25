# EduMetrics

**Sistema de evaluación interactiva para Educación Primaria**

Aplicación web desarrollada con Flutter que permite a profesores evaluar competencias de matemáticas y lengua en alumnos de 1º de Primaria (6-7 años) mediante actividades interactivas en pizarras digitales táctiles, con seguimiento estadístico individual y grupal en tiempo real.

> Proyecto de Fin de Ciclo (TFG) — Desarrollo de Aplicaciones Multiplataforma (DAM)
> Curso 2025/2026

---

## Características principales

### Sistema de actividades (10 tipos)

**Matemáticas:**
- Comparación numérica (mayor, menor, igual)
- Secuencias numéricas (completar la serie)
- Valor posicional (unidades y decenas)
- Sumas básicas
- Restas básicas

**Lengua:**
- Vocales perdidas (completar palabras)
- Contar sílabas
- Ordenar frases
- Mayúsculas (identificar uso correcto)
- Completar sílabas

Cada actividad incluye cronómetro invisible, variantes aleatorias para evitar copias, feedback visual inmediato y registro automático de resultados.

### Dos modos de uso

- **Modo Pizarra** — Interfaz táctil con botones grandes, optimizada para pantallas de 55"+ a distancia. Los alumnos seleccionan respuestas con teclados numéricos táctiles adaptados a su edad.
- **Modo Desktop** — Panel de gestión para el profesor: administración de alumnos, estadísticas y configuración.

### Estadísticas y análisis

- Gráficas individuales por alumno (% aciertos, evolución temporal, tiempo medio)
- Gráficas comparativas por clase (rendimiento medio, actividades con más dificultad)
- Filtros por periodo: semana, mes, trimestre o rango personalizado

### Gestión de alumnos

- CRUD completo con validación de datos
- 20 avatares genéricos (sin fotografías reales de menores)
- Organización por clases (1ºA, 1ºB, 1ºC, 2ºA, 2ºB, 2ºC)
- Baja temporal y eliminación permanente con borrado en cascada

---

## Seguridad y privacidad (RGPD/LOPDGDD)

La aplicación trabaja con datos de menores de edad. Se han implementado las siguientes medidas:

### Autenticación y acceso
- Login con email y contraseña verificada
- Verificación de email obligatoria
- Política de contraseñas robusta (8+ caracteres, mayúsculas, números, especiales)
- Registro de usuarios restringido (solo administrador)
- Cierre de sesión automático por inactividad (8 horas)
- Protección contra fuerza bruta (bloqueo temporal tras intentos fallidos)

### Protección de datos
- Firebase App Check con reCAPTCHA Enterprise
- Firestore Security Rules con validación de estructura de datos
- Aislamiento de datos por centro educativo (schoolId)
- Resultados inmutables (no pueden ser modificados una vez creados)
- Sanitización de entrada (solo letras, espacios y guiones en nombres)
- Sin fallbacks peligrosos en la configuración de centros
- Mensajes de error genéricos (sin exposición de datos internos)

### Cumplimiento RGPD
- Consentimiento parental obligatorio al registrar alumnos (Art. 7 LOPDGDD)
- Principio de minimización: solo se almacena nombre, clase y resultados
- Avatares genéricos en lugar de fotografías reales
- Derecho de acceso: consulta de datos desde Configuración
- Derecho de supresión: eliminación permanente de alumnos y todos sus datos
- Herramienta de retención de datos (purga automática por antigüedad)
- Política de privacidad integrada en la aplicación
- Logs de auditoría de todas las operaciones sobre datos de alumnos

### Despliegue seguro
- HTTPS obligatorio
- Cabeceras de seguridad HTTP: CSP, X-Frame-Options, X-Content-Type-Options
- Credenciales de Firebase excluidas del repositorio
- Historial de Git verificado (sin fugas de credenciales)

---

## Tecnologías

| Componente | Tecnología |
|-----------|-----------|
| Framework | Flutter 3.33+ (web) |
| Lenguaje | Dart |
| Backend | Firebase (Auth, Firestore, Hosting, App Check) |
| Gráficas | fl_chart |
| Hosting | Firebase Hosting |
| Control de versiones | Git / GitHub |

---

## Arquitectura

```
lib/
├── core/
│   ├── app_mode.dart              # Detección pizarra/desktop
│   ├── audit_service.dart         # Logs de auditoría RGPD
│   └── inactivity_service.dart    # Timeout de sesión
├── screens/
│   ├── dashboard/
│   │   ├── analytics_screen.dart          # Estadísticas (tabs alumno/clase)
│   │   ├── class_analytics_screen.dart    # Gráficas por clase
│   │   ├── student_analytics_screen.dart  # Gráficas por alumno
│   │   ├── students_management_screen.dart
│   │   ├── add_student_screen.dart
│   │   └── edit_student_screen.dart
│   ├── pizarra/
│   │   ├── base_activity_screen.dart      # Clase abstracta (patrón herencia)
│   │   ├── comparison_activity_screen.dart
│   │   ├── sequence_activity_screen.dart
│   │   ├── place_value_activity_screen.dart
│   │   ├── addition_activity_screen.dart
│   │   ├── subtraction_activity_screen.dart
│   │   ├── missing_vowels_activity_screen.dart
│   │   ├── syllable_count_activity_screen.dart
│   │   ├── sentence_order_activity_screen.dart
│   │   ├── capitalization_activity_screen.dart
│   │   ├── syllable_complete_activity_screen.dart
│   │   ├── student_selector_screen.dart
│   │   └── activity_summary_screen.dart
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── email_verification_screen.dart
│   ├── settings_screen.dart
│   └── privacy_policy_screen.dart
├── main.dart
└── firebase_options.dart          # Excluido de Git
```

**Patrón de diseño:** Todas las actividades heredan de `BaseActivityScreen`, que gestiona cronómetro, almacenamiento de resultados, feedback visual y navegación. Cada actividad solo implementa la generación de preguntas, la UI y la validación de respuestas.

---

## Configuración del proyecto

### Requisitos previos

- Flutter SDK 3.33+
- Node.js (para Firebase CLI)
- Cuenta de Firebase

### Instalación

1. **Clonar el repositorio:**
```bash
git clone https://github.com/TU_USUARIO/edumetrics.git
cd edumetrics
```

2. **Instalar dependencias:**
```bash
flutter pub get
```

3. **Configurar Firebase:**
    - Crear un proyecto en [Firebase Console](https://console.firebase.google.com)
    - Activar Authentication (email/contraseña)
    - Crear base de datos Firestore
    - Generar `firebase_options.dart`:
```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

4. **Crear índices compuestos en Firestore:**

| Colección | Campos |
|-----------|--------|
| students | schoolId ↑, isActive ↑, name ↑ |
| results | schoolId ↑, studentId ↑, timestamp ↑ |
| results | studentId ↑, timestamp ↑ |

5. **Ejecutar en desarrollo:**
```bash
flutter run -d chrome
```

6. **Desplegar en producción:**
```bash
flutter build web --release
firebase deploy --only hosting
```

### Crear el primer usuario

Con el registro público deshabilitado, crear usuarios desde Firebase Console → Authentication → Añadir usuario. Después, crear el documento del usuario en Firestore:

```
Colección: users
Documento ID: [uid del usuario creado]
Campos:
  - schoolId: "nombre-del-centro"
  - name: "Nombre del profesor"
```

---

## Capturas de pantalla

*Añadir capturas de: login, selector de alumnos, actividad en pizarra, estadísticas, modo oscuro, configuración.*

---

## Licencia

Este proyecto ha sido desarrollado como Trabajo de Fin de Grado. Todos los derechos reservados.

---

## Contacto

Desarrollado por **Víctor Marcos** — victormarcosp@gmail.com