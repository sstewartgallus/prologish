{-# LANGUAGE DataKinds #-}
{-# LANGUAGE KindSignatures #-}

module Term.AsView (View, view) where

import Term
import Hoas.Type

newtype View (env :: [T]) (a :: T) = View String

view :: View env a -> String
view (View v) = v

instance Term View where
  View x `be` View f = View ("(" ++ x ++ " be " ++ f ++ ")")
  View f <*> View x = View ("(" ++ f ++ " " ++ x ++ ")")

  u64 n = View (show n)
  add = View "add"

  tip = View "I"
  const (View x) = View ("(K " ++ x ++ ")")

  curry (View f) = View ("(λ " ++ f ++ ")")