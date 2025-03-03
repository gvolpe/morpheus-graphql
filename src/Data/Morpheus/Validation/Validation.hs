{-# LANGUAGE FlexibleInstances   #-}
{-# LANGUAGE NamedFieldPuns      #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeOperators       #-}

module Data.Morpheus.Validation.Validation
  ( validateRequest
  ) where

import           Data.Map                                   (fromList)
import           Data.Morpheus.Error.Mutation               (mutationIsNotDefined)
import           Data.Morpheus.Error.Subscription           (subscriptionIsNotDefined)
import           Data.Morpheus.Types.Internal.AST.Operator  (Operator (..), Operator' (..), RawOperator, RawOperator',
                                                             ValidOperator)
import           Data.Morpheus.Types.Internal.AST.Selection (SelectionSet)
import           Data.Morpheus.Types.Internal.Data          (DataOutputObject, DataTypeLib (..))
import           Data.Morpheus.Types.Internal.Validation    (Validation)
import           Data.Morpheus.Types.Types                  (GQLQueryRoot (..))
import           Data.Morpheus.Validation.Fragment          (validateFragments)
import           Data.Morpheus.Validation.Selection         (validateSelectionSet)
import           Data.Morpheus.Validation.Variable          (resolveOperatorVariables)

updateQuery :: RawOperator -> SelectionSet -> ValidOperator
updateQuery (Query (Operator' name' _ _ pos)) sel        = Query (Operator' name' [] sel pos)
updateQuery (Mutation (Operator' name' _ _ pos)) sel     = Mutation (Operator' name' [] sel pos)
updateQuery (Subscription (Operator' name' _ _ pos)) sel = Subscription (Operator' name' [] sel pos)

getOperator :: RawOperator -> DataTypeLib -> Validation (DataOutputObject, RawOperator')
getOperator (Query operator') lib' = pure (snd $ query lib', operator')
getOperator (Mutation operator') lib' =
  case mutation lib' of
    Just (_, mutation') -> pure (mutation', operator')
    Nothing             -> Left $ mutationIsNotDefined (operatorPosition operator')
getOperator (Subscription operator') lib' =
  case subscription lib' of
    Just (_, subscription') -> pure (subscription', operator')
    Nothing                 -> Left $ subscriptionIsNotDefined (operatorPosition operator')

validateRequest :: DataTypeLib -> GQLQueryRoot -> Validation ValidOperator
validateRequest lib GQLQueryRoot {fragments, inputVariables, operator} = do
  (operatorType, rawOperator) <- getOperator operator lib
  variables <- resolveOperatorVariables lib fragments (fromList inputVariables) rawOperator
  validateFragments lib fragments (operatorSelection rawOperator)
  selectors <-
    validateSelectionSet lib fragments (operatorName rawOperator) variables operatorType (operatorSelection rawOperator)
  pure $ updateQuery operator selectors
