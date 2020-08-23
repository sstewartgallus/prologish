{-# LANGUAGE DataKinds #-}
{-# LANGUAGE KindSignatures #-}

module Lambda.AsBound (Expr, bindPoints) where

import Control.Category
import Control.Monad.State
import Lambda.Exp
import Lambda.Hoas
import Id (Stream (..))
import Lambda.Labels
import Lambda
import Lambda.Product
import Lambda.Sum
import Lambda.Type
import Lambda.Vars
import Prelude hiding ((.), (<*>), id)

newtype Expr k (a :: T) (b :: T) = Expr {unExpr :: Stream -> k a b}

bindPoints :: Stream -> Expr k env a -> k env a
bindPoints str (Expr x) = x str

instance (Labels k, Vars k) => Hoas (Expr k) where
  mapVar t f = Expr $ \(Stream n bodys _) ->
    bindMapVar n t $ \v ->
      unExpr (f (Expr $ const v)) bodys
  mapLabel t f = Expr $ \(Stream n bodys _) ->
    bindMapLabel n t $ \v ->
      unExpr (f (Expr $ const v)) bodys

instance Category k => Category (Expr k) where
  id = Expr $ pure id
  Expr f . Expr g = Expr $ liftM2 (.) f g

instance Product k => Product (Expr k) where
  unit = Expr $ pure unit
  Expr f # Expr g = Expr $ liftM2 (#) f g
  first = Expr $ pure first
  second = Expr $ pure second

  letBe (Expr x) (Expr f) = Expr $ liftM2 letBe x f
  whereIs (Expr f) (Expr x) = Expr $ liftM2 whereIs f x

instance Sum k => Sum (Expr k) where
  absurd = Expr $ pure absurd
  Expr f ! Expr g = Expr $ liftM2 (!) f g
  left = Expr $ pure left
  right = Expr $ pure right

  letCase (Expr x) (Expr f) = Expr $ liftM2 letCase x f
  whereCase (Expr f) (Expr x) = Expr $ liftM2 whereCase f x

instance Exp k => Exp (Expr k) where
  lambda (Expr f) = Expr $ liftM lambda f
  Expr f <*> Expr x = Expr $ liftM2 (<*>) f x

instance Lambda k => Lambda (Expr k) where
  u64 x = Expr $ pure (u64 x)
  add = Expr $ pure add