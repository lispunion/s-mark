;; Copyright 2020 Lassi Kortela
;; SPDX-License-Identifier: ISC

(define-library (s-mark read)
  (export s-mark-read-all)
  (import (scheme base) (scheme char))
  (begin

    (define (cons* x xs)
      (cond ((not x) xs)
            ((string? x)
             (if (and (not (null? xs)) (string? (car xs)))
                 (cons (string-append (car xs) x) (cdr xs))
                 (cons x xs)))
            ((char? x)
             (if (and (not (null? xs)) (string? (car xs)))
                 (cons (string-append (car xs) (string x)) (cdr xs))
                 (cons (string x) xs)))
            (else (cons x xs))))

    (define (newline? char) (char=? char #\newline))

    (define (graphic-char? char)
      (not (char-whitespace? char)))

    (define (horizontal-char? char)
      (not (char=? newline? char)))

    (define (horizontal-whitespace? char)
      (case char ((#\space #\tab) #t) (else #f)))

    (define (backslash?          char)      (char=? #\\ char))
    (define (open-paren?         char)      (char=? #\( char))
    (define (close-paren?        char)      (char=? #\) char))
    (define (sharpsign?          char)      (char=? #\# char))
    (define (not-sharpsign?      char) (not (char=? #\# char)))

    (define (name-char? char)
      (or (char<=? #\0 char #\9)
          (char<=? #\A char #\Z)
          (char<=? #\a char #\z)
          (char=?  #\- char)))

    (define (read-char? match?)
      (let ((char (peek-char)))
        (and (not (eof-object? char))
             (match? char)
             (read-char))))

    (define (read-char* match?)
      (let loop ((chars #f))
        (let ((char (read-char? match?)))
          (cond (char (loop (cons char (or chars '()))))
                (chars (list->string (reverse chars)))
                (else #f)))))

    (define (read-escape-char)
      (or (read-char? graphic-char?)
          (error "Bad escape char")))

    (define (read-argument)
      (let loop ((nest 1) (forms '()))
        (let ((whitespace (read-char* horizontal-whitespace?)))
          (cond ((eof-object? (peek-char))
                 (error "Unterminated argument"))
                ((read-char? newline?)
                 (loop nest (cons* "\n" forms)))
                ((read-char? sharpsign?)
                 (loop nest (cons* (read-directive) (cons* whitespace forms))))
                ((read-char? backslash?)
                 (loop nest (cons* (read-escape-char) (cons* whitespace forms))))
                (else
                 (let* ((char (read-char))
                        (nest (cond ((open-paren?  char) (+ nest 1))
                                    ((close-paren? char) (- nest 1))
                                    (else nest))))
                   (if (< nest 1)
                       (cond ((null? forms) "")
                             ((and (string? (car forms)) (null? (cdr forms)))
                              (car forms))
                             (else (reverse forms)))
                       (loop nest
                             (cons* char (cons* whitespace forms))))))))))

    (define (read-directive)
      (let ((name (string->symbol (or (read-char* name-char?)
                                      (error "No directive name")))))
        (let loop ((form (list name)))
          (if (read-char? open-paren?)
              (loop (cons (read-argument) form))
              (reverse form)))))

    (define (s-mark-read-all)
      (let loop ((forms '()))
        (let ((whitespace (read-char* horizontal-whitespace?)))
          (cond ((eof-object? (peek-char))
                 (reverse forms))
                ((read-char? newline?)
                 (loop (cons* "\n" forms)))
                ((read-char? sharpsign?)
                 (loop (cons* (read-directive) (cons* whitespace forms))))
                ((read-char? backslash?)
                 (loop (cons* (read-escape-char) (cons* whitespace forms))))
                (else
                 (loop (cons* (read-char) (cons* whitespace forms))))))))))
