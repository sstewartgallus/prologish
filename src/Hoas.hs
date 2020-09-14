{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE NoStarIsType #-}

module Hoas (Hoas (..)) where

import Data.Word (Word64)
import Hoas.Type
import Prelude hiding (uncurry, (.), (<*>))

class Hoas t where
  -- Basic higher order CPS combinators
  kont :: ST a -> t x -> (t a -> t Void) -> t (a -< x)
  jump :: ST x -> t (a -< x) -> (t x -> t a) -> t c
  val :: t (a -< x) -> t x

  unit :: t Unit
  (&&&) :: t a -> t b -> t (a * b)
  first :: t (a * b) -> t a
  second :: t (a * b) -> t b

  absurd :: t Void -> t a
  either :: t (a + b) -> (t a -> t c, t b -> t c) -> t c
  left :: t a -> t (a + b)
  right :: t b -> t (a + b)

  pick :: t B -> t (Unit + Unit)
  true :: t B
  false :: t B

  u64 :: Word64 -> t U64
  add :: t U64 -> t U64 -> t U64

  load :: ST a -> String -> t a

  -- | Syntactic sugar for easier programming
  (\+) :: KnownT a => t x -> (t a -> t Void) -> t (a -< x)
  x \+ k = kont inferT x k

  fn :: (KnownT a, KnownT b) => (t b -> t a) -> t (K (a -< b))
  fn f = unit \+ \x -> x ! f

  (!) :: KnownT x => t (a -< x) -> (t x -> t a) -> t c
  x ! k = jump inferT x k

infixl 9 &&&

infixl 0 \+

infixl 0 !
