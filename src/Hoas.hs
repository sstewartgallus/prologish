{-# LANGUAGE DataKinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE NoStarIsType #-}

module Hoas (Hoas (..)) where

import Control.Category
import Data.Kind
import Data.Word (Word64)
import Hoas.Type
import Prelude hiding (id, (.), (<*>))

class Category t => Hoas t where
  mal :: ST a -> (t a r -> t b r) -> t (a -< b) r
  try :: t (a -< b) r -> t a r -> t b r

  unit :: t x Unit
  (&&&) :: t x a -> t x b -> t x (a * b)
  first :: t x (a * b) -> t x a
  second :: t x (a * b) -> t x b

  empty :: t Void r
  (|||) :: t a r -> t b r -> t (a + b) r
  left :: t (a + b) r -> t a r
  right :: t (a + b) r -> t b r

  thunk :: ST a -> (forall r. t a r -> t x r) -> t x a
  thunk _ f = f id
  letBe :: ST a -> (forall x. t x a -> t x r) -> t a r
  letBe _ f = f id

  kont ::
    ST a ->
    ST b ->
    t x a ->
    (forall x r. t x b -> t x r) ->
    t x (b -< a)
  kont s t x f = thunk (t :-< s) (\k -> (k `try` letBe t f) . x)

  jump :: ST a -> t x (a -< b) -> (forall x. t x a) -> t x r
  jump t k x = mal t (\k -> k . x) . k

  env :: ST a -> ST b -> t x (a -< b) -> t x b
  env a b k = thunk b $ \x -> mal a (const x) . k

  u64 :: Word64 -> t x U64

  (|=) ::
    (KnownT a, KnownT b) =>
    t x a ->
    (forall x r. t x b -> t x r) ->
    t x (b -< a)
  x |= f = kont inferT inferT x f

  (!) ::
    (KnownT a) =>
    t x (a -< b) ->
    (forall x. t x a) ->
    t x r
  k ! x = jump inferT k x

infixl 0 |=

infixr 9 &&&

infixr 9 |||
