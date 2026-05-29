# Plan de Implementación: Rediseño y Creación de 5 Pantallas de Administración (ReservPy)

Recrearemos las pantallas de administración del dueño de negocio para que coincidan exactamente con el diseño, la distribución y los indicadores de las capturas de pantalla de Reservly Argentina, adaptándolas al esquema de color **Teal / Cían premium de Paraguay** (`AppColors.primary`).

---

## Requiere Revisión del Usuario

> [!IMPORTANT]
> **Paleta de Colores**: Las capturas originales usan el color naranja (`#F97316`). Para ReservPy Paraguay, adaptaremos todos los botones, bordes, estados activos y barras de progreso al color **Teal premium** (`AppColors.primary`) del proyecto paraguayo. Esto mantendrá la identidad visual coherente.
>
> **Integración de la Navegación**: Para acceder fácilmente a las nuevas pantallas ("Clientes", "Servicios" y "Disponibilidad") tanto en web como en móviles sin alterar la barra de navegación inferior de 5 pestañas existente, las integraremos en la sección **"Gestión del negocio"** de la pestaña **"Mi Negocio"** (4ª pestaña). Al hacer clic en los respectivos botones de esa cuadrícula, se abrirán las pantallas completas.

---

## Cambios Propuestos

Crearemos y modificaremos las siguientes 5 pantallas en el código:

### 1. 📊 Pantalla de Dashboard (Rediseño)

#### [MODIFY] [dashboard_screen.dart](file:///c:/Users/pepeq/OneDrive/Desktop/reservas/lib/src/features/dashboard/dashboard_screen.dart)
Reescribiremos esta pantalla por completo para estructurarla igual a la captura:
* **Banner "Plan Free" Superior**: Un banner superior con fondo suave y barra de progreso que indica `Plan Free - 0/10 reservas este mes` junto con un botón naranja/teal de `Actualizar a Pro`.
* **4 Tarjetas de Métricas KPI**:
  1. `Turnos hoy` (0 confirmados)
  2. `Esta semana` (Confirmados)
  3. `₲ 0 Ingresos semana` (Confirmados solamente)
  4. `Pendientes` (Sin pendientes)
* **Diseño en Dos Columnas (Escritorio/Pantallas Anchas)**:
  * **Columna Izquierda (65% de ancho)**: Tarjeta para `Próximos turnos (Próximos 14 días)`. Contendrá un estado vacío elegante con ícono de calendario que dice `Todo al día. No hay turnos en los próximos 14 días.`.
  * **Columna Derecha (35% de ancho)**:
    * Tarjeta 1: `Agenda de hoy (miércoles, 27 de mayo)` con el mensaje `Sin turnos hoy. Disfrutá el día libre 🏝️`.
    * Tarjeta 2: `Esta semana (Reservas por día)` que muestra un minigráfico de barras horizontales/verticales (dibujado con contenedores de alturas variables) que represente Lun, Mar, Mié, Jue, Vie, Sáb, Dom.
  * *En pantallas móviles, las tarjetas se apilarán verticalmente de forma adaptativa.*

---

### 2. 👥 Pantalla de Clientes (Nueva)

#### [NEW] [clients_screen.dart](file:///c:/Users/pepeq/OneDrive/Desktop/reservas/lib/src/features/business/clients_screen.dart)
Una nueva pantalla para visualizar el listado de clientes que interactúan con el negocio:
* **Cabecera**: Título `Gestión de Clientes` con el subtítulo `Historial y estadísticas de tus clientes`.
* **Filtros y Búsqueda**:
  * Barra de búsqueda con bordes redondeados: `Buscar por nombre, email o teléfono...`.
  * Selector a la derecha: `Ordenar por: Última reserva`.
* **Contenido Principal**: Una tarjeta central de estado vacío con un ícono doble de usuarios y el texto `Sin clientes aún. Cuando recibas reservas, tus clientes aparecerán aquí.`.

---

### 3. ✂️ Pantalla de Servicios (Nueva)

#### [NEW] [services_screen.dart](file:///c:/Users/pepeq/OneDrive/Desktop/reservas/lib/src/features/business/services_screen.dart)
Una nueva pantalla para gestionar el catálogo de servicios del negocio:
* **Cabecera**: Título `Servicios` con el subtítulo `Gestioná los servicios que ofrecés` y un botón superior derecho `+ Nuevo servicio` (en color Teal sólido).
* **4 Tarjetas Pequeñas de Métricas**:
  1. `1 Servicios activos`
  2. `45 min Duración promedio`
  3. `₲ 60.000 Servicio más caro`
  4. `0 Servicios pausados`
* **Tabla/Lista de Servicios**: Diseñada con columnas claras para `SERVICIO`, `DURACIÓN`, `PRECIO` y `ACCIONES`.
  * Elemento precargado: `Corte de pelo` (Badge verde de "Activo", duración "45 min", precio "₲ 60.000" y acciones de "Editar" y "Pausar").
  * Tarjeta interactiva con borde punteado de `+ Agregar nuevo servicio` al final de la lista.

---

### 4. 📅 Pantalla de Disponibilidad (Nueva)

#### [NEW] [availability_screen.dart](file:///c:/Users/pepeq/OneDrive/Desktop/reservas/lib/src/features/business/availability_screen.dart)
Una nueva pantalla para configurar las reglas y horarios del negocio:
* **Cabecera**: Título `Disponibilidad` con el subtítulo `Configurá tus horarios de atención` y un botón superior derecho `+ Nuevo horario`.
* **Tarjeta de Horarios Semanales**: Muestra el listado de lunes a domingo con sus horarios asignados y botones para agregar, editar y eliminar:
  * Lunes a Viernes: `09:00 - 18:00 (pedrog)` con íconos de lápiz (editar) y papelera (eliminar), más el botón `+ Agregar`.
  * Sábado y Domingo: `Sin horario` con el botón `+ Agregar` habilitado.
* **Tarjeta de Excepciones**: Espacio inferior para fechas especiales con el texto: `No hay fechas específicas configuradas. Usá excepciones para fechas fuera de lo habitual o días no laborables.`.

---

### 5. 📆 Pantalla de Calendario (Rediseño de la Vista Semanal)

#### [MODIFY] [calendar_screen.dart](file:///c:/Users/pepeq/OneDrive/Desktop/reservas/lib/src/features/calendar/calendar_screen.dart)
Modificaremos la grilla semanal del calendario para que coincida perfectamente con la vista de tiempo por horas:
* **Cabecera**: Muestra el mes actual (`Mayo de 2026`), botones selectores de `Día` / `Semana`, el botón `Hoy` y las flechas de navegación `<` y `>`.
* **Grilla Semanal por Horas**:
  * Fila de días superiores: `LUN 25`, `MAR 26`, `MIÉ 27`, `JUE 28`, `VIE 29`, `SÁB 30`, `DOM 31`.
  * El día actual, miércoles (`MIÉ 27`), estará destacado con una columna de fondo suave Teal y el número `27` encerrado en un círculo Teal sólido.
  * Columna izquierda de horas desde las `07:00` hasta las `20:00` con líneas divisorias grises horizontales exactas.

---

## Configuración de Rutas y Enlaces

Registraremos los nuevos accesos en nuestro enrutador central y los vincularemos a las tarjetas de gestión de perfil:

#### [MODIFY] [app_router.dart](file:///c:/Users/pepeq/OneDrive/Desktop/reservas/lib/src/core/router/app_router.dart)
Registrar las siguientes rutas nuevas:
* `/business-clients` -> `ClientsScreen`
* `/business-services-manage` -> `ServicesScreen`
* `/business-availability` -> `AvailabilityScreen`

#### [MODIFY] [business_profile_screen.dart](file:///c:/Users/pepeq/OneDrive/Desktop/reservas/lib/src/features/business/business_profile_screen.dart)
Expandiremos la sección de acciones de negocio para que el dueño pueda abrir las 6 herramientas:
* `Equipo` -> `/business-employees`
* `Reportes` -> `/business-reports`
* `Recordatorios` -> `/business-reminders`
* `Clientes` -> `/business-clients` [NUEVO]
* `Servicios` -> `/business-services-manage` [NUEVO]
* `Disponibilidad` -> `/business-availability` [NUEVO]

---

## Plan de Verificación

### Análisis y Compilación
* Ejecutar `flutter analyze` para asegurar un código limpio y libre de errores de sintaxis.
* Probar la compilación y ejecución local en Flutter Web.

### Verificación Manual de Experiencia de Usuario (UX)
1. **Iniciar Sesión** como Dueño de Negocio (pedro).
2. **Dashboard (Pestaña 1)**: Validar la apariencia del Plan Free, las tarjetas de métricas y la distribución a dos columnas.
3. **Calendario (Pestaña 2)**: Cambiar a la vista "Semana" y verificar la cuadrícula de horas de 07:00 a 20:00, las líneas divisorias y el destaque del miércoles 27.
4. **Mi Negocio (Pestaña 4)**: Comprobar que en la sección "Gestión del negocio" aparezcan los accesos para Clientes, Servicios y Disponibilidad.
5. **Navegación**: Hacer clic en cada una de ellas y verificar que carguen de forma fluida con sus respectivos diseños y estados vacíos premium.
