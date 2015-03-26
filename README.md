# purescript-couchdb
A purescript wrapper for the node.js CouchDB library.

Here's an example of how to use it.

```PureScript
-- Import the library
import qualified Database.CouchDB as DB

-- Get an instance of the module
cbModule = DB.requireCouchbase

-- Connect to a cluster
cbCluster = do
  m <- cbModule
  DB.connectCluster m "127.0.0.1:8091"
  
-- Accessing a view...
myView = do
  m <- cbModule
  DB.createQuery m "design_doc" "view_name"
  
-- Querying the view for documents
runQuery = runContT $ runErrorT $ do
  cluster <- lift cbCluster
  query   <- lift myView
  bucket  <- DB.doWork cluster "my_bucket"
  rows    <- DB.query bucket query
  return rows
  
-- Save a document
save key doc = runContT $ runErrorT $ do
  cluster <- lift cbCluster
  bucket  <- DB.doWork cluster "my_bucket"
  DB.upsert key doc
```
