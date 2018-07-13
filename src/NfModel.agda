-- A Beth model of normal forms

open import Library

module NfModel (Base : Set) where

import Formulas   ; open module Form = Formulas    Base
import Derivations; open module Der  = Derivations Base

-- Beth model

-- A cover for Γ is the skeleton of a case tree that can be formed in Γ.
-- It contains the (neutral) scrutinees we case over and the markers (hole)
-- for the leaves that have to be filled by the branches of the case statement.

data Cover (Γ : Cxt) : Set where
  hole   : Cover Γ
  falseC : (t : Ne Γ False) → Cover Γ
  orC    : ∀{A B} (t : Ne Γ (A ∨ B)) (C : Cover (Γ ∙ A)) (D : Cover (Γ ∙ B)) → Cover Γ

-- Choice of names.
-- hole  : has the same role as the hole-evaluation context (identity).
-- falseC: basically falseE.
-- orC   : basically orE.

-- Given C : Cover Γ, a path p : Δ ∈ C leads us from the root to one of the leaves (hole)
-- of the case tree.  Δ is the context at the leaf.

data _∈_ Δ : ({Γ} : Cxt) (C : Cover Γ) → Set where
  here  : Δ ∈ hole {Δ}
  left  : ∀{Γ A B C D} {t : Ne Γ (A ∨ B)} (e : Δ ∈ C) → Δ ∈ orC t C D
  right : ∀{Γ A B C D} {t : Ne Γ (A ∨ B)} (e : Δ ∈ D) → Δ ∈ orC t C D

-- Given a case tree C : Cover Γ and a context-indexed set P,
-- f : All C P  is an assignment of things in  P Δ  to holes
-- of type Δ reached by pathes e : Δ ∈ C.

All : ∀{Γ} (C : Cover Γ) (P : (Δ : Cxt) → Set) → Set
All C P = ∀{Δ} (e : Δ ∈ C) → P Δ

-- We can also use All C P with a property P on context,
-- to express that all holes of C satify P.

-- We might want to depend on the path e : Δ ∈ C also:

All' : ∀{Γ} (C : Cover Γ) (P : ∀ {Δ} (e : Δ ∈ C) → Set) → Set
All' C P = ∀{Δ} (e : Δ ∈ C) → P e

-- If  C : Cover Γ  and  e : Δ ∈ C,  then Δ must be an extension of Γ.
-- Here, we only prove that it is a thinning.

coverWk : ∀{Γ} {C : Cover Γ} → All C (_≤ Γ)
coverWk here      = id≤
coverWk (left  e) = coverWk e • weak id≤
coverWk (right e) = coverWk e • weak id≤

-- We can substitute leaves in the case tree by case trees in turn.
-- The following is a ``parallel substitution'' operations for covers.

-- If C : Cover Γ and f is a mapping from the leaves of C to case trees
-- we can graft f onto C to get a new case tree  transC C f.

-- Here, the case tree substitution is given as a function from pathes
-- p : Δ ∈ C  to covers.

transC : ∀{Γ} (C : Cover Γ) (f : All C Cover) → Cover Γ
transC hole        f = f here
transC (falseC t)  f = falseC t
transC (orC t C D) f = orC t (transC C (f ∘ left)) (transC D (f ∘ right))

-- Composition of pathes.

-- Assume a C : Cover Γ and a substitution f : Δ ∈ C → ∁over Δ and a path e : Δ ∈ C.
-- Then any path p : Φ ∈ f e can be extended to a path q : Φ ∈ transC C f
-- by essentially concatenating e and p.

-- Note that we maintain f only for the sake of typing.

-- trans∈ : ∀{Γ} (C : Cover Γ) (f : All C Cover) →
--   ∀ {Δ} (e : Δ ∈ C) {Φ} → Φ ∈ f e → Φ ∈ transC C f

trans∈ : ∀{Γ} (C : Cover Γ) (f : All C Cover) →
  All' C λ {Δ} (e : Δ ∈ C) → All (f e) (_∈ transC C f)
trans∈ hole        f here      = id
trans∈ (falseC t)  f ()
trans∈ (orC t C D) f (left  e) = left  ∘ trans∈ C (f ∘ left ) e
trans∈ (orC t C D) f (right e) = right ∘ trans∈ D (f ∘ right) e

-- Splitting of pathes.

-- In a situation similar to the previous lemma:
-- If we have a path q : Φ ∈ transC C f we can split it into some
-- e : Δ ∈ C and p : Φ ∈ f e.

split∈ : ∀{Γ} (C : Cover Γ) (f : All C Cover) {Φ} (q : Φ ∈ transC C f)
  → ∃ λ Δ → ∃ λ (e : Δ ∈ C) → Φ ∈ f e
split∈ hole        f q = _ , _ , q
split∈ (falseC t)  f ()
split∈ (orC t C D) f (left q) with split∈ C (f ∘ left) q
... | Δ , e₁ , e₂ = Δ , left e₁ , e₂
split∈ (orC t C D) f (right q) with split∈ D (f ∘ right) q
... | Δ , e₁ , e₂ = Δ , right e₁ , e₂

-- Syntactic paste (from Thorsten).

-- If for each leave e : Δ ∈ C of a case tree C : Cover Γ we have a normal form
-- f e : Nf Δ A  of type A, grafting these nfs onto C gives us a  Nf Γ A.

paste' : ∀{A Γ} (C : Cover Γ) (f : All C λ Δ → Nf Δ A) → Nf Γ A
paste' hole        f = f here
paste' (falseC t)  f = falseE t
paste' (orC t C D) f = orE t (paste' C (f ∘ left)) (paste' D (f ∘ right))

-- Weakening covers:  A case tree in Γ can be transported to a thinning Δ
-- by weakening all the scrutinees.

-- monC : ∀{Γ Δ} (τ : Δ ≤ Γ) (C : Cover Γ) → Cover Δ
monC : Mon Cover
monC τ hole        = hole
monC τ (falseC t)  = falseC (monNe τ t)
monC τ (orC t C D) = orC (monNe τ t) (monC (lift τ) C) (monC (lift τ) D)

-- Undoing a weakening on a path.
--
-- If we have a path  e : Φ ∈ monC τ C  in a case tree  C : Cover Γ  transported
-- to Δ via thinning  τ : Δ ≤ Γ, we also get a path  e' : Ψ ∈ C  in the original
-- case tree C such that Ψ is a strenthening of Φ  (Φ ≤ Ψ).

mon∈ : ∀{Γ Δ Φ} (C : Cover Γ) (τ : Δ ≤ Γ) (e : Φ ∈ monC τ C) → ∃ λ Ψ → Ψ ∈ C × Φ ≤ Ψ
mon∈  hole τ here = _ , here , τ
mon∈ (falseC t)  τ ()
mon∈ (orC t C D) τ (left e)  with mon∈ C (lift τ) e
... | Ψ , e' , σ = Ψ , left e' , σ
mon∈ (orC t C D) τ (right e) with mon∈ D (lift τ) e
... | Ψ , e' , σ = Ψ , right e' , σ

-- Packaging a case tree with its valuation.

CovExt : (Γ : Cxt) (P : Cxt → Set) → Set
CovExt Γ P = Σ (Cover Γ) λ C → All C P

transCE : ∀ {P Γ} (C : Cover Γ) (f : All C λ Δ → CovExt Δ P) → CovExt Γ P
transCE C f = transC C (proj₁ ∘ f) , λ e →
  let _ , e₁ , e₂ = split∈ C (proj₁ ∘ f) e
  in  f e₁ .proj₂ e₂

monCE : ∀{P} → Mon P → Mon λ Γ → CovExt Γ P
monCE monP τ (C , f) = monC τ C ,  λ {Φ} e →
  let Ψ , e' , σ = mon∈ C τ e
  in  monP σ (f {Ψ} e')

-- The syntactic Beth model.

-- We interpret base propositions  Atom P  by their normal deriviations.
-- ("Normal" is important; "neutral is not sufficient since we need case trees here.)

-- The negative connectives True, ∧, and ⇒ are explained as usual by η-expansion
-- and the meta-level connective.

-- The positive connectives False and ∨ are inhabited by case trees.
-- In case False, the tree has no leaves.
-- In case A ∨ B, each leaf must be in the semantics of either A or B.

T⟦_⟧ : (A : Form) (Γ : Cxt) → Set
T⟦ Atom P ⟧ Γ = Nf Γ (Atom P)
T⟦ True   ⟧ Γ = ⊤
T⟦ False  ⟧ Γ = CovExt Γ λ Δ → ⊥
T⟦ A ∨ B  ⟧ Γ = CovExt Γ λ Δ → T⟦ A ⟧ Δ ⊎ T⟦ B ⟧ Δ
T⟦ A ∧ B  ⟧ Γ = T⟦ A ⟧ Γ × T⟦ B ⟧ Γ
T⟦ A ⇒ B  ⟧ Γ = ∀{Δ} (τ : Δ ≤ Γ) → T⟦ A ⟧ Δ → T⟦ B ⟧ Δ

-- Monotonicity of the model is proven by induction on the proposition,
-- using monotonicity of covers and the built-in monotonicity at implication.

-- monT : ∀ A {Γ Δ} (τ : Δ ≤ Γ) → T⟦ A ⟧ Γ → T⟦ A ⟧ Δ

monT : ∀ A → Mon T⟦ A ⟧
monT (Atom P) = monNf
monT True     = _
monT False    = monCE λ τ ()
monT (A ∨ B)  = monCE λ τ → map-⊎ (monT A τ) (monT B τ)
monT (A ∧ B) τ (a , b) = monT A τ a , monT B τ b
monT (A ⇒ B) τ f σ = f (σ • τ)

-- Reflection / reification, proven simultaneously by induction on the proposition.

-- Reflection is η-expansion (and recursively reflection);
-- at positive connections we build a case tree with a single scrutinee: the neutral
-- we are reflecting.

-- At implication, we need reification, which produces introductions
-- and reifies the stored case trees.

mutual

  reflect : ∀{Γ} A (t : Ne Γ A) → T⟦ A ⟧ Γ
  reflect (Atom P) t = ne t
  reflect True     t = _
  reflect False    t = falseC t , λ()
  reflect (A ∨ B)  t = orC t hole hole , λ where
    (left  here) → inj₁ (reflect A (hyp top))
    (right here) → inj₂ (reflect B (hyp top))
  reflect (A ∧ B)  t = reflect A (andE₁ t) , reflect B (andE₂ t)
  reflect (A ⇒ B)  t τ a = reflect B (impE (monNe τ t) (reify A a))

  reify : ∀{Γ} A (⟦f⟧ : T⟦ A ⟧ Γ) → Nf Γ A
  reify (Atom P) t      = t
  reify True _          = trueI
  reify False   (C , f) = paste' C (⊥-elim ∘ f)
  reify (A ∨ B) (C , f) = paste' C ([ orI₁ ∘ reify A , orI₂ ∘ reify B ] ∘ f)
  reify (A ∧ B) (a , b) = andI (reify A a) (reify B b)
  reify (A ⇒ B) ⟦f⟧     = impI (reify B (⟦f⟧ (weak id≤) (reflect A (hyp top))))

-- Semantic paste.

-- This grafts semantic values f onto a case tree C : Cover Γ.
-- For atomic propositions, this is grafting of normal forms (defined before).

paste : ∀ A {Γ} (C : Cover Γ) (f : All C (T⟦ A ⟧)) → T⟦ A ⟧ Γ
paste (Atom P) = paste'
paste True     = _
paste False    = transCE
paste (A ∨ B)  = transCE
paste (A ∧ B) C f = paste A C (proj₁ ∘ f) , paste B C (proj₂ ∘ f)
paste (A ⇒ B) C f τ a = paste B (monC τ C) λ {Δ} e →
  let Ψ , e' , σ  = mon∈ C τ e
  in  f e' σ (monT A (coverWk e) a)

-- Fundamental theorem
-- Extension of T⟦_⟧ to contexts

G⟦_⟧ : ∀ (Γ Δ : Cxt) → Set
G⟦ ε     ⟧ Δ = ⊤
G⟦ Γ ∙ A ⟧ Δ = G⟦ Γ ⟧ Δ × T⟦ A ⟧ Δ

-- monG : ∀{Γ Δ Φ} (τ : Φ ≤ Δ) → G⟦ Γ ⟧ Δ → G⟦ Γ ⟧ Φ

monG : ∀{Γ} → Mon G⟦ Γ ⟧
monG {ε} τ _ = _
monG {Γ ∙ A} τ (γ , a) = monG τ γ , monT A τ a

-- Variable case.

fundH : ∀{Γ Δ A} (x : Hyp A Γ) (γ : G⟦ Γ ⟧ Δ) → T⟦ A ⟧ Δ
fundH top     = proj₂
fundH (pop x) = fundH x ∘ proj₁

-- A lemma for the orE case.

orElim : ∀ {Γ A B X} → T⟦ A ∨ B ⟧ Γ →
         (∀{Δ} (τ : Δ ≤ Γ) → T⟦ A ⟧ Δ → T⟦ X ⟧ Δ) →
         (∀{Δ} (τ : Δ ≤ Γ) → T⟦ B ⟧ Δ → T⟦ X ⟧ Δ) →
         T⟦ X ⟧ Γ
orElim (C , f) g h = paste _ C λ e → [ g (coverWk e) , h (coverWk e) ] (f e)

-- A lemma for the falseE case.

-- Casts an empty cover into any semantic value (by contradiction).

falseElim : ∀{Γ A} → T⟦ False ⟧ Γ → T⟦ A ⟧ Γ
falseElim (C , f) = paste _ C (⊥-elim ∘ f)

-- The fundamental theorem

fund :  ∀{Γ A} (t : Γ ⊢ A) {Δ} (γ : G⟦ Γ ⟧ Δ) → T⟦ A ⟧ Δ
fund (hyp x)           = fundH x
fund (impI t)    γ τ a = fund t (monG τ γ , a)
fund (impE t u)  γ     = fund t γ id≤ (fund u γ)
fund (andI t u)  γ     = fund t γ , fund u γ
fund (andE₁ t)         = proj₁ ∘ fund t
fund (andE₂ t)         = proj₂ ∘ fund t
fund (orI₁ t)    γ     = hole , inj₁ ∘ λ{ here → fund t γ }
fund (orI₂ t)    γ     = hole , inj₂ ∘ λ{ here → fund t γ }
fund (orE t u v) γ     = orElim (fund t γ)
  (λ τ a → fund u (monG τ γ , a))
  (λ τ b → fund v (monG τ γ , b))
fund (falseE t)  γ     = falseElim (fund t γ)
fund trueI       γ     = _

-- Identity environment

ide : ∀ Γ → G⟦ Γ ⟧ Γ
ide ε = _
ide (Γ ∙ A) = monG (weak id≤) (ide Γ) , reflect A (hyp top)

-- Normalization

norm : ∀{Γ A} (t : Γ ⊢ A) → Nf Γ A
norm t = reify _ (fund t (ide _))

-- Q.E.D. -}
