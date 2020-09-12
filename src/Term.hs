{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module Term (Term (..)) where

import Data.Word (Word64)
import Hoas.Type
import Prelude hiding (const, curry, (<*>))

class Term t where
  mal :: t '[b] (a + env) -> t '[a -< b] env
  try :: t '[a -< b] env -> t '[a] env -> t '[b] env

  tip :: t (a ': env) a
  const :: t env a -> t (any ': env) a

  u64 :: Word64 -> t env U64

  swap :: t (x ': a ': env) b -> t (a ': x ': env) b
  swap f = undefined -- const (const (mal (mal f))) `try` tip `try` const tip
