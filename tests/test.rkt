#lang racket/base
(require ffi/unsafe
         ffi/unsafe/define
         ffi/unsafe/define/conventions)

(define NimibString _string*/utf-8)

(define-ffi-definer define-nimib (ffi-lib "libnimib") #:make-c-id convention:hyphen->underscore)

(define-nimib nimib-set-file-ext (_fun NimibString -> _void))
(define-nimib nimib-set-exec-cmd (_fun NimibString -> _void))

(define-nimib nimib-init (_fun NimibString -> NimibString))
(define-nimib nimib-add-text (_fun NimibString -> _void))
(define-nimib nimib-add-code (_fun NimibString -> NimibString))
(define-nimib nimib-add-code-with-ext (_fun NimibString NimibString -> NimibString))
(define-nimib nimib-add-code-with-ext-cmd (_fun NimibString NimibString -> NimibString))
(define-nimib nimib-save (_fun -> NimibString))

(nimib-set-file-ext ".rkt")
(nimib-set-exec-cmd "racket $file")
(nimib-init (find-system-path 'run-file))
(nimib-add-text "# Hello from Racket!")
(nimib-add-code "#lang racket/base\n(displayln \"Hello, World\")\n(displayln (+ 10 20))\n")
(nimib-save)




