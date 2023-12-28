#lang racket/base
(require ffi/unsafe
         ffi/unsafe/define
         ffi/unsafe/define/conventions)

(define NimibString _string*/utf-8)

(define-ffi-definer define-nimib (ffi-lib "libnimib") #:make-c-id convention:hyphen->underscore)

(define-nimib nimib-debug _bool)

(define-nimib nimib-free-string (_fun NimibString -> _void))

(define-nimib nimib-set-ext-cmd-language (_fun NimibString NimibString NimibString -> NimibString))


(define-nimib nimib-init (_fun NimibString NimibString NimibString NimibString -> NimibString))
(define-nimib nimib-save (_fun -> NimibString))


(define-nimib nimib-add-code (_fun NimibString -> NimibString))
(define-nimib nimib-add-code-with-ext (_fun NimibString NimibString -> NimibString))


(define-nimib nimib-add-text (_fun NimibString -> _void))
(define-nimib nimib-add-image (_fun NimibString NimibString NimibString -> NimibString))

(define-nimib nimib-add-file (_fun NimibString -> NimibString))
(define-nimib nimib-add-file-name-content (_fun NimibString NimibString -> NimibString))

(set! nimib-debug #t)
(nimib-init (find-system-path 'run-file) ".rkt" "racket $file" "lisp")
(nimib-set-ext-cmd-language ".nim" "nim c -r --verbosity:0 $file" "nim")
(nimib-add-text "# Hello from Racket!")
(nimib-add-code "#lang racket/base\n(displayln \"Hello, World\")\n(displayln (+ 10 20))\n")
(nimib-add-code-with-ext "echo 10 + 30" ".nim")
(nimib-save)




