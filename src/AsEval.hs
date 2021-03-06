{-# LANGUAGE DataKinds #-}
{-# LANGUAGE EmptyCase #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE Strict #-}
{-# LANGUAGE StrictData #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeFamilyDependencies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE NoStarIsType #-}

-- | Strict / Strict Data are not for performance but simply to
-- emphasize the semantics don't depend on laziness
module AsEval (Expr, asEval, Value (..)) where

import Control.Category
import Control.Monad.Cont
import Data.Kind
import qualified Data.Void as Void
import Data.Word
import Global
import HasCoexp
import HasProduct
import HasSum
import Mal
import Type
import Prelude hiding (Bool (..), Either (..), id, (.))

asEval :: Expr m a b -> Value m a -> m (Value m b)
asEval (E x) = x

data family Value (m :: Type -> Type) (a :: T)

data instance Value m (a + b) = Left (Value m a) | Right (Value m b)

data instance Value m (a * b) = Value m a ::: Value m b

data instance Value m (a -< b) = Value m b :- (Value m a -> m Void.Void)

data instance Value m B = True | False

infixl 9 :-

data instance Value m Unit = Coin

data instance Value m Void

newtype instance Value m U64 = Value64 Word64

newtype Expr m a b = E (Value m a -> m (Value m b))

instance Monad m => Category (Expr m) where
  id = E pure
  E f . E g = E $ \x -> do
    y <- g x
    f y

instance Monad m => HasProduct (Expr m) where
  unit = E $ const $ pure Coin

  E f &&& E g = E $ \x -> do
    f' <- f x
    g' <- g x
    pure $ f' ::: g'
  first = E $ \(x ::: _) -> pure x
  second = E $ \(_ ::: x) -> pure x

instance Monad m => HasSum (Expr m) where
  absurd = E $ \x -> case x of

  E f ||| E g = E $ \x -> case x of
    Left l -> f l
    Right r -> g r
  left = E (pure . Left)
  right = E (pure . Right)

instance MonadCont m => HasCoexp (Expr m) where
  st (E f) = E $ \(x :- k) -> do
    y <- f x
    case y of
      Left l -> do
        abs <- k l
        Void.absurd abs
      Right r -> pure r
  try (E f) = E $ \b -> callCC $ \k -> do
    env <- f $ b :- \x -> k (Left x)
    pure (Right env)

instance MonadCont m => Mal (Expr m) where
  true = E $ \Coin -> pure True
  false = E $ \Coin -> pure False
  u64 x = E $ \Coin -> pure $ Value64 x

  global (Global (SU64 :*: SU64) SU64 "core" "add") = E $ \(Value64 x ::: Value64 y) -> pure $ Value64 (x + y)
  global (Global SU64 SU64 "core" "succ") = E $ \(Value64 x) -> pure $ Value64 (x + 1)
