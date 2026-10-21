/*
 * Executar dentro da pasta:
 *   mongosh "mongodb://localhost:27017" 04_mongodb_import.js
 *
 * Variaveis opcionais:
 *   MONGO_DB=petcare360
 *   DATASET_PATH=./03_dataset_petcare360_exportado.json
 */

const fs = require("fs");
const databaseName = process.env.MONGO_DB || "petcare360";
const datasetPath = process.env.DATASET_PATH || "./03_dataset_petcare360_exportado.json";
const targetDb = db.getSiblingDB(databaseName);

let dataset;
try {
  dataset = JSON.parse(fs.readFileSync(datasetPath, "utf8"));
} catch (error) {
  throw new Error(`Nao foi possivel ler o dataset ${datasetPath}: ${error.message}`);
}

if (!dataset || !Array.isArray(dataset.pets) || dataset.pets.length === 0) {
  throw new Error("Dataset invalido: o array pets deve possuir ao menos um documento.");
}
if (dataset.schemaVersion !== "2.0" || dataset.pets.some((pet) =>
  !Array.isArray(pet.veterinarians) || !Array.isArray(pet.messages) ||
  !Array.isArray(pet.appointments) || !Array.isArray(pet.recommendations) ||
  !Array.isArray(pet.alerts) || pet.alerts.some((alert) => !Array.isArray(alert.history)))) {
  throw new Error("Dataset incompatível: gere novamente o JSON da versao 2.0 no Oracle.");
}

const validator = {
  $jsonSchema: {
    bsonType: "object",
    required: ["petId", "name", "age", "weight", "breed", "species", "active", "owner", "device", "sensorReadings", "veterinarians", "messages", "appointments", "recommendations", "alerts"],
    properties: {
      petId: { bsonType: ["int", "long", "double", "decimal"], minimum: 1 },
      name: { bsonType: "string", minLength: 1 },
      age: { bsonType: ["int", "long", "double", "decimal"], minimum: 0 },
      weight: { bsonType: ["int", "long", "double", "decimal"], minimum: 0, exclusiveMinimum: true },
      breed: { bsonType: "string", minLength: 1 },
      species: { enum: ["DOG", "CAT", "OTHER"] },
      active: { bsonType: ["int", "long", "double", "decimal"], enum: [0, 1] },
      createdAt: { bsonType: "date" },
      owner: {
        bsonType: "object",
        required: ["userId", "name", "email"],
        properties: {
          userId: { bsonType: ["int", "long", "double", "decimal"] },
          name: { bsonType: "string" },
          email: { bsonType: "string" }
        }
      },
      device: {
        bsonType: "object",
        required: ["deviceId", "deviceCode", "status", "battery", "lastSeen"],
        properties: {
          deviceId: { bsonType: ["int", "long", "double", "decimal"] },
          deviceCode: { bsonType: "string", minLength: 1 },
          status: { enum: ["A", "I", "M"] },
          battery: { bsonType: ["int", "long", "double", "decimal"], minimum: 0, maximum: 100 },
          lastSeen: { bsonType: "date" }
        }
      },
      sensorReadings: {
        bsonType: "array",
        items: {
          bsonType: "object",
          required: ["sensorId", "timestamp", "temperature", "heartRate", "activityLevel", "location", "battery", "status", "classification"],
          properties: {
            timestamp: { bsonType: "date" },
            activityLevel: { enum: ["HIGH", "MEDIUM", "LOW"] },
            status: { enum: ["A", "I", "M"] },
            classification: { enum: ["NORMAL", "ALERTA", "CRITICO"] },
            location: {
              bsonType: "object",
              required: ["type", "coordinates"],
              properties: {
                type: { enum: ["Point"] },
                coordinates: {
                  bsonType: "array",
                  minItems: 2,
                  maxItems: 2,
                  items: { bsonType: ["int", "long", "double", "decimal"] }
                }
              }
            }
          }
        }
      },
      veterinarians: {
        bsonType: "array",
        items: {
          bsonType: "object",
          required: ["userId", "name", "assignedAt", "active"],
          properties: {
            userId: { bsonType: ["int", "long", "double", "decimal"] },
            name: { bsonType: "string" },
            assignedAt: { bsonType: "date" },
            active: { enum: [0, 1] }
          }
        }
      },
      messages: {
        bsonType: "array",
        items: {
          bsonType: "object",
          required: ["messageId", "senderId", "receiverId", "subject", "message", "status", "createdAt"],
          properties: {
            status: { enum: ["SENT", "READ", "ANSWERED"] },
            createdAt: { bsonType: "date" },
            readAt: { bsonType: ["date", "null"] }
          }
        }
      },
      appointments: {
        bsonType: "array",
        items: {
          bsonType: "object",
          required: ["appointmentId", "tutorId", "veterinarianId", "scheduledAt", "reason", "status", "createdAt"],
          properties: {
            scheduledAt: { bsonType: "date" },
            status: { enum: ["REQUESTED", "CONFIRMED", "CANCELED", "DONE"] },
            createdAt: { bsonType: "date" }
          }
        }
      },
      recommendations: {
        bsonType: "array",
        items: {
          bsonType: "object",
          required: ["recommendationId", "tutorId", "veterinarianId", "title", "instructions", "priority", "status", "createdAt"],
          properties: {
            priority: { enum: ["LOW", "NORMAL", "HIGH"] },
            status: { enum: ["ACTIVE", "COMPLETED", "CANCELED"] },
            createdAt: { bsonType: "date" },
            completedAt: { bsonType: ["date", "null"] }
          }
        }
      },
      alerts: {
        bsonType: "array",
        items: {
          bsonType: "object",
          required: ["alertId", "type", "message", "level", "status", "createdAt", "history"],
          properties: {
            type: { enum: ["ACTIVITY", "TEMPERATURE", "HEART_RATE", "BATTERY"] },
            level: { enum: ["CRITICAL", "INFO", "WARNING"] },
            status: { enum: ["OPEN", "IN_PROGRESS", "RESOLVED"] },
            createdAt: { bsonType: "date" },
            resolvedAt: { bsonType: ["date", "null"] },
            history: {
              bsonType: "array",
              items: {
                bsonType: "object",
                required: ["historyId", "userId", "newStatus", "createdAt"],
                properties: {
                  previousStatus: { enum: [null, "OPEN", "IN_PROGRESS", "RESOLVED"] },
                  newStatus: { enum: ["OPEN", "IN_PROGRESS", "RESOLVED"] },
                  createdAt: { bsonType: "date" }
                }
              }
            }
          }
        }
      },
      source: { bsonType: "object" }
    }
  }
};

if (!targetDb.getCollectionNames().includes("pets")) {
  targetDb.createCollection("pets", {
    validator,
    validationLevel: "strict",
    validationAction: "error"
  });
} else {
  targetDb.runCommand({
    collMod: "pets",
    validator,
    validationLevel: "strict",
    validationAction: "error"
  });
}

const toDate = (value, field) => {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    throw new Error(`Data invalida em ${field}: ${value}`);
  }
  return parsed;
};

const operations = dataset.pets.map((pet) => ({
  replaceOne: {
    filter: { petId: pet.petId },
    replacement: {
      ...pet,
      createdAt: toDate(pet.createdAt, `pet ${pet.petId}.createdAt`),
      device: {
        ...pet.device,
        lastSeen: toDate(pet.device.lastSeen, `pet ${pet.petId}.device.lastSeen`)
      },
      sensorReadings: pet.sensorReadings.map((reading) => ({
        ...reading,
        timestamp: toDate(reading.timestamp, `sensor ${reading.sensorId}.timestamp`)
      })),
      veterinarians: pet.veterinarians.map((vet) => ({
        ...vet,
        assignedAt: toDate(vet.assignedAt, `veterinario ${vet.userId}.assignedAt`)
      })),
      messages: pet.messages.map((message) => ({
        ...message,
        createdAt: toDate(message.createdAt, `mensagem ${message.messageId}.createdAt`),
        readAt: message.readAt ? toDate(message.readAt, `mensagem ${message.messageId}.readAt`) : null
      })),
      appointments: pet.appointments.map((appointment) => ({
        ...appointment,
        scheduledAt: toDate(appointment.scheduledAt, `consulta ${appointment.appointmentId}.scheduledAt`),
        createdAt: toDate(appointment.createdAt, `consulta ${appointment.appointmentId}.createdAt`)
      })),
      recommendations: pet.recommendations.map((recommendation) => ({
        ...recommendation,
        createdAt: toDate(recommendation.createdAt, `recomendacao ${recommendation.recommendationId}.createdAt`),
        completedAt: recommendation.completedAt ? toDate(recommendation.completedAt, `recomendacao ${recommendation.recommendationId}.completedAt`) : null
      })),
      alerts: pet.alerts.map((alert) => ({
        ...alert,
        createdAt: toDate(alert.createdAt, `alert ${alert.alertId}.createdAt`),
        resolvedAt: alert.resolvedAt ? toDate(alert.resolvedAt, `alert ${alert.alertId}.resolvedAt`) : null,
        history: alert.history.map((item) => ({
          ...item,
          createdAt: toDate(item.createdAt, `historico ${item.historyId}.createdAt`)
        }))
      })),
      source: {
        system: "Oracle",
        dataset: dataset.dataset,
        schemaVersion: dataset.schemaVersion,
        generatedAt: toDate(dataset.generatedAt, "generatedAt"),
        importedAt: new Date()
      }
    },
    upsert: true
  }
}));

const result = targetDb.pets.bulkWrite(operations, { ordered: true });

targetDb.pets.createIndex({ petId: 1 }, { unique: true, name: "uk_pets_pet_id" });
targetDb.pets.createIndex({ "owner.userId": 1 }, { name: "idx_pets_owner" });
targetDb.pets.createIndex({ "device.deviceId": 1 }, { unique: true, name: "uk_pets_device" });
targetDb.pets.createIndex({ "sensorReadings.location": "2dsphere" }, { name: "idx_sensor_location" });
targetDb.pets.createIndex({ "alerts.level": 1 }, { name: "idx_alert_level" });
targetDb.pets.createIndex({ "veterinarians.userId": 1 }, { name: "idx_pets_veterinario" });
targetDb.pets.createIndex({ "appointments.scheduledAt": 1 }, { name: "idx_consultas_data" });

printjson({
  database: databaseName,
  collection: "pets",
  matched: result.matchedCount,
  modified: result.modifiedCount,
  upserted: result.upsertedCount,
  totalDocuments: targetDb.pets.countDocuments({})
});

printjson(targetDb.pets.findOne(
  { petId: 1 },
  { _id: 0, petId: 1, name: 1, owner: 1, device: 1, veterinarians: 1,
    appointments: 1, sensorReadings: { $slice: 1 }, alerts: 1 }
));
