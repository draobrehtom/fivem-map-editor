let isMongoLoaded = moduleIsAvailable('mongodb');

function moduleIsAvailable (path) {
    try {
        require.resolve(path);
        return true;
    } catch (e) {
        return false;
    }
}

function checkParams(params) {
    return params !== null && typeof params === 'object';
}

const utils = require('./utils.js');

if (isMongoLoaded) {
    const mongodb = require('mongodb');


    const dbUrl = GetConvar('mongodb_url', 'mongodb://localhost:27017');
    const dbName = GetConvar('mongodb_database', 'editor2');

    let db;

    mongodb.MongoClient.connect(dbUrl, { useNewUrlParser: true, useUnifiedTopology: true }, function (err, client) {
        if (err) { return console.log('[MongoDB] Failed to connect: ' + err.message); }

        db = client.db(dbName);
        console.log(`[MongoDB] Connected to database: ${dbName}`);
        emit('onDatabaseConnect', dbName);
    });

    function checkDatabaseReady() {
        if (!db) { console.log(`[MongoDB] Database is not connected.`); return false; }
        
        return true;
    }



    function getParamsCollection(params) {
        if (!params.collection) { return; }

        return db.collection(params.collection)
    }

    /* MongoDB methods wrappers */

    /**
     * MongoDB insert method
     * @param {Object} params - Params object
     * @param {Array}  params.documents - An array of documents to insert.
     * @param {Object} params.options - Options passed to insert.
     */
    function dbInsert(params, callback) {
        if (!checkDatabaseReady()) { return; }

        if (!checkParams(params)) { return console.log(`[MongoDB][ERROR] exports.insert: Invalid params object.`); }

        let collection = getParamsCollection(params);
        if (!collection) {
            return console.log(`[MongoDB][ERROR] exports.insert: Invalid collection '${params.collection}'`);
        }

        let documents = params.documents;
        if (!documents || !Array.isArray(documents)) {
            return console.log(`[MongoDB][ERROR] exports.insert: Invalid 'params.documents' value. Expected object or array of objects.`);
        }

        const options = utils.safeObjectArgument(params.options);
        collection.insertMany(documents, options, (err, result) => {
            if (err) {
                console.log(`[MongoDB][ERROR] exports.insert: Error '${err.message}'.`);
                utils.safeCallback(callback, false, err.message);
                return;
            }
            let arrayOfIds = [];

            // Convert object to an array
            for (let key in result.insertedIds) {
                if (result.insertedIds.hasOwnProperty(key)) {
                    arrayOfIds[parseInt(key)] = result.insertedIds[key].toString();
                }
            }
            utils.safeCallback(callback, true, result.insertedCount, arrayOfIds);
        });
        process._tickCallback();
    }

    /**
     * MongoDB find method
     * @param {Object} params - Params object
     * @param {Object} params.query - Query object.
     * @param {Object} params.options - Options passed to insert.
     * @param {number} params.limit - Limit documents count.
     */
    function dbFind(params, callback) {
        if (!checkDatabaseReady()) { return; }

        if (!checkParams(params)) { return console.log(`[MongoDB][ERROR] exports.find: Invalid params object.`); }

        let collection = getParamsCollection(params);
        if (!collection) { return console.log(`[MongoDB][ERROR] exports.insert: Invalid collection '${params.collection}'`); }

        const query = utils.safeObjectArgument(params.query);
        const options = utils.safeObjectArgument(params.options);

        let cursor = collection.find(query, options);
        if (params.limit) { cursor = cursor.limit(params.limit); }

        cursor.toArray((err, documents) => {
            if (err) {
                console.log(`[MongoDB][ERROR] exports.find: Error '${err.message}'.`);
                utils.safeCallback(callback, false, err.message);
                return;
            };
            utils.safeCallback(callback, true, utils.exportDocuments(documents));
        });
        process._tickCallback();
        return params;
    }

    /**
     * MongoDB update method
     * @param {Object} params - Params object
     * @param {Object} params.query - Filter query object.
     * @param {Object} params.update - Update query object.
     * @param {Object} params.options - Options passed to insert.
     */
    function dbUpdate(params, callback, isUpdateOne) {
        if (!checkDatabaseReady()) { return; }

        if (!checkParams(params)) { return console.log(`[MongoDB][ERROR] exports.update: Invalid params object.`); }

        let collection = getParamsCollection(params);
        if (!collection) { return console.log(`[MongoDB][ERROR] exports.insert: Invalid collection '${params.collection}'`); }

        query = utils.safeObjectArgument(params.query);
        update = utils.safeObjectArgument(params.update);
        options = utils.safeObjectArgument(params.options);
        const cb = (err, res) => {
            if (err) {
                console.log(`[MongoDB][ERROR] exports.update: Error '${err.message}'.`);
                utils.safeCallback(callback, false, err.message);
                return;
            }
            utils.safeCallback(callback, true, res);
        };

        isUpdateOne ? collection.updateOne(query, update, options, cb) : collection.updateMany(query, update, options, cb);
        process._tickCallback();
    }

    /**
     * MongoDB count method
     * @param {Object} params - Params objects
     * @param {Object} params.query - Query object.
     * @param {Object} params.options - Options passed to insert.
     */
    function dbCount(params, callback) {
        if (!checkDatabaseReady()) { return; }

        if (!checkParams(params)) { return console.log(`[MongoDB][ERROR] exports.count: Invalid params object.`); }

        let collection = getParamsCollection(params);
        if (!collection) { return console.log(`[MongoDB][ERROR] exports.insert: Invalid collection '${params.collection}'`); }

        const query = utils.safeObjectArgument(params.query);
        const options = utils.safeObjectArgument(params.options);

        collection.countDocuments(query, options, (err, count) => {
            if (err) {
                console.log(`[MongoDB][ERROR] exports.count: Error '${err.message}'.`);
                utils.safeCallback(callback, false, err.message);
                return;
            }
            utils.safeCallback(callback, true, count);
        });
        process._tickCallback();
    }

    /**
     * MongoDB delete method
     * @param {Object} params - Params object
     * @param {Object} params.query - Query object.
     * @param {Object} params.options - Options passed to insert.
     */
    function dbDelete(params, callback, isDeleteOne) {
        if (!checkDatabaseReady()) { return; }

        if (!checkParams(params)) { return console.log(`[MongoDB][ERROR] exports.delete: Invalid params object.`); }

        let collection = getParamsCollection(params);
        if (!collection) { return console.log(`[MongoDB][ERROR] exports.insert: Invalid collection '${params.collection}'`); }

        const query = utils.safeObjectArgument(params.query);
        const options = utils.safeObjectArgument(params.options);
        const cb = (err, res) => {
            if (err) {
                console.log(`[MongoDB][ERROR] exports.delete: Error '${err.message}'.`);
                utils.safeCallback(callback, false, err.message);
                return;
            }
            utils.safeCallback(callback, true, res);
        };

        isDeleteOne ? collection.deleteOne(query, options, cb) : collection.deleteMany(query, options, cb);
        process._tickCallback();
    }
}

/* Exports definitions */
exports('isConnected', () => {
    console.log("Exports: isConnected");
    if (!isMongoLoaded) {
        return true;
    }
    return !!db;
});

exports('insert', (params, callback) => {
    console.log("Exports: insert");
    console.log(params);
    if (!isMongoLoaded) {
        return utils.safeCallback(callback, true, []);
    }
    return dbInsert(params, callback);
});
exports('insertOne', (params, callback) => {
    console.log("Exports: insertOne");
    console.log(params);
    /*
    Exports: insertOne
    {
      "document": {
        "uId": "192.168.1.15",
        "data": {
          "playerName": "PC"
        }
      },
      "collection": "players"
    }
    {
      "document": {
        "password": "",
        "displayColor": "79b33f",
        "maximumSlots": 4,
        "ownerId": "192.168.1.15",
        "name": "AAAAA",
        "ownerName": "PC",
        "id": 1
      },
      "collection": "sessions"
    }
    */
    if (checkParams(params)) {
        params.documents = [params.document];
        params.document = null;
    }
    if (!isMongoLoaded) {
        return utils.safeCallback(callback, true, []);
    }
    return dbInsert(params, callback)
});

exports('find', (params, callback) => {
    console.log("Exports: find"); // used on resoure start
    console.log(params);
    /*
    {
      "collection": "sessions",
      "options": {
        "projection": {
          "_id": 0
        }
      },
      "query": []
    }

    {
      "collection": "sessions",
      "options": {
        "projection": {
          "ownerId": 1,
          "whitelist": 1,
          "whitelistDisabled": 1,
          "id": 1,
          "_id": 0
        }
      },
      "query": []
    }

    {
      "collection": "sessions",
      "options": {
        "projection": {
          "_id": 0
        }
      },
      "query": {
        "ownerId": "192.168.1.15"
      }
    }
    
    */
    if (!isMongoLoaded) {
        return utils.safeCallback(callback, true, []);
    }
    return dbFind(params, callback);
});
exports('findOne', (params, callback) => {
    console.log("Exports: findOne");
    console.log(params);

    /*
    {
      "collection": "players",
      "query": {
        "uId": "192.168.1.15"
      }
    }
    */

    if (checkParams(params)) { params.limit = 1; }
    if (!isMongoLoaded) {
        return utils.safeCallback(callback, true, []);
    }
    return dbFind(params, callback);
});

exports('update', (params, callback) => {
    console.log("Exports: update");
    console.log(params);
    /*
    {
      "collection": "maps",
      "query": {
        "ownerId": "192.168.1.15"
      },
      "update": {
        "$set": {
          "session": 1
        }
      }
    }
    */
    if (!isMongoLoaded) {
        return utils.safeCallback(callback, true, []);
    }
    return dbUpdate(params, callback, false);
});
exports('updateOne', (params, callback) => {
    console.log("Exports: updateOne");
    console.log(params);

    /*
        {
          "collection": "players",
          "update": {
            "$set": {
              "data": {
                "playerName": "PC"
              }
            }
          },
          "query": {
            "uId": "192.168.1.15"
          }
        }
    */

    if (!isMongoLoaded) {
        return true;
    }
    return dbUpdate(params, callback, true);
});

exports('count', (params, callback) => {
    console.log("Exports: count");
    console.log(params);
    if (!isMongoLoaded) {
        return true;
    }
    return dbCount(params, callback);
});

exports('delete', (params, callback) => {
    console.log("Exports: delete");
    console.log(params);
    if (!isMongoLoaded) {
        return true;
    }
    return dbDelete(params, callback, false);
});
exports('deleteOne', (params, callback) => {
    console.log("Exports: deleteOne");
    console.log(params);
    if (!isMongoLoaded) {
        return true;
    }
    return dbDelete(params, callback, true);
});