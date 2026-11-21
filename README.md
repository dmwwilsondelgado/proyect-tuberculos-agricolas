# React + Vite

This template provides a minimal setup to get React working in Vite with HMR and some ESLint rules.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Oxc](https://oxc.rs)
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/)

## React Compiler

The React Compiler is not enabled on this template because of its impact on dev & build performances. To add it, see [this documentation](https://react.dev/learn/react-compiler/installation).

## Expanding the ESLint configuration

If you are developing a production application, we recommend using TypeScript with type-aware lint rules enabled. Check out the [TS template](https://github.com/vitejs/vite/tree/main/packages/create-vite/template-react-ts) for information on how to integrate TypeScript and [`typescript-eslint`](https://typescript-eslint.io) in your project.



E-COMMERCE AGRICOLA PARA VENTA DE PRODUCTOS DE FINCA A TU MESA


DESCRIPCION GENERAL DEL PROYECTO:
Objetivo: Desarrollar una plataforma web intuitiva que permita  a los productores  agrícolas gestionar su inventario  de cosecha ( frutas, tubérculos, derivados del cacao como el chocolate entre otros indefinidos como el aguacate) y ofrecer un canal directo de venta a los compradores.

Requisitos Funcionales (RF)
•	RF-01 (Visualización de Catálogo): El sistema debe proveer una interfaz pública en React que liste los productos agrícolas disponibles, mostrando únicamente aquellos que se encuentren con estado activo o disponible.
•	RF-02 (Detalle y Filtrado de Productos): Cada producto debe mostrar su nombre, categoría, descripción, precio en pesos colombianos (COP), imagen y un indicador visual de disponibilidad, permitiendo al usuario filtrar por categorías o buscar por nombre.
•	RF-03 (Gestión de Productos - CRUD): El administrador de la finca debe poder realizar operaciones CRUD (Crear, Leer, Actualizar, Eliminar) sobre los productos a través de su panel de control utilizando el backend.
•	RF-04 (Control de Disponibilidad / Pausa): Cada producto en la base de datos debe contar con un estado booleano o de control (ej. Disponible / Agotado o Activo / Pausado), permitiendo al administrador ocultar o mostrar un producto en la tienda web cuando finalice o inicie una cosecha, sin necesidad de calcular un inventario numérico complejo.
•	RF-05 (Gestión de Carrito y Pedidos): El usuario final debe poder agregar los productos deseados al carrito de compras, calcular el costo total del pedido y enviar la orden de compra a la base de datos.
•	RF-06 (Visualización de Pedidos para el Administrador): El administrador debe contar con una sección privada para consultar el listado de los pedidos generados por los clientes en la plataforma.









Requisitos No Funcionales (RNF)
•	RNF-01 (Arquitectura del Software): El backend debe estructurarse estrictamente bajo el patrón Modelo-Vista-Controlador (MVC), separando la lógica de las rutas, los controladores y la conexión con la base de datos relacional.
•	RNF-02 (Rendimiento y Usabilidad): La interfaz desarrollada en React debe ser responsiva y ofrecer una navegación fluida tanto en dispositivos móviles como en computadores de escritorio.
•	RNF-03 (Persistencia de Datos): La información referente a categorías, productos, estados de disponibilidad y pedidos debe almacenarse de forma segura y relacional en tablas de PostgreSQL.
•	RNF-04 (Pruebas de Backend): Las rutas de la API expuestas por el servidor en Node.js deben ser verificadas, probadas y validadas mediante herramientas externas como Postman, comprobando códigos de estado HTTP y la correcta manipulación de datos.

