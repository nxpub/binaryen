;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.

;; RUN: foreach %s %t wasm-opt --inlining --optimize-level=3 --all-features -S -o - | filecheck %s

(module
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $i32_=>_none (func (param i32)))

  ;; CHECK:      (type $anyref_=>_anyref (func (param anyref) (result anyref)))

  ;; CHECK:      (type $struct (struct ))
  (type $struct (struct))

  ;; CHECK:      (type $i32_rtt_$struct_=>_none (func (param i32 (rtt $struct))))

  ;; CHECK:      (type $anyref_=>_none (func (param anyref)))

  ;; CHECK:      (type $i64_i32_f64_=>_none (func (param i64 i32 f64)))

  ;; CHECK:      (import "out" "func" (func $import))
  (import "out" "func" (func $import))

  ;; CHECK:      (global $glob i32 (i32.const 1))
  (global $glob i32 (i32.const 1))

  ;; CHECK:      (start $start-used-globally)
  (start $start-used-globally)

  ;; Pattern A: functions beginning with
  ;;
  ;;   if (simple) return;

  (func $maybe-work-hard (param $x i32)
    ;; A function that does a quick check before any heavy work. We can outline
    ;; the heavy work, so that the condition can be inlined.
    ;;
    ;; This function (and others lower down that we also optimize) will vanish
    ;; in the output. Part of it will be inlined into its caller, below, and
    ;; the rest will be outlined into a new function with suffix "outlined".
    (if
      (local.get $x)
      (return)
    )
    (loop $l
      (call $import)
      (br $l)
    )
  )

  ;; CHECK:      (func $call-maybe-work-hard
  ;; CHECK-NEXT:  (local $0 i32)
  ;; CHECK-NEXT:  (local $1 i32)
  ;; CHECK-NEXT:  (local $2 i32)
  ;; CHECK-NEXT:  (block
  ;; CHECK-NEXT:   (block $__inlined_func$maybe-work-hard$byn-outline-A-inlineable
  ;; CHECK-NEXT:    (local.set $0
  ;; CHECK-NEXT:     (i32.const 1)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (if
  ;; CHECK-NEXT:     (i32.eqz
  ;; CHECK-NEXT:      (local.get $0)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:     (call $maybe-work-hard$byn-outline-A-outlined
  ;; CHECK-NEXT:      (local.get $0)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (block
  ;; CHECK-NEXT:   (block $__inlined_func$maybe-work-hard$byn-outline-A-inlineable0
  ;; CHECK-NEXT:    (local.set $1
  ;; CHECK-NEXT:     (i32.const 2)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (if
  ;; CHECK-NEXT:     (i32.eqz
  ;; CHECK-NEXT:      (local.get $1)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:     (call $maybe-work-hard$byn-outline-A-outlined
  ;; CHECK-NEXT:      (local.get $1)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (block
  ;; CHECK-NEXT:   (block $__inlined_func$maybe-work-hard$byn-outline-A-inlineable1
  ;; CHECK-NEXT:    (local.set $2
  ;; CHECK-NEXT:     (i32.const 3)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (if
  ;; CHECK-NEXT:     (i32.eqz
  ;; CHECK-NEXT:      (local.get $2)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:     (call $maybe-work-hard$byn-outline-A-outlined
  ;; CHECK-NEXT:      (local.get $2)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $call-maybe-work-hard
    ;; Call the above function to verify that we can in fact inline it after
    ;; splitting. We should see each of these three calls replaced by inlined
    ;; code performing the if from $maybe-work-hard, and depending on that
    ;; result they each call the outlined code that must *not* be inlined.
    ;;
    ;; Note that we must call more than once, otherwise given a single use we
    ;; will always inline the entire thing.
    (call $maybe-work-hard (i32.const 1))
    (call $maybe-work-hard (i32.const 2))
    (call $maybe-work-hard (i32.const 3))
  )

  ;; CHECK:      (func $nondefaultable-param (param $x i32) (param $y (rtt $struct))
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:   (return)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (loop $l
  ;; CHECK-NEXT:   (call $import)
  ;; CHECK-NEXT:   (br $l)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $nondefaultable-param (param $x i32) (param $y (rtt $struct))
    ;; The RTT param here prevents us from even being inlined, even with
    ;; splitting.
    (if
      (local.get $x)
      (return)
    )
    (loop $l
      (call $import)
      (br $l)
    )
  )

  ;; CHECK:      (func $call-nondefaultable-param
  ;; CHECK-NEXT:  (call $nondefaultable-param
  ;; CHECK-NEXT:   (i32.const 0)
  ;; CHECK-NEXT:   (rtt.canon $struct)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $call-nondefaultable-param
    (call $nondefaultable-param (i32.const 0) (rtt.canon $struct))
  )

  (func $many-params (param $x i64) (param $y i32) (param $z f64)
    ;; Test that we can optimize this function even though it has multiple
    ;; parameters, and it is not the very first one that we use in the
    ;; condition.
    (if
      (local.get $y)
      (return)
    )
    (loop $l
      (call $import)
      (br $l)
    )
  )

  ;; CHECK:      (func $call-many-params
  ;; CHECK-NEXT:  (local $0 i64)
  ;; CHECK-NEXT:  (local $1 i32)
  ;; CHECK-NEXT:  (local $2 f64)
  ;; CHECK-NEXT:  (local $3 i64)
  ;; CHECK-NEXT:  (local $4 i32)
  ;; CHECK-NEXT:  (local $5 f64)
  ;; CHECK-NEXT:  (block
  ;; CHECK-NEXT:   (block $__inlined_func$many-params$byn-outline-A-inlineable
  ;; CHECK-NEXT:    (local.set $0
  ;; CHECK-NEXT:     (i64.const 0)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (local.set $1
  ;; CHECK-NEXT:     (i32.const 1)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (local.set $2
  ;; CHECK-NEXT:     (f64.const 3.14159)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (if
  ;; CHECK-NEXT:     (i32.eqz
  ;; CHECK-NEXT:      (local.get $1)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:     (call $many-params$byn-outline-A-outlined
  ;; CHECK-NEXT:      (local.get $0)
  ;; CHECK-NEXT:      (local.get $1)
  ;; CHECK-NEXT:      (local.get $2)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (block
  ;; CHECK-NEXT:   (block $__inlined_func$many-params$byn-outline-A-inlineable0
  ;; CHECK-NEXT:    (local.set $3
  ;; CHECK-NEXT:     (i64.const 0)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (local.set $4
  ;; CHECK-NEXT:     (i32.const 1)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (local.set $5
  ;; CHECK-NEXT:     (f64.const 3.14159)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (if
  ;; CHECK-NEXT:     (i32.eqz
  ;; CHECK-NEXT:      (local.get $4)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:     (call $many-params$byn-outline-A-outlined
  ;; CHECK-NEXT:      (local.get $3)
  ;; CHECK-NEXT:      (local.get $4)
  ;; CHECK-NEXT:      (local.get $5)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $call-many-params
    ;; Call the above function to verify that we can in fact inline it after
    ;; splitting. We should see each of these three calls replaced by inlined
    ;; code performing the if from $maybe-work-hard, and depending on that
    ;; result they each call the outlined code that must *not* be inlined.
    (call $many-params (i64.const 0) (i32.const 1) (f64.const 3.14159))
    (call $many-params (i64.const 0) (i32.const 1) (f64.const 3.14159))
  )

  (func $condition-eqz (param $x i32)
    (if
      ;; More work in the condition, but work that we still consider worth
      ;; optimizing: a unary op.
      (i32.eqz
        (local.get $x)
      )
      (return)
    )
    (loop $l
      (call $import)
      (br $l)
    )
  )

  ;; CHECK:      (func $call-condition-eqz
  ;; CHECK-NEXT:  (local $0 i32)
  ;; CHECK-NEXT:  (local $1 i32)
  ;; CHECK-NEXT:  (block
  ;; CHECK-NEXT:   (block $__inlined_func$condition-eqz$byn-outline-A-inlineable
  ;; CHECK-NEXT:    (local.set $0
  ;; CHECK-NEXT:     (i32.const 0)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (if
  ;; CHECK-NEXT:     (i32.eqz
  ;; CHECK-NEXT:      (i32.eqz
  ;; CHECK-NEXT:       (local.get $0)
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:     (call $condition-eqz$byn-outline-A-outlined
  ;; CHECK-NEXT:      (local.get $0)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (block
  ;; CHECK-NEXT:   (block $__inlined_func$condition-eqz$byn-outline-A-inlineable0
  ;; CHECK-NEXT:    (local.set $1
  ;; CHECK-NEXT:     (i32.const 1)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (if
  ;; CHECK-NEXT:     (i32.eqz
  ;; CHECK-NEXT:      (i32.eqz
  ;; CHECK-NEXT:       (local.get $1)
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:     (call $condition-eqz$byn-outline-A-outlined
  ;; CHECK-NEXT:      (local.get $1)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $call-condition-eqz
    (call $condition-eqz (i32.const 0))
    (call $condition-eqz (i32.const 1))
  )

  ;; CHECK:      (func $condition-global
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (global.get $glob)
  ;; CHECK-NEXT:   (return)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (loop $l
  ;; CHECK-NEXT:   (call $import)
  ;; CHECK-NEXT:   (br $l)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $condition-global
    (if
      ;; A global read.
      (global.get $glob)
      (return)
    )
    (loop $l
      (call $import)
      (br $l)
    )
  )

  ;; CHECK:      (func $condition-ref.is (param $x anyref)
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (ref.is_null
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (return)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (loop $l
  ;; CHECK-NEXT:   (call $import)
  ;; CHECK-NEXT:   (br $l)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $condition-ref.is (param $x anyref)
    (if
      ;; A ref.is operation.
      (ref.is_null
        (local.get $x)
      )
      (return)
    )
    (loop $l
      (call $import)
      (br $l)
    )
  )

  ;; CHECK:      (func $condition-disallow-binary (param $x i32)
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (i32.add
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (return)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (loop $l
  ;; CHECK-NEXT:   (call $import)
  ;; CHECK-NEXT:   (br $l)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $condition-disallow-binary (param $x i32)
    (if
      ;; Work we do *not* allow (at least for now), a binary.
      (i32.add
        (local.get $x)
        (local.get $x)
      )
      (return)
    )
    (loop $l
      (call $import)
      (br $l)
    )
  )

  ;; CHECK:      (func $condition-disallow-unreachable (param $x i32)
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (i32.eqz
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (return)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (loop $l
  ;; CHECK-NEXT:   (call $import)
  ;; CHECK-NEXT:   (br $l)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $condition-disallow-unreachable (param $x i32)
    (if
      ;; Work we do *not* allow (at least for now), an unreachable.
      (i32.eqz
        (unreachable)
      )
      (return)
    )
    (loop $l
      (call $import)
      (br $l)
    )
  )

  ;; CHECK:      (func $start-used-globally
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (global.get $glob)
  ;; CHECK-NEXT:   (return)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (loop $l
  ;; CHECK-NEXT:   (call $import)
  ;; CHECK-NEXT:   (br $l)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $start-used-globally
    ;; This looks optimizable, but it is the start function, which means it is
    ;; used in more than the direct calls we can optimize, and so we do not
    ;; optimize it (for now).
    (if
      (global.get $glob)
      (return)
    )
    (loop $l
      (call $import)
      (br $l)
    )
  )

  ;; CHECK:      (func $inlineable
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (global.get $glob)
  ;; CHECK-NEXT:   (return)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $inlineable
    ;; This looks optimizable, but it is also inlineable - so we do not need to
    ;; outline it.
    (if
      (global.get $glob)
      (return)
    )
  )

  ;; CHECK:      (func $if-not-first (param $x i32)
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:   (return)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (loop $l
  ;; CHECK-NEXT:   (call $import)
  ;; CHECK-NEXT:   (br $l)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $if-not-first (param $x i32)
    ;; Except for the initial nop, we should outline this. As the if is not
    ;; first any more, we ignore it.
    (nop)
    (if
      (local.get $x)
      (return)
    )
    (loop $l
      (call $import)
      (br $l)
    )
  )

  ;; CHECK:      (func $if-else (param $x i32)
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:   (return)
  ;; CHECK-NEXT:   (nop)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (loop $l
  ;; CHECK-NEXT:   (call $import)
  ;; CHECK-NEXT:   (br $l)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $if-else (param $x i32)
    ;; An else in the if prevents us from recognizing the pattern we want.
    (if
      (local.get $x)
      (return)
      (nop)
    )
    (loop $l
      (call $import)
      (br $l)
    )
  )

  ;; CHECK:      (func $if-non-return (param $x i32)
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:   (unreachable)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (loop $l
  ;; CHECK-NEXT:   (call $import)
  ;; CHECK-NEXT:   (br $l)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $if-non-return (param $x i32)
    ;; Something other than a return in the if body prevents us from outlining.
    (if
      (local.get $x)
      (unreachable)
    )
    (loop $l
      (call $import)
      (br $l)
    )
  )

  ;; CHECK:      (func $colliding-name (param $x i32)
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:   (return)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (loop $l
  ;; CHECK-NEXT:   (call $import)
  ;; CHECK-NEXT:   (br $l)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $colliding-name (param $x i32)
    ;; When we outline this, the name should not collide with that of the
    ;; function after us.
    (if
      (local.get $x)
      (return)
    )
    (loop $l
      (call $import)
      (br $l)
    )
  )

  ;; CHECK:      (func $colliding-name$byn-outline-A
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $colliding-name$byn-outline-A
  )

  ;; Pattern B: functions containing
  ;;
  ;;   if (simple1) heavy-work-that-is-unreachable;
  ;;   simple2

  ;; CHECK:      (func $error-if-null (param $x anyref) (result anyref)
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (ref.is_null
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (block $block
  ;; CHECK-NEXT:    (call $import)
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.get $x)
  ;; CHECK-NEXT: )
  (func $error-if-null (param $x anyref) (result anyref)
    ;; A "as non null" function: If the input is null, issue an error somehow
    ;; (here, by calling an import, but could also be a throwing of an
    ;; exception). If not null, return the value.
    (if
      (ref.is_null
        (local.get $x)
      )
      (block
        (call $import)
        (unreachable)
      )
    )
    (local.get $x)
  )

  ;; CHECK:      (func $too-many (param $x anyref) (result anyref)
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (ref.is_null
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (block $block
  ;; CHECK-NEXT:    (call $import)
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT:  (local.get $x)
  ;; CHECK-NEXT: )
  (func $too-many (param $x anyref) (result anyref)
    (if
      (ref.is_null
        (local.get $x)
      )
      (block
        (call $import)
        (unreachable)
      )
    )
    (nop) ;; An extra operation here prevents us from identifying the pattern.
    (local.get $x)
  )

  ;; CHECK:      (func $tail-not-simple (param $x anyref) (result anyref)
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (ref.is_null
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (block $block
  ;; CHECK-NEXT:    (call $import)
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (unreachable)
  ;; CHECK-NEXT: )
  (func $tail-not-simple (param $x anyref) (result anyref)
    (if
      (ref.is_null
        (local.get $x)
      )
      (block
        (call $import)
        (unreachable)
      )
    )
    (unreachable) ;; This prevents us from optimizing
  )

  ;; CHECK:      (func $reachable-if-body (param $x anyref) (result anyref)
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (ref.is_null
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (call $import)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.get $x)
  ;; CHECK-NEXT: )
  (func $reachable-if-body (param $x anyref) (result anyref)
    (if
      (ref.is_null
        (local.get $x)
      )
      ;; The if body is not unreachable, which prevents the optimization.
      (call $import)
    )
    (local.get $x)
  )
)

;; CHECK:      (func $maybe-work-hard$byn-outline-A-outlined (param $x i32)
;; CHECK-NEXT:  (loop $l
;; CHECK-NEXT:   (call $import)
;; CHECK-NEXT:   (br $l)
;; CHECK-NEXT:  )
;; CHECK-NEXT: )

;; CHECK:      (func $many-params$byn-outline-A-outlined (param $x i64) (param $y i32) (param $z f64)
;; CHECK-NEXT:  (loop $l
;; CHECK-NEXT:   (call $import)
;; CHECK-NEXT:   (br $l)
;; CHECK-NEXT:  )
;; CHECK-NEXT: )

;; CHECK:      (func $condition-eqz$byn-outline-A-outlined (param $x i32)
;; CHECK-NEXT:  (loop $l
;; CHECK-NEXT:   (call $import)
;; CHECK-NEXT:   (br $l)
;; CHECK-NEXT:  )
;; CHECK-NEXT: )
