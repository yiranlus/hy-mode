;;; hy-mode.el --- Major mode for Hylang

;; Copyright © 2013 Julien Danjou <julien@danjou.info>
;;           © 2017 Eric Kaschalk <ekaschalk@gmail.com>
;;
;; Authors: Julien Danjou <julien@danjou.info>
;;          Eric Kaschalk <ekaschalk@gmail.com>
;; URL: http://github.com/hylang/hy-mode
;; Version: 1.0
;; Keywords: languages, lisp, python

;; hy-mode is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; hy-mode is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with hy-mode.  If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Provides font-lock, indentation, and navigation for the Hy
;; language. (http://hylang.org)

(defgroup hy-mode nil
  "A mode for Hy"
  :prefix "hy-mode-"
  :group 'applications)

(defcustom hy-mode-inferior-lisp-command "hy"
  "The command used by `inferior-lisp-program'."
  :type 'string
  :group 'hy-mode)

;;; Keywords

(defconst hy--kwds-builtins
  '("*map" "accumulate" "and" "assoc" "butlast" "calling-module-name" "car"
    "cdr" "chain" "coll?" "combinations" "compress" "cons" "cons?" "count" "cut"
    "cycle" "dec" "def" "defmain" "del" "disassemble" "distinct" "drop"
    "drop-last" "drop-while" "empty?" "eval" "even?" "every?" "filter" "first"
    "flatten" "float?" "fraction" "gensym" "get" "group-by" "identity" "in"
    "inc" "input" "instance?" "integer" "integer-char?" "integer?" "interleave"
    "interpose" "is" "is-not" "is_not" "islice" "iterable?" "iterate"
    "iterator?" "keyword" "keyword?" "last" "list*" "list-comp" "macroexpand"
    "macroexpand-1" "map" "merge-with" "multicombinations" "name" "neg?" "nil?"
    "none?" "not" "not-in" "not_in" "nth" "numeric?" "odd?" "or" "partition"
    "permutations" "pos?" "print" "product" "quasiquote" "quote" "range" "read"
    "read-str" "reduce" "remove" "repeat" "repeatedly" "rest" "second" "setv"
    "slice" "some" "string" "string?" "symbol?" "take" "take-nth" "take-while"
    "tee" "unquote" "unquote-splice" "zero?" "zip" "zip-longest")

  "Hy builtin keywords.")

(defconst hy--kwds-constants
  '("True" "False" "None" "nil")

  "Hy constant keywords.")

(defconst hy--kwds-defs
  '("defn" "defun"
    "defmacro" "defmacro/g!" "defmacro!"
    "defreader" "defsharp" "deftag")

  "Hy definition keywords.")

(defconst hy--kwds-operators
  '("!=" "%" "%=" "&" "&=" "*" "**" "**=" "*=" "+" "+=" "," "-"
    "-=" "/" "//" "//=" "/=" "<" "<<" "<<=" "<=" "=" ">" ">=" ">>" ">>="
    "^" "^=" "_=" "|" "|=" "~")

  "Hy operator keywords.")

(defconst hy--kwds-special-forms
  '(;; Looping
    "loop" "recur"
    "for" "for*"

    ;; Threading
    "_>" "->" "_>>" "->>" "as->" "as_>"

    ;; Flow control
    "if" "if-not" "else" "unless" "when"
    "break" "continue"
    "while" "cond"
    "do" "progn"

    ;; Functional
    "lambda" "fn"
    "yield" "yield-from"
    "with" "with*"
    "with-decorator" "with_decorator" "with-gensyms" "with_gensyms"

    ;; Error Handling
    "except" "try" "throw" "raise" "catch" "finally" "assert"

    ;; Misc
    "global"
    "eval-and-compile"

    ;; Discontinued
    "apply" "kwapply" "let")

  "Hy special forms keywords.")

;;; Font Locks
;;;; Definitions

(defconst hy--font-lock-kwds-builtins
  (list
   (rx-to-string
    `(: word-start
        (or ,@hy--kwds-operators
            ,@hy--kwds-builtins)
        word-end))

   '(0 font-lock-builtin-face))

  "Hy builtin keywords.")

(defconst hy--font-lock-kwds-constants
  (list
   (rx-to-string
    `(: (or ,@hy--kwds-constants)))

   '(0 font-lock-constant-face))

  "Hy constant keywords.")

(defconst hy--font-lock-kwds-defs
  (list
   (rx-to-string
    `(: (group-n 1 (or ,@hy--kwds-defs))
        (1+ space)
        (group-n 2 (1+ word))))

   '(1 font-lock-keyword-face)
   '(2 font-lock-function-name-face nil t))

  "Hy definition keywords.")

(defconst hy--font-lock-kwds-special-forms
  (list
   (rx-to-string
    `(: word-start
        (or ,@hy--kwds-special-forms)
        word-end))

   '(0 font-lock-keyword-face))

  "Hy special forms keywords.")

;;;; Static

(defconst hy--font-lock-kwds-aliases
  (list
   (rx (group-n 1 (or "defmacro-alias" "defn-alias" "defun-alias"))
       (1+ space)
       "["
       (group-n 2 (1+ anything))
       "]")

   '(1 font-lock-keyword-face)
   '(2 font-lock-function-name-face nil t))

  "Hy aliasing keywords.")

(defconst hy--font-lock-kwds-class
  (list
   (rx (group-n 1 "defclass")
       (1+ space)
       (group-n 2 (1+ word)))

   '(1 font-lock-keyword-face)
   '(2 font-lock-type-face))

  "Hy class keywords.")

(defconst hy--font-lock-kwds-imports
  (list
   (rx (or "import" "require" ":as")
       (or (1+ space) eol))

   '(0 font-lock-keyword-face))

  "Hy import keywords.")

(defconst hy--font-lock-kwds-self
  (list
   (rx word-start
       (group "self")
       (or "." word-end))

   '(1 font-lock-keyword-face))

  "Hy self keyword.")

;;;; Misc

(defconst hy--font-lock-kwds-func-modifiers
  (list
   (rx word-start "&" (1+ word))

   '(0 font-lock-type-face))

  "Hy '&rest/&kwonly/...' styling.")

(defconst hy--font-lock-kwds-kwargs
  (list
   (rx word-start ":" (1+ word))

   '(0 font-lock-constant-face))

  "Hy ':kwarg' styling.")

(defconst hy--font-lock-kwds-shebang
  (list
   (rx buffer-start "#!" (0+ not-newline) eol)

   '(0 font-lock-comment-face))

  "Hy shebang line.")

;;;; Grouped

(defconst hy-font-lock-kwds
  (list hy--font-lock-kwds-aliases
        hy--font-lock-kwds-builtins
        hy--font-lock-kwds-class
        hy--font-lock-kwds-constants
        hy--font-lock-kwds-defs
        hy--font-lock-kwds-func-modifiers
        hy--font-lock-kwds-imports
        hy--font-lock-kwds-kwargs
        hy--font-lock-kwds-self
        hy--font-lock-kwds-shebang
        hy--font-lock-kwds-special-forms)

  "All Hy font lock keywords.")

;;; Indentation

(defcustom hy-indent-specform
  '(("for" . 1)
    ("for*" . 1)
    ("while" . 1)
    ("except" . 1)
    ("catch" . 1)
    ("let" . 1)
    ("if" . 1)
    ("when" . 1)
    ("unless" . 1))
  "How to indent specials specform."
  :group 'hy-mode)

(defun hy-indent-function (indent-point state)
  "This function is the normal value of the variable `lisp-indent-function' for `hy-mode'.
It is used when indenting a line within a function call, to see
if the called function says anything special about how to indent
the line.

INDENT-POINT is the position at which the line being indented begins.
Point is located at the point to indent under (for default indentation);
STATE is the `parse-partial-sexp' state for that position.

This function returns either the indentation to use, or nil if the
Lisp function does not specify a special indentation."
  (let ((normal-indent (current-column)))
    (goto-char (1+ (elt state 1)))
    (parse-partial-sexp (point) calculate-lisp-indent-last-sexp 0 t)
    (if (and (elt state 2)
             (not (looking-at "\\sw\\|\\s_")))
        ;; car of form doesn't seem to be a symbol
        (progn
          (if (not (> (save-excursion (forward-line 1) (point))
                      calculate-lisp-indent-last-sexp))
              (progn (goto-char calculate-lisp-indent-last-sexp)
                     (beginning-of-line)
                     (parse-partial-sexp (point)
                                         calculate-lisp-indent-last-sexp 0 t)))
          ;; Indent under the list or under the first sexp on the same
          ;; line as calculate-lisp-indent-last-sexp.  Note that first
          ;; thing on that line has to be complete sexp since we are
          ;; inside the innermost containing sexp.
          (backward-prefix-chars))
      (let* ((open-paren (elt state 1))
             (function (buffer-substring (point)
                                         (progn (forward-sexp 1) (point))))
             (specform (cdr (assoc function hy-indent-specform))))
        (cond ((member (char-after open-paren) '(?\[ ?\{))
               (goto-char open-paren)
               (1+ (current-column)))
              (specform
               (lisp-indent-specform specform state indent-point normal-indent))
              ((string-match-p "\\`\\(?:\\S +/\\)?\\(def\\|with-\\|with_\\|fn\\|lambda\\)" function)
               (lisp-indent-defform state indent-point)))))))

;;; Syntax

(defvar hy-mode-syntax-table
  (let ((table (copy-syntax-table lisp-mode-syntax-table)))
    (modify-syntax-entry ?\{ "(}" table)
    (modify-syntax-entry ?\} "){" table)
    (modify-syntax-entry ?\[ "(]" table)
    (modify-syntax-entry ?\] ")[" table)
    table))

;;; Hy-mode

(unless (fboundp 'setq-local)
  (defmacro setq-local (var val)
    `(set (make-local-variable ',var) ,val)))

;;;###autoload
(progn
  (add-to-list 'auto-mode-alist '("\\.hy\\'" . hy-mode))
  (add-to-list 'interpreter-mode-alist '("hy" . hy-mode)))

;;;###autoload
(define-derived-mode hy-mode prog-mode "Hy"
  "Major mode for editing Hy files."
  (setq font-lock-defaults
        '(hy-font-lock-kwds
          nil nil
          (("+-*/.<>=!?$%_&~^:@" . "w")) ; syntax alist
          nil
          (font-lock-mark-block-function . mark-defun)
          (font-lock-syntactic-face-function
           . lisp-font-lock-syntactic-face-function)))
  ;; Comments
  (setq-local comment-start ";")
  (setq-local comment-start-skip
              "\\(\\(^\\|[^\\\\\n]\\)\\(\\\\\\\\\\)*\\)\\(;+\\|#|\\) *")
  (setq-local comment-add 1)

  ;; Indentation
  (setq-local indent-tabs-mode nil)
  (setq-local indent-line-function 'lisp-indent-line)
  (setq-local lisp-indent-function 'hy-indent-function)

  ;; Inferior Lisp Program
  (setq-local inferior-lisp-program hy-mode-inferior-lisp-command)
  (setq-local inferior-lisp-load-command
              (concat "(import [hy.importer [import-file-to-module]])\n"
                      "(import-file-to-module \"__main__\" \"%s\")\n"))
  (setenv "PYTHONIOENCODING" "UTF-8"))

;;; Utilities

;;;###autoload
(defun hy-insert-pdb ()
  "Import and set pdb trace at point."
  (interactive)
  (insert "(do (import pdb) (pdb.set-trace))"))

;;;###autoload
(defun hy-insert-pdb-threaded ()
  "Import and set pdb trace at point for a threading macro."
  (interactive)
  (insert "((fn [x] (import pdb) (pdb.set-trace) x))"))

;;; Keybindings

(set-keymap-parent hy-mode-map lisp-mode-shared-map)
(define-key hy-mode-map (kbd "C-M-x")   'lisp-eval-defun)
(define-key hy-mode-map (kbd "C-x C-e") 'lisp-eval-last-sexp)
(define-key hy-mode-map (kbd "C-c C-z") 'switch-to-lisp)
(define-key hy-mode-map (kbd "C-c C-l") 'lisp-load-file)

(define-key hy-mode-map (kbd "C-c C-t") 'hy-insert-pdb)
(define-key hy-mode-map (kbd "C-c C-S-t") 'hy-insert-pdb-threaded)

(provide 'hy-mode)

;;; hy-mode.el ends here
