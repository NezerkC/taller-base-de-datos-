// =============================================================================
// BDY1103 - Taller de Base de Datos - Evaluación Parcial 3 (EP3)
// Caso de Estudio: Sonido Vivo (Tienda de Instrumentos Musicales - Viña del Mar)
// Motor: MongoDB 7.x (mongosh)
// Arquitectura: Persistencia Políglota (Oracle 19c Core ACID + MongoDB NoSQL)
// Integrantes: Dylan Sandoval – Víctor Martínez – Danilo Sepúlveda
// =============================================================================

// Seleccionar base de datos (equivalente en REPL interactivo a: use sonido_vivo;)
db = db.getSiblingDB("sonido_vivo");

print("=========================================================================");
print("   SONIDO VIVO - INICIALIZACION Y VERIFICACION NOSQL (MONGODB 7.x)");
print("=========================================================================");

// =============================================================================
// FASE 1: LIMPIEZA PREVENTIVA, VALIDADORES ($jsonSchema) E INDICES
// =============================================================================

db.productos.drop();
db.pedidos.drop();
db.resenas_clientes.drop();

// 1.1 Colección 'productos' (Catálogo Polimórfico con $jsonSchema estricto)
db.createCollection("productos", {
  validationLevel: "strict",
  validationAction: "error",
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: [
        "codigo",
        "nombre",
        "marca",
        "categoria",
        "precio",
        "stock",
        "stock_critico",
        "activo",
        "especificaciones"
      ],
      properties: {
        codigo: {
          bsonType: "string",
          pattern: "^[A-Z]{2}[0-9]{3}$",
          description: "Código único formato LL999 (ej. GE001) - Obligatorio"
        },
        nombre: {
          bsonType: "string",
          minLength: 3,
          description: "Nombre del instrumento o accesorio - Obligatorio"
        },
        marca: {
          bsonType: "string",
          minLength: 2,
          description: "Fabricante o marca - Obligatorio"
        },
        modelo: {
          bsonType: "string",
          description: "Modelo comercial"
        },
        categoria: {
          enum: [
            "Guitarras Acústicas",
            "Guitarras Eléctricas",
            "Bajos Eléctricos",
            "Teclados y Pianos",
            "Audio Profesional",
            "Accesorios"
          ],
          description: "Categoría oficial de Sonido Vivo - Obligatorio"
        },
        precio: {
          bsonType: ["int", "long", "double", "decimal"],
          minimum: 1,
          description: "Precio unitario en CLP mayor o igual a 1 - Obligatorio"
        },
        stock: {
          bsonType: "int",
          minimum: 0,
          description: "Stock físico disponible no negativo - Obligatorio"
        },
        stock_critico: {
          bsonType: "int",
          minimum: 0,
          description: "Umbral de alerta de reposición - Obligatorio"
        },
        activo: {
          bsonType: "bool",
          description: "Disponibilidad visible en catálogo web - Obligatorio"
        },
        especificaciones: {
          bsonType: "object",
          description: "Subdocumento polimórfico de atributos técnicos - Obligatorio"
        },
        etiquetas: {
          bsonType: "array",
          items: { bsonType: "string" },
          description: "Arreglo de etiquetas de búsqueda (índice multikey)"
        }
      }
    }
  }
});

// 1.2 Colección 'pedidos' (Patrón Embebido: lectura atómica + inmutabilidad)
db.createCollection("pedidos", {
  validationLevel: "strict",
  validationAction: "error",
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: [
        "codigo_pedido",
        "nro_boleta",
        "fecha",
        "estado",
        "cliente",
        "items",
        "subtotal",
        "descuento",
        "total"
      ],
      properties: {
        codigo_pedido: {
          bsonType: "string",
          pattern: "^PED-[0-9]{4}-[0-9]{4}$",
          description: "Identificador legible del pedido web - Obligatorio"
        },
        nro_boleta: {
          bsonType: "int",
          minimum: 1,
          description: "Número correlativo de boleta sincronizado con Oracle"
        },
        fecha: {
          bsonType: "date",
          description: "Fecha y hora de emisión del pedido"
        },
        estado: {
          enum: ["PENDIENTE", "PAGADO", "COMPLETADO", "CANCELADO"],
          description: "Estado del ciclo de vida del pedido"
        },
        cliente: {
          bsonType: "object",
          required: ["rut", "nombre", "email", "comuna", "tipo_cliente"],
          properties: {
            rut: { bsonType: "string" },
            nombre: { bsonType: "string" },
            email: { bsonType: "string" },
            comuna: { bsonType: "string" },
            tipo_cliente: { enum: ["ESTANDAR", "FRECUENTE", "PREMIUM"] }
          }
        },
        items: {
          bsonType: "array",
          minItems: 1,
          items: {
            bsonType: "object",
            required: ["codigo", "nombre", "cantidad", "precio_unitario", "subtotal"],
            properties: {
              codigo: { bsonType: "string" },
              nombre: { bsonType: "string" },
              cantidad: { bsonType: "int", minimum: 1 },
              precio_unitario: {
                bsonType: ["int", "long", "double", "decimal"],
                minimum: 1
              },
              subtotal: {
                bsonType: ["int", "long", "double", "decimal"],
                minimum: 1
              }
            }
          }
        },
        subtotal: { bsonType: ["int", "long", "double", "decimal"], minimum: 0 },
        descuento: { bsonType: ["int", "long", "double", "decimal"], minimum: 0 },
        total: { bsonType: ["int", "long", "double", "decimal"], minimum: 0 }
      }
    }
  }
});

// 1.3 Colección 'resenas_clientes' (Patrón Referenciado: evita Unbounded Growth > 16 MB)
db.createCollection("resenas_clientes", {
  validationLevel: "strict",
  validationAction: "error",
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: [
        "codigo_producto",
        "rut_cliente",
        "nombre_cliente",
        "calificacion",
        "comentario",
        "fecha",
        "compra_verificada"
      ],
      properties: {
        codigo_producto: {
          bsonType: "string",
          pattern: "^[A-Z]{2}[0-9]{3}$",
          description: "Referencia lógica al campo productos.codigo"
        },
        rut_cliente: { bsonType: "string" },
        nombre_cliente: { bsonType: "string" },
        calificacion: {
          bsonType: "int",
          minimum: 1,
          maximum: 5,
          description: "Evaluación de 1 a 5 estrellas"
        },
        comentario: { bsonType: "string", minLength: 5 },
        fecha: { bsonType: "date" },
        compra_verificada: { bsonType: "bool" }
      }
    }
  }
});

// 1.4 Creación de índices estratégicos (evita COLLSCAN)
db.productos.createIndex({ codigo: 1 }, { unique: true, name: "idx_prod_codigo" });
db.productos.createIndex({ categoria: 1, precio: -1 }, { name: "idx_prod_cat_precio" });
db.productos.createIndex({ etiquetas: 1 }, { name: "idx_prod_etiquetas_multikey" });
db.pedidos.createIndex({ codigo_pedido: 1 }, { unique: true, name: "idx_ped_codigo" });
db.pedidos.createIndex({ "cliente.rut": 1, fecha: -1 }, { name: "idx_ped_cliente_fecha" });
db.resenas_clientes.createIndex({ codigo_producto: 1, calificacion: -1 }, { name: "idx_res_producto" });

print("[FASE 1 OK] Colecciones, validadores $jsonSchema e indices creados.");

// =============================================================================
// FASE 2: OPERACIONES CREATE (insertMany / insertOne)
// =============================================================================

// 2.1 Catálogo inicial de 10 productos (homologados con ep2_sonido_vivo.sql)
db.productos.insertMany([
  {
    codigo: "GA001",
    nombre: "Guitarra Acústica Folk F310",
    marca: "Yamaha",
    modelo: "F310",
    categoria: "Guitarras Acústicas",
    precio: NumberDecimal("129990"),
    stock: NumberInt(8),
    stock_critico: NumberInt(3),
    activo: true,
    especificaciones: {
      tipo: "Acústica Folk",
      tapa: "Abeto",
      aros_fondo: "Meranti",
      diapason: "Palisandro",
      trastes: 20,
      cuerdas: 6,
      color: "Natural"
    },
    etiquetas: ["yamaha", "acustica", "folk", "principiante"]
  },
  {
    codigo: "GA002",
    nombre: "Guitarra Acústica Dreadnought CD-60S",
    marca: "Fender",
    modelo: "CD-60S",
    categoria: "Guitarras Acústicas",
    precio: NumberDecimal("189990"),
    stock: NumberInt(5),
    stock_critico: NumberInt(3),
    activo: true,
    especificaciones: {
      tipo: "Dreadnought",
      tapa: "Abeto macizo",
      aros_fondo: "Caoba",
      diapason: "Nogal",
      trastes: 20,
      cuerdas: 6,
      color: "Natural Gloss"
    },
    etiquetas: ["fender", "acustica", "dreadnought", "tapa-maciza"]
  },
  {
    codigo: "GE001",
    nombre: "Guitarra Eléctrica Player Stratocaster",
    marca: "Fender",
    modelo: "Player HSS",
    categoria: "Guitarras Eléctricas",
    precio: NumberDecimal("749990"),
    stock: NumberInt(4),
    stock_critico: NumberInt(2),
    activo: true,
    especificaciones: {
      tipo: "Eléctrica",
      cuerpo: "Aliso",
      diapason: "Arce",
      trastes: 22,
      configuracion_pastillas: "HSS (Humbucker + 2 Single-Coil)",
      puente: "Trémolo sincronizado de 2 puntos",
      color: "3-Color Sunburst"
    },
    etiquetas: ["fender", "stratocaster", "electrica", "hss"]
  },
  {
    codigo: "GE002",
    nombre: "Guitarra Eléctrica Les Paul Tribute",
    marca: "Gibson",
    modelo: "Tribute Satin",
    categoria: "Guitarras Eléctricas",
    precio: NumberDecimal("1199990"),
    stock: NumberInt(2),
    stock_critico: NumberInt(1),
    activo: true,
    especificaciones: {
      tipo: "Eléctrica",
      cuerpo: "Caoba con tapa de arce",
      diapason: "Palisandro",
      trastes: 22,
      configuracion_pastillas: "HH (490R y 490T Humbucker)",
      peso_kg: 3.9,
      color: "Honeyburst Satin"
    },
    etiquetas: ["gibson", "lespaul", "electrica", "humbucker", "usa"]
  },
  {
    codigo: "BA001",
    nombre: "Bajo Eléctrico Player Precision Bass",
    marca: "Fender",
    modelo: "P-Bass 4C",
    categoria: "Bajos Eléctricos",
    precio: NumberDecimal("799990"),
    stock: NumberInt(3),
    stock_critico: NumberInt(2),
    activo: true,
    especificaciones: {
      tipo: "Bajo Pasivo",
      cuerpo: "Aliso",
      diapason: "Pau Ferro",
      cuerdas: 4,
      trastes: 20,
      pastilla: "Player Series Alnico 5 Split Single-Coil",
      escala_pulgadas: 34
    },
    etiquetas: ["fender", "bajo", "precision", "4-cuerdas"]
  },
  {
    codigo: "TE001",
    nombre: "Piano Digital P-45B 88 Teclas",
    marca: "Yamaha",
    modelo: "P-45B",
    categoria: "Teclados y Pianos",
    precio: NumberDecimal("459990"),
    stock: NumberInt(6),
    stock_critico: NumberInt(2),
    activo: true,
    especificaciones: {
      tipo: "Piano Digital Portátil",
      teclas: 88,
      accion_teclado: "GHS (Graded Hammer Standard)",
      polifonia_notas: 64,
      sonidos_integrados: 10,
      conectividad: ["USB to Host", "Salida Auriculares TRS"],
      peso_kg: 11.5
    },
    etiquetas: ["yamaha", "piano", "88-teclas", "contrapesado"]
  },
  {
    codigo: "AP001",
    nombre: "Micrófono Dinámico Vocal SM58",
    marca: "Shure",
    modelo: "SM58-LC",
    categoria: "Audio Profesional",
    precio: NumberDecimal("114990"),
    stock: NumberInt(12),
    stock_critico: NumberInt(4),
    activo: true,
    especificaciones: {
      tipo: "Micrófono Dinámico Vocal",
      patron_polar: "Cardioide",
      respuesta_frecuencia: "50 Hz - 15 kHz",
      impedancia_ohm: 150,
      conector: "XLR 3 pines",
      filtro_antipop_integrado: true
    },
    etiquetas: ["shure", "microfono", "escenario", "estudio"]
  },
  {
    codigo: "AP002",
    nombre: "Interfaz de Audio Scarlett 2i2 4th Gen",
    marca: "Focusrite",
    modelo: "2i2 Gen4",
    categoria: "Audio Profesional",
    precio: NumberDecimal("199990"),
    stock: NumberInt(7),
    stock_critico: NumberInt(3),
    activo: true,
    especificaciones: {
      tipo: "Interfaz de Audio USB-C",
      canales_entrada: 2,
      canales_salida: 2,
      preamplificadores: 2,
      resolucion_max: "24-bit / 192 kHz",
      phantom_power_48v: true,
      modo_air: true
    },
    etiquetas: ["focusrite", "interfaz", "grabacion", "estudio"]
  },
  {
    codigo: "AC001",
    nombre: "Cuerdas Guitarra Eléctrica 010-046",
    marca: "Ernie Ball",
    modelo: "Regular Slinky",
    categoria: "Accesorios",
    precio: NumberDecimal("8990"),
    stock: NumberInt(35),
    stock_critico: NumberInt(10),
    activo: true,
    especificaciones: {
      tipo: "Encordado Eléctrica",
      calibre: "010-013-017-026-036-046",
      material_entorchado: "Acero niquelado",
      origen: "EE.UU."
    },
    etiquetas: ["ernie-ball", "cuerdas", "accesorios", "010"]
  },
  {
    codigo: "AC002",
    nombre: "Baquetas American Classic 5A Madera",
    marca: "Vic Firth",
    modelo: "5A",
    categoria: "Accesorios",
    precio: NumberDecimal("12990"),
    stock: NumberInt(20),
    stock_critico: NumberInt(5),
    activo: true,
    especificaciones: {
      tipo: "Baquetas de Batería",
      medida: "5A",
      madera: "Hickory americano",
      punta: "Madera tipo lágrima",
      longitud_cm: 40.64
    },
    etiquetas: ["vic-firth", "baquetas", "percusion", "5a"]
  }
]);

// 2.2 Inserción de 5 pedidos históricos/activos con ítems embebidos
db.pedidos.insertMany([
  {
    codigo_pedido: "PED-2026-5001",
    nro_boleta: NumberInt(5001),
    fecha: new Date("2026-09-01T11:15:00Z"),
    estado: "COMPLETADO",
    cliente: {
      rut: "15.482.913-4",
      nombre: "Carlos Valenzuela Pinto",
      email: "carlos.valenzuela@gmail.com",
      comuna: "Viña del Mar",
      tipo_cliente: "PREMIUM"
    },
    items: [
      {
        codigo: "GE001",
        nombre: "Guitarra Eléctrica Player Stratocaster",
        cantidad: NumberInt(1),
        precio_unitario: NumberDecimal("749990"),
        subtotal: NumberDecimal("749990")
      },
      {
        codigo: "AP001",
        nombre: "Micrófono Dinámico Vocal SM58",
        cantidad: NumberInt(1),
        precio_unitario: NumberDecimal("114990"),
        subtotal: NumberDecimal("114990")
      }
    ],
    subtotal: NumberDecimal("864980"),
    descuento: NumberDecimal("0"),
    total: NumberDecimal("864980")
  },
  {
    codigo_pedido: "PED-2026-5002",
    nro_boleta: NumberInt(5002),
    fecha: new Date("2026-09-05T16:40:00Z"),
    estado: "COMPLETADO",
    cliente: {
      rut: "15.482.913-4",
      nombre: "Carlos Valenzuela Pinto",
      email: "carlos.valenzuela@gmail.com",
      comuna: "Viña del Mar",
      tipo_cliente: "PREMIUM"
    },
    items: [
      {
        codigo: "AC001",
        nombre: "Cuerdas Guitarra Eléctrica 010-046",
        cantidad: NumberInt(3),
        precio_unitario: NumberDecimal("8990"),
        subtotal: NumberDecimal("26970")
      }
    ],
    subtotal: NumberDecimal("26970"),
    descuento: NumberDecimal("0"),
    total: NumberDecimal("26970")
  },
  {
    codigo_pedido: "PED-2026-5003",
    nro_boleta: NumberInt(5003),
    fecha: new Date("2026-09-03T10:05:00Z"),
    estado: "PAGADO",
    cliente: {
      rut: "18.324.571-K",
      nombre: "Valentina Morales Soto",
      email: "vale.morales@outlook.com",
      comuna: "Valparaíso",
      tipo_cliente: "FRECUENTE"
    },
    items: [
      {
        codigo: "TE001",
        nombre: "Piano Digital P-45B 88 Teclas",
        cantidad: NumberInt(1),
        precio_unitario: NumberDecimal("459990"),
        subtotal: NumberDecimal("459990")
      }
    ],
    subtotal: NumberDecimal("459990"),
    descuento: NumberDecimal("0"),
    total: NumberDecimal("459990")
  },
  {
    codigo_pedido: "PED-2026-5004",
    nro_boleta: NumberInt(5004),
    fecha: new Date("2026-09-06T19:20:00Z"),
    estado: "PENDIENTE",
    cliente: {
      rut: "19.874.120-2",
      nombre: "Matías Lagos Herrera",
      email: "matias.lagos@gmail.com",
      comuna: "Concón",
      tipo_cliente: "ESTANDAR"
    },
    items: [
      {
        codigo: "GA001",
        nombre: "Guitarra Acústica Folk F310",
        cantidad: NumberInt(1),
        precio_unitario: NumberDecimal("129990"),
        subtotal: NumberDecimal("129990")
      },
      {
        codigo: "AC002",
        nombre: "Baquetas American Classic 5A Madera",
        cantidad: NumberInt(2),
        precio_unitario: NumberDecimal("12990"),
        subtotal: NumberDecimal("25980")
      }
    ],
    subtotal: NumberDecimal("155970"),
    descuento: NumberDecimal("0"),
    total: NumberDecimal("155970")
  },
  {
    codigo_pedido: "PED-2026-5005",
    nro_boleta: NumberInt(5005),
    fecha: new Date("2026-09-08T13:50:00Z"),
    estado: "COMPLETADO",
    cliente: {
      rut: "14.102.345-8",
      nombre: "Camila Rojas Benítez",
      email: "camila.rojas@vtr.net",
      comuna: "Quilpué",
      tipo_cliente: "PREMIUM"
    },
    items: [
      {
        codigo: "BA001",
        nombre: "Bajo Eléctrico Player Precision Bass",
        cantidad: NumberInt(1),
        precio_unitario: NumberDecimal("799990"),
        subtotal: NumberDecimal("799990")
      },
      {
        codigo: "AP002",
        nombre: "Interfaz de Audio Scarlett 2i2 4th Gen",
        cantidad: NumberInt(1),
        precio_unitario: NumberDecimal("199990"),
        subtotal: NumberDecimal("199990")
      }
    ],
    subtotal: NumberDecimal("999980"),
    descuento: NumberDecimal("0"),
    total: NumberDecimal("999980")
  }
]);

// 2.3 Inserción de 6 reseñas referenciadas por codigo_producto
db.resenas_clientes.insertMany([
  {
    codigo_producto: "GE001",
    rut_cliente: "15.482.913-4",
    nombre_cliente: "Carlos Valenzuela Pinto",
    calificacion: NumberInt(5),
    comentario: "Versatilidad excelente gracias a la configuración HSS.",
    fecha: new Date("2026-09-10T15:00:00Z"),
    compra_verificada: true
  },
  {
    codigo_producto: "GE001",
    rut_cliente: "20.145.892-1",
    nombre_cliente: "Ignacio Garrido Ruiz",
    calificacion: NumberInt(4),
    comentario: "Muy cómoda en el mástil de arce, calibración de fábrica correcta.",
    fecha: new Date("2026-09-12T18:30:00Z"),
    compra_verificada: false
  },
  {
    codigo_producto: "GE002",
    rut_cliente: "14.102.345-8",
    nombre_cliente: "Camila Rojas Benítez",
    calificacion: NumberInt(5),
    comentario: "Sustain increíble y acabado satinado muy cómodo.",
    fecha: new Date("2026-09-14T12:10:00Z"),
    compra_verificada: true
  },
  {
    codigo_producto: "AP001",
    rut_cliente: "15.482.913-4",
    nombre_cliente: "Carlos Valenzuela Pinto",
    calificacion: NumberInt(5),
    comentario: "Indestructible para ensayos y presentaciones en vivo.",
    fecha: new Date("2026-09-11T20:00:00Z"),
    compra_verificada: true
  },
  {
    codigo_producto: "AP002",
    rut_cliente: "14.102.345-8",
    nombre_cliente: "Camila Rojas Benítez",
    calificacion: NumberInt(5),
    comentario: "Latencia mínima y el modo Air da brillo a las voces.",
    fecha: new Date("2026-09-15T09:45:00Z"),
    compra_verificada: true
  },
  {
    codigo_producto: "TE001",
    rut_cliente: "18.324.571-K",
    nombre_cliente: "Valentina Morales Soto",
    calificacion: NumberInt(4),
    comentario: "Teclado contrapesado ideal para estudiar piano clásico en casa.",
    fecha: new Date("2026-09-13T17:25:00Z"),
    compra_verificada: true
  }
]);

// 2.4 Inserción unitaria (insertOne) de producto temporal para probar ciclo de vida
db.productos.insertOne({
  codigo: "TE002",
  nombre: "Sintetizador Roland JUNO-DS61",
  marca: "Roland",
  modelo: "JUNO-DS61",
  categoria: "Teclados y Pianos",
  precio: NumberDecimal("789990"),
  stock: NumberInt(2),
  stock_critico: NumberInt(1),
  activo: true,
  especificaciones: {
    tipo: "Sintetizador Workstation",
    teclas: 61,
    polifonia_notas: 128,
    peso_kg: 5.3
  },
  etiquetas: ["roland", "sintetizador", "escenario"]
});

print("[FASE 2 OK] Documentos insertados (11 productos, 5 pedidos, 6 resenas).");

// =============================================================================
// FASE 3: OPERACIONES READ (Dot Notation, Filtros Compuestos, $elemMatch, Multikey)
// =============================================================================

print("\n--- Consulta 3.1: Dot Notation sobre subdocumento polimorfico ---");
printjson(
  db.productos.find(
    {
      $or: [
        { "especificaciones.trastes": 22 },
        { "especificaciones.patron_polar": "Cardioide" }
      ]
    },
    { codigo: 1, nombre: 1, categoria: 1, "especificaciones.trastes": 1, "especificaciones.patron_polar": 1, _id: 0 }
  ).toArray()
);

print("\n--- Consulta 3.2: Filtros compuestos ($in + $gt) ordenados por precio ---");
printjson(
  db.productos.find(
    {
      categoria: { $in: ["Guitarras Eléctricas", "Audio Profesional"] },
      precio: { $gt: NumberDecimal("150000") }
    },
    { codigo: 1, nombre: 1, categoria: 1, precio: 1, _id: 0 }
  ).sort({ precio: -1 }).toArray()
);

print("\n--- Consulta 3.3: $elemMatch sobre arreglo embebido 'items' ---");
// Evita falsos positivos: garantiza que AMBAS condiciones se cumplan en el MISMO subdocumento del array
printjson(
  db.pedidos.find(
    {
      items: {
        $elemMatch: {
          cantidad: { $gte: 2 },
          subtotal: { $gte: NumberDecimal("20000") }
        }
      }
    },
    { codigo_pedido: 1, "cliente.nombre": 1, items: 1, total: 1, _id: 0 }
  ).toArray()
);

print("\n--- Consulta 3.4: Indice Multikey sobre arreglo 'etiquetas' ---");
printjson(
  db.productos.find(
    { etiquetas: { $in: ["estudio", "fender"] } },
    { codigo: 1, nombre: 1, etiquetas: 1, _id: 0 }
  ).toArray()
);

// =============================================================================
// FASE 4: OPERACIONES UPDATE (Actualizaciones Atómicas y Arreglos)
// =============================================================================

// 4.1 Descuento atómico de stock con condición de guarda ($gte + $inc)
// Evita Race Conditions cuando dos clientes compran las últimas unidades en paralelo
const resStock = db.productos.updateOne(
  { codigo: "AP001", stock: { $gte: 2 } },
  { $inc: { stock: NumberInt(-2) } }
);
print("\n[UPDATE 4.1] Stock descontado en AP001 (matched=" + resStock.matchedCount + ", modified=" + resStock.modifiedCount + ")");

// 4.2 Agregar etiqueta sin duplicados ($addToSet)
const resTag = db.productos.updateOne(
  { codigo: "GE001" },
  { $addToSet: { etiquetas: "alta-demanda" } }
);
print("[UPDATE 4.2] Etiqueta agregada en GE001 con $addToSet (modified=" + resTag.modifiedCount + ")");

// 4.3 Agregar ítem a pedido PENDIENTE ($push) e incrementar totales ($inc)
const resPedido = db.pedidos.updateOne(
  { codigo_pedido: "PED-2026-5004", estado: "PENDIENTE" },
  {
    $push: {
      items: {
        codigo: "AC001",
        nombre: "Cuerdas Guitarra Eléctrica 010-046",
        cantidad: NumberInt(2),
        precio_unitario: NumberDecimal("8990"),
        subtotal: NumberDecimal("17980")
      }
    },
    $inc: {
      subtotal: NumberDecimal("17980"),
      total: NumberDecimal("17980")
    }
  }
);
print("[UPDATE 4.3] Item agregado a PED-2026-5004 con $push + $inc (modified=" + resPedido.modifiedCount + ")");

// 4.4 Actualización masiva de garantía en categoría Audio Profesional (updateMany)
const resGarantia = db.productos.updateMany(
  { categoria: "Audio Profesional" },
  { $set: { activo: true, "especificaciones.garantia_meses": NumberInt(12) } }
);
print("[UPDATE 4.4] Garantia 12 meses asignada a Audio Profesional (modified=" + resGarantia.modifiedCount + ")");

// =============================================================================
// FASE 5: OPERACIONES DELETE (deleteOne / deleteMany)
// =============================================================================

// 5.1 Eliminar producto de prueba descontinuado (TE002)
const resDelProd = db.productos.deleteOne({ codigo: "TE002" });
print("\n[DELETE 5.1] Producto TE002 eliminado (deletedCount=" + resDelProd.deletedCount + ")");

// 5.2 Insertar pedido temporal CANCELADO y depurarlo con deleteMany
db.pedidos.insertOne({
  codigo_pedido: "PED-2026-9999",
  nro_boleta: NumberInt(9999),
  fecha: new Date("2026-09-20T10:00:00Z"),
  estado: "CANCELADO",
  cliente: {
    rut: "20.145.892-1",
    nombre: "Ignacio Garrido Ruiz",
    email: "ignacio.garrido@gmail.com",
    comuna: "Viña del Mar",
    tipo_cliente: "ESTANDAR"
  },
  items: [
    {
      codigo: "AC001",
      nombre: "Cuerdas Guitarra Eléctrica 010-046",
      cantidad: NumberInt(1),
      precio_unitario: NumberDecimal("8990"),
      subtotal: NumberDecimal("8990")
    }
  ],
  subtotal: NumberDecimal("8990"),
  descuento: NumberDecimal("0"),
  total: NumberDecimal("8990")
});
const resDelPed = db.pedidos.deleteMany({ estado: "CANCELADO" });
print("[DELETE 5.2] Pedidos CANCELADO depurados con deleteMany (deletedCount=" + resDelPed.deletedCount + ")");

// =============================================================================
// FASE 6: PRUEBA DE INTEGRIDAD Y GOBERNANZA ($jsonSchema NEGATIVE TEST)
// =============================================================================

print("\n--- Prueba 6.1: Rechazo de documento invalido por $jsonSchema ---");
try {
  db.productos.insertOne({
    codigo: "BAD01",
    nombre: "Instrumento Corrupto",
    marca: "SinMarca",
    categoria: "Cuerdas",
    precio: NumberDecimal("-5000"),
    stock: NumberInt(-1),
    stock_critico: NumberInt(1),
    activo: true,
    especificaciones: {}
  });
  print("[ERROR] El documento invalido fue aceptado inesperadamente.");
} catch (e) {
  print("[OK] Validador $jsonSchema rechazo documento invalido correctamente: " + e.message);
}

// =============================================================================
// FASE 7: ANALITICA DE NEGOCIO CON AGGREGATION PIPELINE
// =============================================================================

print("\n--- Pipeline 7.1: Ranking de productos facturados ($match -> $unwind -> $group -> $sort) ---");
printjson(
  db.pedidos.aggregate([
    { $match: { estado: { $in: ["COMPLETADO", "PAGADO"] } } },
    { $unwind: "$items" },
    {
      $group: {
        _id: "$items.codigo",
        nombre_producto: { $first: "$items.nombre" },
        unidades_vendidas: { $sum: "$items.cantidad" },
        ingresos_acumulados: { $sum: "$items.subtotal" }
      }
    },
    { $sort: { ingresos_acumulados: -1 } }
  ]).toArray()
);

print("\n--- Pipeline 7.2: Promedio de resenas por producto ($lookup -> $unwind -> $group -> $project -> $sort) ---");
printjson(
  db.productos.aggregate([
    {
      $lookup: {
        from: "resenas_clientes",
        localField: "codigo",
        foreignField: "codigo_producto",
        as: "resenas"
      }
    },
    { $unwind: "$resenas" },
    {
      $group: {
        _id: "$codigo",
        nombre: { $first: "$nombre" },
        total_resenas: { $sum: 1 },
        calificacion_promedio: { $avg: "$resenas.calificacion" }
      }
    },
    {
      $project: {
        _id: 0,
        codigo: "$_id",
        nombre: 1,
        total_resenas: 1,
        calificacion_promedio: { $round: ["$calificacion_promedio", 2] }
      }
    },
    { $sort: { calificacion_promedio: -1, total_resenas: -1 } }
  ]).toArray()
);

print("\n=========================================================================");
print("   FIN DE EJECUCION SCRIPT EP3 SONIDO VIVO (MONGODB)");
print("=========================================================================");
