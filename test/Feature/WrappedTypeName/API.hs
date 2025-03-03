{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies      #-}
{-# LANGUAGE TypeOperators     #-}

module Feature.WrappedTypeName.API
  ( api
  ) where

import           Data.ByteString.Lazy.Char8 (ByteString)
import           Data.Morpheus              (interpreter)
import           Data.Morpheus.Kind         (OBJECT)
import           Data.Morpheus.Types        (EventContent, GQLRootResolver (..), GQLType (..), ResM, StreamM)
import           Data.Text                  (Text)
import           Data.Typeable              (Typeable)
import           GHC.Generics               (Generic)

instance Typeable a => GQLType (WA a) where
  type KIND (WA a) = OBJECT

instance (Typeable a, Typeable b) => GQLType (Wrapped a b) where
  type KIND (Wrapped a b) = OBJECT

data Wrapped a b = Wrapped
  { fieldA :: a
  , fieldB :: b
  } deriving (Generic)

data WA m = WA
  { aText :: () -> m Text
  , aInt  :: Int
  } deriving (Generic)

data Query = Query
  { a1 :: WA ResM
  , a2 :: Maybe (Wrapped Int Int)
  , a3 :: Maybe (Wrapped (Wrapped Text Int) Text)
  } deriving (Generic)

data Mutation = Mutation
  { mut1 :: Maybe (WA (StreamM EVENT))
  , mut2 :: Maybe (Wrapped Int Int)
  , mut3 :: Maybe (Wrapped (Wrapped Text Int) Text)
  } deriving (Generic)

data EVENT =
  EVENT
  deriving (Show, Eq)

data instance  EventContent EVENT = Content

data Subscription = Subscription
  { sub1 :: () -> ([EVENT], EventContent EVENT -> ResM (Maybe (WA ResM)))
  , sub2 :: () -> ([EVENT], EventContent EVENT -> ResM (Maybe (Wrapped Int Int)))
  , sub3 :: () -> ([EVENT], EventContent EVENT -> ResM (Maybe (Wrapped (Wrapped Text Int) Text)))
  } deriving (Generic)

rootResolver :: GQLRootResolver IO EVENT Query Mutation Subscription
rootResolver =
  GQLRootResolver
    { queryResolver = return Query {a1 = WA {aText = const $ pure "test1", aInt = 0}, a2 = Nothing, a3 = Nothing}
    , mutationResolver = return Mutation {mut1 = Nothing, mut2 = Nothing, mut3 = Nothing}
    , subscriptionResolver =
        return
          Subscription
            { sub1 = const ([EVENT], const $ return Nothing)
            , sub2 = const ([EVENT], const $ return Nothing)
            , sub3 = const ([EVENT], const $ return Nothing)
            }
    }

api :: ByteString -> IO ByteString
api = interpreter rootResolver
