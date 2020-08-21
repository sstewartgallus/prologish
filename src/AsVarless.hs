{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE NoStarIsType #-}

module AsVarless (Varless, removeVariables) where

import Control.Category
import Data.Typeable ((:~:) (..))
import Exp
import Labels
import Lambda
import Product
import Sum
import Type
import Vars
import Prelude hiding ((.), (<*>), id)

removeVariables :: Product k => Varless k a b -> k a b
removeVariables (V x) = x EmptyEnv . (id # unit)

matchVar :: Product k => Var a -> Env env -> k env a
matchVar x env = case env of
  VarEnv y rest -> case x `eqVar` y of
    Just Refl -> second
    Nothing -> matchVar x rest . first
  _ -> undefined

newtype Varless k a (b :: T) = V (forall env. Env env -> k (a * env) b)

data Env a where
  EmptyEnv :: Env Unit
  VarEnv :: Var v -> Env a -> Env (a * v)

inV :: Product k => k a b -> Varless k a b
inV f = V (const (f . first))

instance Product k => Category (Varless k) where
  id = inV id
  V f . V g = V $ \env -> f env . (g env # second)

instance (Exp k, Labels k) => Labels (Varless k) where
  mkLabel lbl = inV (mkLabel lbl)
  bindLabel lbl (V x) = V $ \env -> bindLabel lbl (x env)

instance (Product k, Labels k) => Vars (Varless k) where
  mkVar v = V $ \env -> matchVar v env . second
  bindVar v (V x) = V $ \env ->
    let shuffle :: Product k => k ((a * c) * b) (a * (b * c))
        shuffle = (first . first) # (second # (second . first))
     in x (VarEnv v env) . shuffle

instance Product k => Product (Varless k) where
  unit = inV unit
  V f # V g = V $ \env -> f env # g env
  first = inV first
  second = inV second

instance (Sum k, Exp k) => Sum (Varless k) where
  absurd = inV absurd
  V f ! V g = V $ \env -> factor (f env) (g env)
  left = inV left
  right = inV right

instance Exp k => Exp (Varless k) where
  lambda (V f) = V $ \env ->
    let shuffle :: Product k => k ((a * b) * c) ((a * c) * b)
        shuffle = ((first . first) # second) # (second . first)
     in lambda (f env . shuffle)
  eval = inV eval

instance Lambda k => Lambda (Varless k) where
  u64 x = inV (u64 x)
  add = inV add

factor :: (Sum k, Exp k) => k (a * x) c -> k (b * x) c -> k ((a + b) * x) c
factor f g = eval . (((lambda f ! lambda g) . first) # second)
