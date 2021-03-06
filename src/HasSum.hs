{-# LANGUAGE TypeOperators #-}

module HasSum (HasSum (..)) where

import Control.Category
import Type

class Category k => HasSum k where
  absurd :: k Void x

  (|||) :: k a c -> k b c -> k (a + b) c
  left :: k a (a + b)
  right :: k b (a + b)

infixl 9 |||
