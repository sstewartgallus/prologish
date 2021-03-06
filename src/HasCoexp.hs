{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE NoStarIsType #-}

module HasCoexp (mal, HasCoexp (..)) where

import Control.Category
import HasSum
import Type
import Prelude hiding (curry, id, uncurry, (.), (<*>))

-- | The categorical definition of an exponential (function type.)
class HasSum k => HasCoexp k where
  (<*>) :: k (a -< b) env -> k a env -> k b env
  f <*> x = (x ||| id) . try f

  st :: k b (a + env) -> k (a -< b) env
  try :: k (a -< b) env -> k b (a + env)

-- | deprecated alias
mal :: HasCoexp k => k b (a + env) -> k (a -< b) env
mal = st
