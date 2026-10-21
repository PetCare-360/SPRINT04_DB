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

const validator = {
  $jsonSchema: {
    bsonType: "object",
    required: ["petId", "name", "age", "weight", "breed", "owner", "device", "sensorReadings", "alerts"],
    properties: {
      petId: { bsonType: ["int", "long", "double", "decimal"], minimum: 1 },
      name: { bsonType: "string", minLength: 1 },
      age: { bsonType: ["int", "long", "double", "decimal"], minimum: 0 },
      weight: { bsonType: ["int", "long", "double", "decimal"], minimum: 0, exclusiveMinimum: true },
      breed: { bsonType: "string", minLength: 1 },
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
        required: ["deviceId", "status", "battery", "lastSeen"],
        properties: {
          deviceId: { bsonType: ["int", "long", "double", "decimal"] },
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
      alerts: {
        bsonType: "array",
        items: {
          bsonType: "object",
          required: ["alertId", "type", "message", "level", "createdAt"],
          properties: {
            type: { enum: ["ACTIVITY", "TEMPERATURE"] },
            level: { enum: ["CRITICAL", "INFO", "WARNING"] },
            createdAt: { bsonType: "date" }
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
      alerts: pet.alerts.map((alert) => ({
        ...alert,
        createdAt: toDate(alert.createdAt, `alert ${alert.alertId}.createdAt`)
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
  { _id: 0, petId: 1, name: 1, owner: 1, device: 1, sensorReadings: { $slice: 1 }, alerts: 1 }
));
