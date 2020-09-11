{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE NoStarIsType #-}

module Term (Term (..)) where

import Data.Word (Word64)
import Hoas.Type
import Prelude hiding (const, curry, (<*>))

class Term t where
  be :: t a env -> t b (a ': env) -> t b env

  tip :: t a (a ': env)
  const :: t a env -> t a (any ': env)

  mal :: t b (a ': env) -> t (a -< b) env
  try :: t (a -< b) env -> t a env -> t b env

  unit :: t a '[Unit]
  (&&&) :: t c '[a] -> t c '[b] -> t c '[a * b]
  first :: t (a * b) '[a]
  second :: t (a * b) '[b]

  absurd :: t Void r
  (|||) :: t a c -> t b c -> t (a + b) c
  left :: t a '[a + b]
  right :: t b '[a + b]

  u64 :: Word64 -> t Unit '[U64]
  add :: t env '[U64] -> t env '[U64] -> t env '[U64]

  swap :: t b (x ': a ': env) -> t b (a ': x ': env)
  swap f = const (const (mal (mal f))) `try` tip `try` const tip
