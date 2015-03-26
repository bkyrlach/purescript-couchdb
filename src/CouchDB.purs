module Database.CouchDB where 

import Control.Monad.Eff
import Data.Function
import Data.Either
import Control.Monad.Error.Trans
import Control.Monad.Cont.Trans

type ErrorCode = String

type DBE eff = Eff (db :: DB | eff)
type DBEC eff r = ContT r (DBE eff)
type DBECE eff r = ErrorT ErrorCode (DBEC eff r)

foreign import data DB :: !

foreign import data Module :: *
foreign import data Cluster :: *
foreign import data Bucket :: *
foreign import data ViewQuery :: *

foreign import requireCouchbase """
  function requireCouchbase() {
    return module.require('couchbase');
  }
  """ :: forall eff. DBE eff  Module

foreign import connectClusterImpl """
  function connectClusterImpl(couchModule, address) {
    return function () {
      return new couchModule.Cluster(address);
    };
  }
  """ :: forall eff. Fn2 Module 
                         String 
                         (DBE eff Cluster)

connectCluster :: forall eff. Module -> String -> DBE eff Cluster
connectCluster = runFn2 connectClusterImpl

foreign import doWorkImpl """
  function doWorkImpl(cluster, bucketName, onSuccess, onFailure) {
    return function() {
      console.log('doing work?', onSuccess);
      var bucket = cluster.openBucket(bucketName, function(err) {
        if(err) {
          console.log('error?');
          onFailure(err)();
        } else {
          console.log('success');
          onSuccess(bucket)();
        }
      });
    };
  }
  """ :: forall a eff. Fn4 Cluster
                           String
                           (Bucket -> DBE eff a)
                           (ErrorCode -> DBE eff a) 
                           (DBE eff a)

doWork1 :: forall a eff. Cluster -> String -> (Either ErrorCode Bucket -> DBE eff a) -> DBE eff a
doWork1 c b k = runFn4 doWorkImpl c b (k <<< Right) (k <<< Left)

doWork2 :: forall a eff. Cluster -> String -> DBEC eff a (Either ErrorCode Bucket)
doWork2 c b = ContT $ doWork1 c b

doWork :: forall a eff. Cluster -> String -> DBECE eff a Bucket
doWork c b = ErrorT $ doWork2 c b

foreign import createQueryImpl """
  function createQueryImpl(couchModule, designDoc, viewName) {
    return function() {
      console.log('Query created!');
      return couchModule.ViewQuery.from(designDoc, viewName);
    };
  }
  """ :: forall eff. Fn3 Module
                         String
                         String
                         (DBE eff ViewQuery)

createQuery :: forall eff. Module -> String -> String -> DBE eff ViewQuery
createQuery = runFn3 createQueryImpl

foreign import queryImpl """
  function queryImpl(bucket, query, onSuccess, onFailure) {
    return function() {
      console.log('query???', bucket);
      bucket.query(query, null, function(err, rows) {
        if(err) {
          console.log('failed?');
          onFailure(err)();
        } else {
          var x = onSuccess(rows.map(function(row) { return row.value; }))();
          console.log('finished query?', x);
        }
      });
    };
  }
  """ :: forall a b eff. Fn4 Bucket
                             ViewQuery
                             ([a] -> DBE eff b)
                             (ErrorCode -> DBE eff b)
                             (DBE eff b)

query1 :: forall a b eff. Bucket -> ViewQuery -> (Either ErrorCode [a] -> DBE eff b) -> DBE eff b
query1 b q k = runFn4 queryImpl b q (k <<< Right) (k <<< Left)
             
query2 :: forall a b eff. Bucket -> ViewQuery -> DBEC eff b (Either ErrorCode [a])
query2 b q = ContT $ query1 b q

query :: forall a b eff. Bucket -> ViewQuery -> DBECE eff b [a]
query b q = ErrorT $ query2 b q

foreign import upsert """
  function upsert(bucket) {
    return function (key) {
      return function (val) {
        return function() {
          bucket.upsert(key, val, function(err, result) {});
        };
      };
    };
  }
  """ :: forall a eff. Bucket -> String -> a -> DBE eff Unit
