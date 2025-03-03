{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies      #-}

module Data.Morpheus.Types.ID
  ( ID(..)
  ) where

import           Data.Morpheus.Kind                 (SCALAR)
import           Data.Morpheus.Types.GQLScalar      (GQLScalar (..))
import           Data.Morpheus.Types.GQLType        (GQLType (KIND, __typeVisibility))
import           Data.Morpheus.Types.Internal.Value (ScalarValue (..))
import           Data.Text                          (Text, pack)
import           GHC.Generics                       (Generic)

-- | default GraphQL type,
-- parses only 'String' and 'Int' values,
-- serialized always as 'String'
newtype ID = ID
  { unpackID :: Text
  } deriving (Generic)

instance GQLType ID where
  type KIND ID = SCALAR
  __typeVisibility _ = False

instance GQLScalar ID where
  parseValue (Int x)    = return (ID $ pack $ show x)
  parseValue (String x) = return (ID x)
  parseValue _          = Left ""
  serialize (ID x) = String x
